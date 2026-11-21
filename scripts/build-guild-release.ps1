param([string]$LuaRunner)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repo 'guild'
$dist = Join-Path $repo 'share\Tranquility'
$names = @('Tranquility','Tranquility_Auctions','Tranquility_DB','Tranquility_Dungeon','Tranquility_Gear','Tranquility_Info','Tranquility_Loot','Tranquility_Phases','Tranquility_PvP','Tranquility_Recruitment','Tranquility_Regions','Tranquility_Summons')
$coreManifest = [IO.File]::ReadAllText((Join-Path $source 'Tranquility\Tranquility.toc'))
$versionMatch = [regex]::Match($coreManifest, '(?m)^## Version: ([0-9]+\.[0-9]+\.[0-9]+(?:-beta\.[0-9]+)?)\r?$')
if (-not $versionMatch.Success) { throw 'Missing valid public version.' }
$version = $versionMatch.Groups[1].Value
$utf8 = [Text.UTF8Encoding]::new($false)
Push-Location -LiteralPath $repo
try {
    if (-not $LuaRunner) {
        $command = Get-Command lua, luajit, fengari -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $LuaRunner = $command.Source }
        else {
            $cacheRoots = @((Join-Path $env:LOCALAPPDATA 'npm-cache\_npx'), (Join-Path $env:USERPROFILE 'AppData\Local\npm-cache\_npx')) | Select-Object -Unique
            $cached = foreach ($cacheRoot in $cacheRoots) {
                Get-ChildItem -Path (Join-Path $cacheRoot '*\node_modules\.bin\fengari.cmd') -Force -ErrorAction SilentlyContinue
            }
            $cached = $cached | Select-Object -First 1
            if ($cached) { $LuaRunner = $cached.FullName }
        }
    }
    if (-not $LuaRunner) { throw 'Install Lua 5.1+ or Fengari, or pass -LuaRunner with the executable path.' }
    $testOutput = @(& $LuaRunner tests/guild.lua 2>&1)
    $testExit = $LASTEXITCODE
    $testOutput | ForEach-Object { Write-Host $_ }
    if ($testExit -ne 0 -or $testOutput.Count -eq 0 -or [string]$testOutput[-1] -notmatch '^PASS: \d+ assertions; \d+ module configurations; public edition contracts$') { throw 'Public addon tests failed. No new ZIP produced.' }
    $security=@(& $LuaRunner tests/security.lua 2>&1);$security | ForEach-Object {Write-Host $_}
    if($LASTEXITCODE -ne 0 -or [string]$security[-1] -notmatch '^PASS: \d+ security and guild work assertions$'){throw 'Security validation failed'}
    $vault=@(& $LuaRunner tests/vault.lua 2>&1);$vault | ForEach-Object {Write-Host $_}
    if($LASTEXITCODE -ne 0 -or [string]$vault[-1] -notmatch '^PASS: \d+ vault verification assertions$'){throw 'Vault validation failed'}
    $defense=@(& $LuaRunner tests/defense.lua 2>&1);$defense | ForEach-Object {Write-Host $_}
    if($LASTEXITCODE -ne 0 -or [string]$defense[-1] -notmatch '^PASS: \d+ world defense assertions$'){throw 'World defense validation failed'}
    $flights=@(& $LuaRunner tests/flights.lua 2>&1);$flights | ForEach-Object {Write-Host $_}
    if($LASTEXITCODE -ne 0 -or [string]$flights[-1] -notmatch '^PASS: \d+ flight path finder assertions$'){throw 'Flight Path Finder validation failed'}
    $lfgResults=@()
    foreach($test in @('tests/lfg.lua','tests/lfg-advanced.lua')){
        $output=@(& $LuaRunner $test 2>&1);$output | ForEach-Object {Write-Host $_}
        if($LASTEXITCODE -ne 0 -or [string]$output[-1] -notmatch '^PASS: \d+ (?:advanced )?guild LFG assertions$'){throw 'Bundled LFG validation failed'}
        $lfgResults += [string]$output[-1]
    }
    $files = @{}
    $interface = '16001'
    foreach ($name in $names) {
        $folder = Join-Path $source $name
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { throw "Missing addon: $name" }
        $listed = @()
        $manifestContent = $null
        foreach ($manifestName in @(($name + '.toc'), ($name + '_Camelot.toc'))) {
            $path = Join-Path $folder $manifestName
            $content = [IO.File]::ReadAllText($path)
            if ($content -notmatch "(?m)^## Version: $([regex]::Escape($version))\r?$" -or $content -notmatch "(?m)^## Interface: $interface\r?$" -or $content -notmatch '(?m)^## X-License: MIT\r?$') { throw "Incorrect metadata: $manifestName" }
            if ($name -ne 'Tranquility' -and $content -notmatch '(?m)^## Dependencies: Tranquility\r?$') { throw "Missing core dependency: $name" }
            if ($manifestContent -and $manifestContent -ne $content) { throw "Client manifests differ: $name" }
            $manifestContent = $content
            $entries = @($content -split '\r?\n' | Where-Object { $_.Trim() -and -not $_.StartsWith('#') } | ForEach-Object { $_.Trim() })
            foreach ($entry in $entries) {
                if ($entry -notmatch '^[A-Za-z][A-Za-z0-9]*\.lua$') { throw "Unexpected manifest entry: $entry" }
                if (-not (Test-Path -LiteralPath (Join-Path $folder $entry) -PathType Leaf)) { throw "Missing Lua: $entry" }
                $files[($name + '/' + $entry)] = Join-Path $folder $entry
            }
            $listed += $entries
            $files[($name + '/' + $manifestName)] = $path
        }
        $actual = @(Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Extension -eq '.lua' } | Select-Object -ExpandProperty Name)
        if (Compare-Object @($listed | Sort-Object -Unique) @($actual | Sort-Object -Unique)) { throw "Unlisted source in $name" }
        $files[($name + '/LICENSE')] = Join-Path $source 'LICENSE'
        foreach ($extra in @('README.md','CHANGELOG.md')) {
            $path = Join-Path $folder $extra
            if (Test-Path -LiteralPath $path) { $files[($name + '/' + $extra)] = $path }
        }
    }
    # Keep distribution checks outside the addon; the uploaded source remains plain readable Lua.
    $deny = '\b(SendInput|keybd_event|RunMacroText|ReloadUI|GuildInvite|SetOverrideBinding|TitansRecruit\w*|SendWho)\b|\.NewTicker\s*\(|macrotext|\.Invite\s*\('
    $sharingDeny = 'HandsAPI|TitansHands|TitansGuild|TitansRecruit|TitansCombat|custom edition|private tools|companion[\\/]|[A-Z]:\\Users\\|D:\\Titans|BEGIN [A-Z ]*PRIVATE KEY|(?:bot[_-]?token|discord[_-]?token)\s*[:=]'
    foreach ($entry in $files.GetEnumerator()) {
        if ($entry.Key -match '\.lua$' -and [IO.File]::ReadAllText($entry.Value) -match $deny) { throw "Public automation audit failed: $($entry.Key)" }
        if ([IO.File]::ReadAllText($entry.Value) -match $sharingDeny) { throw "Public sharing audit failed: $($entry.Key)" }
        if ($entry.Key -notmatch '^Tranquility(?:_[A-Za-z]+)?/(?:[A-Za-z0-9_]+\.(?:lua|toc|md)|LICENSE)$') { throw 'Unsafe archive path' }
    }
    foreach($extra in @('TranquilityLFG.toc','TranquilityLFG_Camelot.toc','Access.lua','Vault.lua','LFG.lua','Profiles.lua','Builder.lua','Mirror.lua','Interface.lua','README.md','LICENSE')){
        $lfgPath=Join-Path $repo ('TranquilityLFG/'+$extra)
        $content=[IO.File]::ReadAllText($lfgPath)
        if($extra -match '\.lua$' -and $content -match $deny){throw "LFG public automation audit failed: $extra"}
        if($content -match $sharingDeny){throw "LFG public sharing audit failed: $extra"}
        $files[('TranquilityLFG/'+$extra)]=$lfgPath
    }
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipPath = Join-Path $dist ('Tranquility-Guild-Toolkit-' + $version + '.zip')
    $temporary = $zipPath + '.building'
    $stream = [IO.File]::Open($temporary, [IO.FileMode]::Create, [IO.FileAccess]::ReadWrite)
    $archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($key in @($files.Keys | Sort-Object)) {
            $entry = $archive.CreateEntry($key, [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = [DateTimeOffset]::new(2026,11,14,0,0,0,[TimeSpan]::Zero)
            $inputStream = [IO.File]::OpenRead($files[$key])
            $outputStream = $entry.Open()
            try { $inputStream.CopyTo($outputStream) }
            finally { $inputStream.Dispose(); $outputStream.Dispose() }
        }
    } finally { $archive.Dispose(); $stream.Dispose() }
    $verify = [IO.Compression.ZipFile]::OpenRead($temporary)
    try {
        if ($verify.Entries.Count -ne $files.Count) { throw 'Archive entry count mismatch' }
        foreach ($entry in $verify.Entries) {
            if (-not $files.ContainsKey($entry.FullName)) { throw 'Unexpected archive content' }
            $reader = $entry.Open()
            $sha = [Security.Cryptography.SHA256]::Create()
            try { $archivedHash = [BitConverter]::ToString($sha.ComputeHash($reader)).Replace('-','') }
            finally { $reader.Dispose(); $sha.Dispose() }
            $expectedHash = (Get-FileHash -LiteralPath $files[$entry.FullName] -Algorithm SHA256).Hash
            if ($archivedHash -ne $expectedHash) { throw "Archive/source mismatch: $($entry.FullName)" }
        }
    } finally { $verify.Dispose() }
    Move-Item -LiteralPath $temporary -Destination $zipPath -Force
    $hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText(($zipPath + '.sha256'), ($hash + '  ' + [IO.Path]::GetFileName($zipPath) + "`n"), $utf8)
    $report = @(
        "Tranquility Guild Toolkit $version - local preflight",
        "Target: Forever 1.60.1 / Interface $interface",
        "$(Get-Date -Format o)",
        [string]$testOutput[-1],
        ($lfgResults -join "`r`n"),
        [string]$security[-1],
        [string]$vault[-1],
        [string]$defense[-1],
        [string]$flights[-1],
        "PASS: $($names.Count + 1) addon folders ($($names.Count) toolkit + TranquilityLFG), $($files.Count) whitelisted files; manifest and archive hashes verified.",
        'PASS: declared addon files only; no test fixtures, credentials or personal SavedVariables.',
        'PASS: MIT license included in every addon folder.',
        "SHA256: $hash",
        'PENDING: live client smoke tests. See curseforge/LIVE-TEST.md.',
        'PENDING: publisher project creation, rights/name/support confirmation, file upload and CurseForge moderation.',
        'Use Beta for this candidate. No upload or game-folder modification performed.'
    ) -join "`r`n"
    [IO.File]::WriteAllText((Join-Path $dist ('Tranquility-Guild-Toolkit-' + $version + '-PREFLIGHT.txt')), $report, $utf8)
    $submission = Join-Path $dist ('Submission-' + $version)
    New-Item -ItemType Directory -Path $submission -Force | Out-Null
    & (Join-Path $PSScriptRoot 'prepare-discord-readme.ps1') | Write-Host
    $materials = @('PROJECT.md','FORM-ENTRIES.md','SUMMARY.md','DESCRIPTION.md','FAQ.md','SCREENSHOTS.md','CHANGELOG.md','LIVE-TEST.md','RELEASE-CHECKS.md','POLICY-REVIEW.md','DISCORD-README.md','DISCORD-MIRROR-SETUP.md','LFG-FEATURES.md','MEMBERSHIP-AND-JOBS.md','DEFENSE.md','SUBMISSION-README.md','avatar.png')
    foreach ($material in $materials) {
        $path = Join-Path (Join-Path $repo 'curseforge') $material
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { if($material -eq 'avatar.png'){continue};throw "Missing submission material: $material" }
        if ($material -ne 'avatar.png' -and [IO.File]::ReadAllText($path) -match $sharingDeny) { throw "Submission material sharing audit failed: $material" }
        Copy-Item -LiteralPath $path -Destination $submission -Force
    }
    $postSource=Join-Path (Join-Path $repo 'curseforge') 'discord-posts'
    $postTarget=Join-Path $submission 'discord-posts'
    if(Test-Path -LiteralPath $postTarget){
        foreach($oldPost in Get-ChildItem -LiteralPath $postTarget -File){
            if($oldPost.Name -match '^Post-\d+\.txt$' -and -not(Test-Path -LiteralPath (Join-Path $postSource $oldPost.Name))){Remove-Item -LiteralPath $oldPost.FullName}
        }
    }
    Copy-Item -LiteralPath $postSource -Destination $submission -Recurse -Force
    foreach ($artifact in @($zipPath, ($zipPath + '.sha256'), (Join-Path $dist ('Tranquility-Guild-Toolkit-' + $version + '-PREFLIGHT.txt')), (Join-Path $source 'LICENSE'), (Join-Path $source 'Tranquility/CHANGELOG.md'))) {
        Copy-Item -LiteralPath $artifact -Destination $submission -Force
    }
    $expectedSubmission = @($materials) + @([IO.Path]::GetFileName($zipPath),([IO.Path]::GetFileName($zipPath) + '.sha256'),('Tranquility-Guild-Toolkit-' + $version + '-PREFLIGHT.txt'),'LICENSE','CHANGELOG.md')
    $expectedSubmission += @(Get-ChildItem -LiteralPath (Join-Path (Join-Path $repo 'curseforge') 'discord-posts') -File | ForEach-Object { 'discord-posts/' + $_.Name })
    foreach ($candidate in (Get-ChildItem -LiteralPath $submission -File -Recurse)) {
        $submissionRelative = $candidate.FullName.Substring($submission.Length+1).Replace('\','/')
        if ($submissionRelative -notin $expectedSubmission) { throw "Unexpected submission file: $submissionRelative" }
        if ($candidate.Name -ne 'avatar.png' -and $candidate.Extension -ne '.zip' -and [IO.File]::ReadAllText($candidate.FullName) -match $sharingDeny) { throw "Submission folder sharing audit failed: $($candidate.Name)" }
        if ($candidate.Extension -notin @('.md','.txt','.zip','.sha256','.png','') -or ($candidate.Extension -eq '' -and $candidate.Name -ne 'LICENSE')) { throw 'Unexpected submission folder file type.' }
    }
    $friendly=Join-Path $repo 'submission\Tranquility'
    New-Item -ItemType Directory -Path $friendly -Force | Out-Null
    Get-ChildItem -LiteralPath $submission -File | Copy-Item -Destination $friendly -Force
    $friendlyPosts=Join-Path $friendly 'discord-posts'
    if(Test-Path -LiteralPath $friendlyPosts){
        foreach($oldPost in Get-ChildItem -LiteralPath $friendlyPosts -File){if($oldPost.Name -match '^Post-\d+\.txt$' -and -not(Test-Path -LiteralPath (Join-Path $postSource $oldPost.Name))){Remove-Item -LiteralPath $oldPost.FullName}}
    }
    Copy-Item -LiteralPath $postSource -Destination $friendly -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $submission 'SUBMISSION-README.md') -Destination (Join-Path $friendly 'START-HERE.md') -Force
    Write-Host "Ready for beta review: $zipPath" -ForegroundColor Green
    Write-Host "Submission folder: $friendly" -ForegroundColor Green
} finally { Pop-Location }
