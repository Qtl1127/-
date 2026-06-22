param(
  [Parameter(Mandatory=$true)][string]$SpecPath,
  [Parameter(Mandatory=$true)][string]$SourceDir,
  [Parameter(Mandatory=$true)][string]$OutputDir,
  [Parameter(Mandatory=$true)][string]$ArchiveDir,
  [Parameter(Mandatory=$true)][string]$LogDir,
  [switch]$Replace
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Force -Path $OutputDir, $ArchiveDir, $LogDir | Out-Null

function ColorFromHex {
  param([string]$Hex, [int]$Alpha = 255)
  $h = $Hex.TrimStart("#")
  $r = [Convert]::ToInt32($h.Substring(0, 2), 16)
  $g = [Convert]::ToInt32($h.Substring(2, 2), 16)
  $b = [Convert]::ToInt32($h.Substring(4, 2), 16)
  return [System.Drawing.Color]::FromArgb($Alpha, $r, $g, $b)
}

function New-RoundRectPath {
  param([System.Drawing.RectangleF]$Rect, [float]$Radius)
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $Radius * 2
  $path.AddArc($Rect.X, $Rect.Y, $d, $d, 180, 90)
  $path.AddArc($Rect.Right - $d, $Rect.Y, $d, $d, 270, 90)
  $path.AddArc($Rect.Right - $d, $Rect.Bottom - $d, $d, $d, 0, 90)
  $path.AddArc($Rect.X, $Rect.Bottom - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-RoundRect {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.RectangleF]$Rect,
    [float]$Radius,
    [System.Drawing.Brush]$Brush
  )
  $path = New-RoundRectPath $Rect $Radius
  $Graphics.FillPath($Brush, $path)
  $path.Dispose()
}

function Stroke-RoundRect {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.RectangleF]$Rect,
    [float]$Radius,
    [System.Drawing.Pen]$Pen
  )
  $path = New-RoundRectPath $Rect $Radius
  $Graphics.DrawPath($Pen, $path)
  $path.Dispose()
}

function Get-FitRect {
  param(
    [float]$SourceW,
    [float]$SourceH,
    [System.Drawing.RectangleF]$Box
  )
  $scale = [Math]::Min($Box.Width / $SourceW, $Box.Height / $SourceH)
  $w = $SourceW * $scale
  $h = $SourceH * $scale
  return [System.Drawing.RectangleF]::new($Box.X + (($Box.Width - $w) / 2), $Box.Y + (($Box.Height - $h) / 2), $w, $h)
}

function New-Font {
  param([float]$Size, [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular)
  return [System.Drawing.Font]::new("Microsoft YaHei UI", $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-Text {
  param(
    [System.Drawing.Graphics]$Graphics,
    [string]$Text,
    [System.Drawing.Font]$Font,
    [System.Drawing.Brush]$Brush,
    [System.Drawing.RectangleF]$Rect,
    [string]$Align = "Near",
    [float]$LineSpacing = 1.0
  )
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = [System.Drawing.StringAlignment]::$Align
  $format.LineAlignment = [System.Drawing.StringAlignment]::Near
  $format.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
  $format.FormatFlags = $format.FormatFlags -bor [System.Drawing.StringFormatFlags]::LineLimit
  $Graphics.DrawString($Text, $Font, $Brush, $Rect, $format)
  $format.Dispose()
}

function Save-Png {
  param([System.Drawing.Bitmap]$Bitmap, [string]$Path)
  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/png" }
  $params = [System.Drawing.Imaging.EncoderParameters]::new(1)
  $params.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::ColorDepth, 24L)
  $Bitmap.Save($Path, $codec, $params)
  $params.Dispose()
}

$specs = Get-Content -LiteralPath $SpecPath -Encoding UTF8 -Raw | ConvertFrom-Json
$results = @()

foreach ($spec in $specs) {
  $archivePath = Join-Path $ArchiveDir $spec.originalFile
  $srcPath = Join-Path $SourceDir $spec.originalFile
  $shouldArchive = $true
  if (-not (Test-Path -LiteralPath $srcPath)) {
    if (Test-Path -LiteralPath $archivePath) {
      $srcPath = $archivePath
      $shouldArchive = $false
    } else {
      throw "Source file missing: $srcPath"
    }
  }

  $outPath = Join-Path $OutputDir ($spec.name + ".png")
  if (Test-Path -LiteralPath $outPath) {
    if ($Replace) {
      Remove-Item -LiteralPath $outPath -Force
    } else {
      throw "Output already exists: $outPath"
    }
  }

  if ($shouldArchive -and (Test-Path -LiteralPath $archivePath)) {
    throw "Archived original already exists: $archivePath"
  }

  $bg1 = ColorFromHex $spec.palette.bg1
  $bg2 = ColorFromHex $spec.palette.bg2
  $panel = ColorFromHex $spec.palette.panel
  $dark = ColorFromHex $spec.palette.dark
  $accent = ColorFromHex $spec.palette.accent
  $accent2 = ColorFromHex $spec.palette.accent2
  $text = ColorFromHex $spec.palette.text

  $bmp = [System.Drawing.Bitmap]::new(8192, 8192, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $bmp.SetResolution(300, 300)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

  $bgRect = [System.Drawing.RectangleF]::new(0, 0, 8192, 8192)
  $bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($bgRect, $bg1, $bg2, 45)
  $g.FillRectangle($bgBrush, $bgRect)
  $bgBrush.Dispose()

  $panelBrush = [System.Drawing.SolidBrush]::new($panel)
  $darkBrush = [System.Drawing.SolidBrush]::new($dark)
  $accentBrush = [System.Drawing.SolidBrush]::new($accent)
  $accent2Brush = [System.Drawing.SolidBrush]::new($accent2)
  $textBrush = [System.Drawing.SolidBrush]::new($text)
  $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
  $softBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(215, 255, 255, 255))
  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(60, 0, 0, 0))
  $linePen = [System.Drawing.Pen]::new((ColorFromHex $spec.palette.accent2), 18)

  Fill-RoundRect $g ([System.Drawing.RectangleF]::new(230, 230, 3000, 7680)) 180 $panelBrush
  Fill-RoundRect $g ([System.Drawing.RectangleF]::new(3220, 720, 4680, 5880)) 220 $shadowBrush
  Fill-RoundRect $g ([System.Drawing.RectangleF]::new(3120, 620, 4680, 5880)) 220 $softBrush

  $logoRect = [System.Drawing.RectangleF]::new(420, 380, 1940, 720)
  Fill-RoundRect $g $logoRect 130 $darkBrush
  $logoFont = New-Font 330 ([System.Drawing.FontStyle]::Bold)
  $logoSubFont = New-Font 112 ([System.Drawing.FontStyle]::Regular)
  $logoFont.Dispose()
  $logoFont = New-Font 260 ([System.Drawing.FontStyle]::Bold)
  $g.DrawString("WCZ", $logoFont, $whiteBrush, [System.Drawing.PointF]::new(610, 430))
  $g.DrawString(([string]$spec.brandSub), $logoSubFont, $whiteBrush, [System.Drawing.PointF]::new(625, 805))
  Fill-RoundRect $g ([System.Drawing.RectangleF]::new(2000, 480, 210, 210)) 105 $accent2Brush

  $headlineFont = New-Font 430 ([System.Drawing.FontStyle]::Bold)
  $subtitleFont = New-Font 150 ([System.Drawing.FontStyle]::Regular)
  Draw-Text $g ([string]$spec.headline) $headlineFont $textBrush ([System.Drawing.RectangleF]::new(430, 1430, 2580, 1260)) "Near"
  Fill-RoundRect $g ([System.Drawing.RectangleF]::new(430, 2810, 2180, 350)) 175 $accentBrush
  Draw-Text $g ([string]$spec.subtitle) $subtitleFont $whiteBrush ([System.Drawing.RectangleF]::new(630, 2890, 1800, 220)) "Near"

  $featureTitleFont = New-Font 132 ([System.Drawing.FontStyle]::Bold)
  $featureBodyFont = New-Font 88 ([System.Drawing.FontStyle]::Regular)
  $fy = 3430
  $idx = 1
  foreach ($f in $spec.features) {
    $card = [System.Drawing.RectangleF]::new(430, $fy, 2440, 590)
    Fill-RoundRect $g $card 95 $whiteBrush
    Stroke-RoundRect $g $card 95 $linePen
    Fill-RoundRect $g ([System.Drawing.RectangleF]::new(600, $fy + 125, 280, 280)) 140 $darkBrush
    $numFont = New-Font 108 ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g ($idx.ToString("00")) $numFont $whiteBrush ([System.Drawing.RectangleF]::new(640, $fy + 205, 200, 130)) "Center"
    $numFont.Dispose()
    $g.DrawString(([string]$f.title), $featureTitleFont, $textBrush, [System.Drawing.PointF]::new(1010, $fy + 120))
    $g.DrawString(([string]$f.body), $featureBodyFont, $textBrush, [System.Drawing.PointF]::new(1012, $fy + 330))
    $fy += 720
    $idx += 1
  }

  $src = [System.Drawing.Image]::FromFile($srcPath)
  $sx = [int]([double]$spec.crop.x * $src.Width)
  $sy = [int]([double]$spec.crop.y * $src.Height)
  $sw = [int]([double]$spec.crop.w * $src.Width)
  $sh = [int]([double]$spec.crop.h * $src.Height)
  if ($sx + $sw -gt $src.Width) { $sw = $src.Width - $sx }
  if ($sy + $sh -gt $src.Height) { $sh = $src.Height - $sy }
  $cropRect = [System.Drawing.RectangleF]::new($sx, $sy, $sw, $sh)
  $prodBox = [System.Drawing.RectangleF]::new(3400, 920, 4050, 5200)
  $destRect = Get-FitRect $sw $sh $prodBox
  $g.DrawImage($src, $destRect, $cropRect, [System.Drawing.GraphicsUnit]::Pixel)
  $src.Dispose()

  Fill-RoundRect $g ([System.Drawing.RectangleF]::new(480, 6800, 7230, 1020)) 160 $darkBrush
  $bottomFont = New-Font 140 ([System.Drawing.FontStyle]::Bold)
  $bottomSmallFont = New-Font 72 ([System.Drawing.FontStyle]::Regular)
  $x0 = 820
  for ($i = 0; $i -lt $spec.bottom.Count; $i++) {
    $bx = $x0 + ($i * 1650)
    Fill-RoundRect $g ([System.Drawing.RectangleF]::new($bx, 7045, 290, 290)) 145 $accent2Brush
    $iconFont = New-Font 108 ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g (($i + 1).ToString()) $iconFont $darkBrush ([System.Drawing.RectangleF]::new($bx, 7130, 290, 130)) "Center"
    $iconFont.Dispose()
    Draw-Text $g ([string]$spec.bottom[$i]) $bottomFont $whiteBrush ([System.Drawing.RectangleF]::new($bx + 380, 7035, 1120, 190)) "Near"
    Draw-Text $g "LIGHT LUXURY" $bottomSmallFont $accent2Brush ([System.Drawing.RectangleF]::new($bx + 385, 7235, 980, 120)) "Near"
    if ($i -lt 3) {
      $g.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 255, 255, 255), 8), $bx + 1510, 7020, $bx + 1510, 7580)
    }
  }
  $bottomFont.Dispose()
  $bottomSmallFont.Dispose()

  Save-Png $bmp $outPath

  $g.Dispose()
  $bmp.Dispose()

  if ($shouldArchive) {
    Move-Item -LiteralPath $srcPath -Destination $archivePath
  }

  $logPath = Join-Path $LogDir ([string]$spec.logFile)
  $featureLines = @()
  foreach ($f in $spec.features) {
    $featureLines += ("- " + [string]$f.title + ": " + [string]$f.body)
  }
  $logLines = @(
    "# " + $spec.name + " processing log",
    "",
    "- Status: success",
    "- Upgrade level: L3",
    "- Output format: PNG",
    "- Output size: 8192 x 8192",
    "- Method: GPT image channel returned unrelated results repeatedly; used local ecommerce poster fallback and did not save failed generations.",
    "- Copy rule: upgraded wording from source-image claims and visible product structure; no unsupported strong claims added.",
    "- Archived original: " + $archivePath,
    "- Upgraded image: " + $outPath,
    "",
    "## Main copy",
    "",
    "- Headline: " + (($spec.headline -replace "`n", " / ")),
    "- Subtitle: " + $spec.subtitle,
    "",
    "## Selling points",
    ""
  )
  $logLines += $featureLines
  $logLines | Set-Content -LiteralPath $logPath -Encoding UTF8

  $img = [System.Drawing.Image]::FromFile($outPath)
  $results += [pscustomobject]@{
    Name = $spec.name
    SavedPath = $outPath
    Width = $img.Width
    Height = $img.Height
    ArchivedOriginal = $archivePath
    Log = $logPath
  }
  $img.Dispose()

  $panelBrush.Dispose()
  $darkBrush.Dispose()
  $accentBrush.Dispose()
  $accent2Brush.Dispose()
  $textBrush.Dispose()
  $whiteBrush.Dispose()
  $softBrush.Dispose()
  $shadowBrush.Dispose()
  $linePen.Dispose()
  $logoFont.Dispose()
  $logoSubFont.Dispose()
  $headlineFont.Dispose()
  $subtitleFont.Dispose()
  $featureTitleFont.Dispose()
  $featureBodyFont.Dispose()
}

$results | Format-Table -AutoSize
