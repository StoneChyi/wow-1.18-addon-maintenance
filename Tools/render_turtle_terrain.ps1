param([Parameter(Mandatory=$true)][string]$Jobs)
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'TurtleTerrainRaster.cs')
foreach ($job in [IO.File]::ReadAllLines($Jobs)) {
    if ($job) { [TurtleTerrainRaster]::Render($job) }
}
