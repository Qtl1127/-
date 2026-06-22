param(
  [Parameter(Mandatory=$true)][string]$Name,
  [Parameter(Mandatory=$true)][string]$OriginalFile,
  [Parameter(Mandatory=$true)][string]$GeneratedDir,
  [Parameter(Mandatory=$true)][string]$SourceDir,
  [Parameter(Mandatory=$true)][string]$OutputDir,
  [Parameter(Mandatory=$true)][string]$ArchiveDir
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Force -Path $OutputDir, $ArchiveDir | Out-Null

$srcImg = Get-ChildItem -LiteralPath $GeneratedDir -File -Filter "*.png" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $srcImg) {
  throw "No generated PNG found."
}

$outImg = Join-Path $OutputDir ($Name + ".png")
if (Test-Path -LiteralPath $outImg) {
  throw "Output already exists: $outImg"
}

$src = [System.Drawing.Image]::FromFile($srcImg.FullName)
$bmp = [System.Drawing.Bitmap]::new(8192, 8192, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.DrawImage($src, 0, 0, 8192, 8192)
$bmp.Save($outImg, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
$src.Dispose()

$origSrc = Join-Path $SourceDir $OriginalFile
$origDest = Join-Path $ArchiveDir $OriginalFile
if (-not (Test-Path -LiteralPath $origSrc)) {
  throw "Original file missing: $origSrc"
}
if (Test-Path -LiteralPath $origDest) {
  throw "Archived original already exists: $origDest"
}
Move-Item -LiteralPath $origSrc -Destination $origDest

$img = [System.Drawing.Image]::FromFile($outImg)
[pscustomobject]@{
  Name = $Name
  SavedPath = $outImg
  Width = $img.Width
  Height = $img.Height
  SizeMB = [Math]::Round((Get-Item -LiteralPath $outImg).Length / 1MB, 2)
  ArchivedOriginal = $origDest
} | Format-List
$img.Dispose()
