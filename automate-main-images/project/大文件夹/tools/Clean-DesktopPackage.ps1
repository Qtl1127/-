param(
  [Parameter(Mandatory=$true)][string]$Target
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Target)) {
  throw "Target folder missing: $Target"
}

Get-ChildItem -LiteralPath $Target -Directory | ForEach-Object {
  if ($_.Name -match "^\d+$") {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
  }
}

$fileCount = (Get-ChildItem -LiteralPath $Target -Recurse -File).Count
$totalBytes = (Get-ChildItem -LiteralPath $Target -Recurse -File | Measure-Object -Property Length -Sum).Sum

[pscustomobject]@{
  Target = $Target
  Files = $fileCount
  SizeGB = [Math]::Round($totalBytes / 1GB, 2)
} | Format-List
