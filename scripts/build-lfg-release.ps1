param([string]$LuaRunner)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $repo
try{
 if(-not $LuaRunner){
  $command=Get-Command lua,luajit,fengari -ErrorAction SilentlyContinue | Select-Object -First 1
  if($command){$LuaRunner=$command.Source}else{
   $cacheRoots=@((Join-Path $env:LOCALAPPDATA 'npm-cache\_npx'),(Join-Path $env:USERPROFILE 'AppData\Local\npm-cache\_npx')) | Select-Object -Unique
   $cached=foreach($cacheRoot in $cacheRoots){Get-ChildItem -Path (Join-Path $cacheRoot '*\node_modules\.bin\fengari.cmd') -Force -ErrorAction SilentlyContinue}
   $cached=$cached | Select-Object -First 1
   if($cached){$LuaRunner=$cached.FullName}
  }
 }
 if(-not $LuaRunner){throw 'Provide a Lua runner'}
 foreach($test in @('tests/lfg.lua','tests/lfg-advanced.lua')){
  $result=@(& $LuaRunner $test 2>&1);$result | ForEach-Object {Write-Host $_}
  if($LASTEXITCODE -ne 0 -or [string]$result[-1] -notmatch '^PASS: \d+ (?:advanced )?guild LFG assertions$'){throw 'Guild LFG tests failed'}
 }
 $toc=Get-Content TranquilityLFG/TranquilityLFG.toc -Raw
 if($toc -ne (Get-Content TranquilityLFG/TranquilityLFG_Camelot.toc -Raw)){throw 'LFG manifests differ'}
 $version=[regex]::Match($toc,'(?m)^## Version: (.+)\r?$').Groups[1].Value.Trim()
 if($version -notmatch '^\d+\.\d+\.\d+-beta\.\d+$'){throw 'Invalid version'}
 $files=@('TranquilityLFG.toc','TranquilityLFG_Camelot.toc','README.md','LICENSE')+@($toc -split '\r?\n' | Where-Object {$_ -and -not $_.StartsWith('#')})
 foreach($file in Get-ChildItem TranquilityLFG -File){if($file.Name -notin $files){throw 'Unexpected addon file'}}
 New-Item -ItemType Directory -Path dist -Force | Out-Null
 Add-Type -AssemblyName System.IO.Compression
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $zip=Join-Path $repo ('dist/TranquilityLFG-'+$version+'.zip')
 $stream=[IO.File]::Open($zip,[IO.FileMode]::Create)
 $archive=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
 try{foreach($file in $files){
  $entry=$archive.CreateEntry('TranquilityLFG/'+$file,[IO.Compression.CompressionLevel]::Optimal)
  $inputStream=[IO.File]::OpenRead((Join-Path $repo ('TranquilityLFG/'+$file)));$outputStream=$entry.Open()
  try{$inputStream.CopyTo($outputStream)}finally{$inputStream.Dispose();$outputStream.Dispose()}
 }}finally{$archive.Dispose();$stream.Dispose()}
 & node scripts/verify-uber-zip.cjs $zip TranquilityLFG
 if($LASTEXITCODE -ne 0){throw 'LFG raw ZIP validation failed'}
 (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash | Set-Content -LiteralPath ($zip+'.sha256') -Encoding ascii
 Write-Output $zip
}finally{Pop-Location}
