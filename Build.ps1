param([string]$LuaRunner)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'scripts/build-guild-release.ps1') -LuaRunner $LuaRunner
