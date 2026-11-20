$ErrorActionPreference = 'Stop'

$agentDir = $env:PI_CODING_AGENT_DIR
if (-not $agentDir)
{
    $agentDir = Join-Path $HOME '.pi\agent'
}
$destination = Join-Path $agentDir 'skills'
New-Item -ItemType Directory -Path $destination -Force | Out-Null

$retiredLauncher = Join-Path $destination 'claude-dagu-pipeline'
if (Test-Path -LiteralPath $retiredLauncher)
{
    Remove-Item -LiteralPath $retiredLauncher -Recurse -Force
}

$skillRoots = 'development-pipeline', 'dagu\skills', 'utility' | ForEach-Object { Join-Path $PSScriptRoot $_ }
Get-ChildItem -LiteralPath $skillRoots -Filter SKILL.md -File -Recurse | ForEach-Object {
    Copy-Item -LiteralPath $_.DirectoryName -Destination $destination -Recurse -Force
}
