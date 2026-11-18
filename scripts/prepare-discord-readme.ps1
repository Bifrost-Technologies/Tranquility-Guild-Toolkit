$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$readme=[IO.File]::ReadAllText((Join-Path $repo 'curseforge\DISCORD-README.md'))
$target=Join-Path $repo 'curseforge\discord-posts'
New-Item -ItemType Directory -Path $target -Force | Out-Null
$chunks=[Collections.Generic.List[string]]::new()
$buffer=''
foreach ($paragraph in ($readme -split '(?:\r?\n){2,}')) {
    if ($paragraph.Length -gt 1900) { throw 'A Discord paragraph exceeds message size.' }
    if ($buffer.Length + $paragraph.Length + 2 -gt 1900) { $chunks.Add($buffer.Trim()); $buffer='' }
    $buffer += $paragraph + "`n`n"
}
if ($buffer.Trim()) { $chunks.Add($buffer.Trim()) }
$utf8=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $repo 'guild\README-DISCORD.md'),$readme,$utf8)
for ($i=0;$i -lt $chunks.Count;$i++) {
    $message='Part ' + ($i+1) + '/' + $chunks.Count + "`n`n" + $chunks[$i]
    if ($message.Length -gt 2000) { throw 'Discord message exceeds 2000 characters.' }
    [IO.File]::WriteAllText((Join-Path $target ('Post-' + ($i+1).ToString('00') + '.txt')),$message,$utf8)
}
foreach($file in Get-ChildItem -LiteralPath $target -File){
    if($file.Name -match '^Post-(\d+)\.txt$' -and [int]$Matches[1] -gt $chunks.Count){Remove-Item -LiteralPath $file.FullName}
}
Write-Output ("Prepared $($chunks.Count) Discord posts, each under 2000 characters.")
