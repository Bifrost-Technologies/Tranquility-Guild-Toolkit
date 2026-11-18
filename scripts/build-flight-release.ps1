param([string]$LuaRunner)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $repo
try{
 if(-not $LuaRunner){
  $command=Get-Command lua,luajit,fengari -ErrorAction SilentlyContinue | Select-Object -First 1
  if($command){$LuaRunner=$command.Source}else{$cached=Get-ChildItem -Path (Join-Path $env:USERPROFILE 'AppData/Local/npm-cache/_npx/*/node_modules/.bin/fengari.cmd') -ErrorAction SilentlyContinue | Select-Object -First 1;if($cached){$LuaRunner=$cached.FullName}}
 }
 if(-not $LuaRunner){throw 'Provide a Lua runner with -LuaRunner.'}
 $result=@(& $LuaRunner tests/flights.lua 2>&1);$result | ForEach-Object {Write-Host $_}
 if($LASTEXITCODE -ne 0 -or [string]$result[-1] -notmatch '^PASS: \d+ flight path finder assertions$'){throw 'Flight Path Finder tests failed'}
 $toc=Get-Content FlightPathFinder/FlightPathFinder.toc -Raw
 if($toc -ne (Get-Content FlightPathFinder/FlightPathFinder_Camelot.toc -Raw)){throw 'Client manifests differ'}
 $version=[regex]::Match($toc,'(?m)^## Version: (.+)\r?$').Groups[1].Value.Trim()
 if($version -notmatch '^\d+\.\d+\.\d+-beta\.\d+$'){throw 'Invalid version'}
 $files=@('FlightPathFinder.toc','FlightPathFinder_Camelot.toc','README.md','LICENSE','CHANGELOG.md')+@($toc -split '\r?\n' | Where-Object {$_ -and -not $_.StartsWith('#')})
 foreach($file in Get-ChildItem FlightPathFinder -File){if($file.Name -notin $files){throw 'Unexpected addon file'}}
 foreach($name in $files){if($name -notmatch '^[A-Za-z][A-Za-z0-9_.-]+$' -or -not(Test-Path -LiteralPath ('FlightPathFinder/'+$name))){throw 'Invalid declared file'};if($name -match '\.lua$' -and [IO.File]::ReadAllText((Join-Path $repo ('FlightPathFinder/'+$name))) -match '\b(?:SendInput|RunMacroText|ReloadUI|loadstring)\b'){throw 'Public source audit failed'}}
 New-Item -ItemType Directory -Path dist -Force | Out-Null
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $path=Join-Path $repo ('dist/FlightPathFinder-'+$version+'.zip')
 $stream=[IO.File]::Open($path,[IO.FileMode]::Create);$zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
 try{foreach($name in $files){$entry=$zip.CreateEntry('FlightPathFinder/'+$name,[IO.Compression.CompressionLevel]::Optimal);$input=[IO.File]::OpenRead((Join-Path $repo ('FlightPathFinder/'+$name)));$output=$entry.Open();try{$input.CopyTo($output)}finally{$input.Dispose();$output.Dispose()}}}finally{$zip.Dispose();$stream.Dispose()}
 & node scripts/verify-uber-zip.cjs $path FlightPathFinder
 if($LASTEXITCODE -ne 0){throw 'ZIP header/CRC validation failed'}
 (Get-FileHash -LiteralPath $path).Hash | Set-Content -LiteralPath ($path+'.sha256') -Encoding ascii
 Write-Output $path
}finally{Pop-Location}
