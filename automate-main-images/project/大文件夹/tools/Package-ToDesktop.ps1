param(
  [Parameter(Mandatory=$true)][string]$SourceRoot
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceRoot)) {
  throw "Source root missing: $SourceRoot"
}

$desktop = [Environment]::GetFolderPath("Desktop")
if ([string]::IsNullOrWhiteSpace($desktop)) {
  throw "Desktop path not found."
}

$target = Join-Path $desktop ("ECOM_IMAGE_UPGRADE_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Path $target -Force | Out-Null

Get-ChildItem -LiteralPath $SourceRoot | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
}

$fileCount = (Get-ChildItem -LiteralPath $target -Recurse -File).Count
$totalBytes = (Get-ChildItem -LiteralPath $target -Recurse -File | Measure-Object -Property Length -Sum).Sum

[pscustomobject]@{
  Target = $target
  Files = $fileCount
  SizeGB = [Math]::Round($totalBytes / 1GB, 2)
} | Format-List
