param(
  [Parameter(Mandatory=$true)][string]$Name,
  [Parameter(Mandatory=$true)][string]$GeneratedRoot,
  [Parameter(Mandatory=$true)][string]$OutputDir,
  [Parameter(Mandatory=$true)][string]$LogDir,
  [Parameter(Mandatory=$true)][string]$Note
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Force -Path $OutputDir, $LogDir | Out-Null

$srcImg = Get-ChildItem -LiteralPath $GeneratedRoot -Recurse -File -Filter "*.png" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $srcImg) {
  throw "No generated PNG found under $GeneratedRoot"
}

$outPath = Join-Path $OutputDir ($Name + ".png")
if (Test-Path -LiteralPath $outPath) {
  Remove-Item -LiteralPath $outPath -Force
}

$src = [System.Drawing.Image]::FromFile($srcImg.FullName)
$side = [Math]::Min($src.Width, $src.Height)
$cropX = [int](($src.Width - $side) / 2)
$cropY = [int](($src.Height - $side) / 2)
$cropRect = [System.Drawing.Rectangle]::new($cropX, $cropY, $side, $side)
$bmp = [System.Drawing.Bitmap]::new(8192, 8192, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$bmp.SetResolution(300, 300)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.DrawImage($src, [System.Drawing.Rectangle]::new(0, 0, 8192, 8192), $cropRect, [System.Drawing.GraphicsUnit]::Pixel)
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
$src.Dispose()

$logPath = Join-Path $LogDir ($Name + "_处理日志.md")
$append = @(
  "",
  "## GPT regenerate record",
  "",
  "- Status: regenerated with GPT image channel and replaced upgraded image.",
  "- Output size: 8192 x 8192",
  "- Replaced file: " + $outPath,
  "- Generated source: " + $srcImg.FullName,
  "- Note: " + $Note
)
$append | Add-Content -LiteralPath $logPath -Encoding UTF8

[pscustomobject]@{
  Name = $Name
  SavedPath = $outPath
  Source = $srcImg.FullName
} | Format-List
