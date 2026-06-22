param(
  [Parameter(Mandatory=$true)][string]$SourceDir,
  [Parameter(Mandatory=$true)][string]$OutputDir
)

Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath {
  param([System.Drawing.RectangleF]$Rect, [float]$Radius)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $Radius * 2
  $path.AddArc($Rect.X, $Rect.Y, $d, $d, 180, 90)
  $path.AddArc($Rect.Right - $d, $Rect.Y, $d, $d, 270, 90)
  $path.AddArc($Rect.Right - $d, $Rect.Bottom - $d, $d, $d, 0, 90)
  $path.AddArc($Rect.X, $Rect.Bottom - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Get-SampleColor {
  param([System.Drawing.Bitmap]$Bitmap, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2)
  $r = 0; $g = 0; $b = 0; $n = 0
  $maxX = [Math]::Min($Bitmap.Width - 1, $X2)
  $maxY = [Math]::Min($Bitmap.Height - 1, $Y2)
  for ($x = [Math]::Max(0, $X1); $x -le $maxX; $x += 8) {
    for ($y = [Math]::Max(0, $Y1); $y -le $maxY; $y += 8) {
      $c = $Bitmap.GetPixel($x, $y)
      $r += $c.R; $g += $c.G; $b += $c.B; $n++
    }
  }
  if ($n -eq 0) { return [System.Drawing.Color]::FromArgb(245,245,245) }
  return [System.Drawing.Color]::FromArgb([int]($r/$n), [int]($g/$n), [int]($b/$n))
}

function Mix-Color {
  param([System.Drawing.Color]$A, [System.Drawing.Color]$B, [double]$T)
  return [System.Drawing.Color]::FromArgb(
    [int]($A.R * (1-$T) + $B.R * $T),
    [int]($A.G * (1-$T) + $B.G * $T),
    [int]($A.B * (1-$T) + $B.B * $T)
  )
}

function U {
  param([int[]]$Codes)
  return -join ($Codes | ForEach-Object { [char]$_ })
}

function Draw-FitImage {
  param([System.Drawing.Graphics]$Graphics, [System.Drawing.Image]$Image)
  $scale = [Math]::Max(800.0 / $Image.Width, 800.0 / $Image.Height)
  $w = [int][Math]::Ceiling($Image.Width * $scale)
  $h = [int][Math]::Ceiling($Image.Height * $scale)
  $x = [int]((800 - $w) / 2)
  $y = [int]((800 - $h) / 2)
  $dest = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
  $Graphics.DrawImage($Image, $dest)
}

function Optimize-One {
  param([string]$InputPath, [string]$OutputPath)
  $src = [System.Drawing.Image]::FromFile($InputPath)
  $base = New-Object System.Drawing.Bitmap(800, 800, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($base)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.Clear([System.Drawing.Color]::White)
  Draw-FitImage -Graphics $g -Image $src
  $g.Dispose()
  $src.Dispose()

  $canvas = New-Object System.Drawing.Bitmap(800, 800, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g2 = [System.Drawing.Graphics]::FromImage($canvas)
  $g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g2.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

  $ia = New-Object System.Drawing.Imaging.ImageAttributes
  $matrix = New-Object System.Drawing.Imaging.ColorMatrix
  $matrix.Matrix00 = 1.08; $matrix.Matrix11 = 1.08; $matrix.Matrix22 = 1.08
  $matrix.Matrix40 = 0.015; $matrix.Matrix41 = 0.015; $matrix.Matrix42 = 0.015
  $ia.SetColorMatrix($matrix)
  $rect = New-Object System.Drawing.Rectangle(0, 0, 800, 800)
  $g2.DrawImage($base, $rect, 0, 0, 800, 800, [System.Drawing.GraphicsUnit]::Pixel, $ia)

  $cornerColor = Get-SampleColor -Bitmap $base -X1 600 -Y1 115 -X2 780 -Y2 220
  $soft = Mix-Color -A $cornerColor -B ([System.Drawing.Color]::White) -T 0.18
  $cornerBrush = New-Object System.Drawing.SolidBrush($soft)
  $g2.FillRectangle($cornerBrush, 636, 0, 164, 126)
  $cornerBrush.Dispose()

  $edgePen = New-Object System.Drawing.Pen((Mix-Color -A $soft -B ([System.Drawing.Color]::Black) -T 0.10), 1)
  $g2.DrawLine($edgePen, 636, 126, 800, 126)
  $edgePen.Dispose()

  $leftTopColor = Get-SampleColor -Bitmap $base -X1 20 -Y1 150 -X2 360 -Y2 260
  $leftTopSoft = Mix-Color -A $leftTopColor -B ([System.Drawing.Color]::White) -T 0.20
  $leftTopRect = New-Object System.Drawing.Rectangle(0, 76, 342, 88)
  $leftTopBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($leftTopRect, $leftTopSoft, (Mix-Color -A $leftTopSoft -B ([System.Drawing.Color]::White) -T 0.18), 0)
  $g2.FillRectangle($leftTopBrush, $leftTopRect)
  $leftTopBrush.Dispose()

  $badgeColor = Get-SampleColor -Bitmap $base -X1 670 -Y1 525 -X2 792 -Y2 660
  $badgeBrush = New-Object System.Drawing.SolidBrush((Mix-Color -A $badgeColor -B ([System.Drawing.Color]::White) -T 0.14))
  $g2.FillRectangle($badgeBrush, 688, 556, 112, 92)
  $badgeBrush.Dispose()

  $bottomColor = Get-SampleColor -Bitmap $base -X1 0 -Y1 632 -X2 799 -Y2 790
  $dark = Mix-Color -A $bottomColor -B ([System.Drawing.Color]::FromArgb(32,32,32)) -T 0.50
  $light = Mix-Color -A $bottomColor -B ([System.Drawing.Color]::White) -T 0.28
  $barRect = New-Object System.Drawing.Rectangle(0, 638, 800, 162)
  $barBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($barRect, $dark, $light, 0)
  $g2.FillRectangle($barBrush, $barRect)
  $barBrush.Dispose()

  $fontTitle = New-Object System.Drawing.Font("Microsoft YaHei", 28, [System.Drawing.FontStyle]::Bold)
  $fontSmall = New-Object System.Drawing.Font("Microsoft YaHei", 15, [System.Drawing.FontStyle]::Regular)
  $fontLabel = New-Object System.Drawing.Font("Microsoft YaHei", 13, [System.Drawing.FontStyle]::Regular)
  $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
  $muted = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235,235,235))
  $titleText = U @(0x9AD8,0x6E05,0x5C55,0x793A)
  $subText = (U @(0x4E3B,0x4F53,0x7A81,0x51FA)) + "  " + (U @(0x7EC6,0x8282,0x6E05,0x6670)) + "  " + (U @(0x573A,0x666F,0x642D,0x914D))
  $g2.DrawString($titleText, $fontTitle, $white, 34, 662)
  $g2.DrawString($subText, $fontSmall, $muted, 36, 716)

  $labels = @(
    (U @(0x5B9E,0x62CD,0x5C55,0x793A)),
    (U @(0x7EC6,0x8282,0x6E05,0x6670)),
    (U @(0x573A,0x666F,0x642D,0x914D))
  )
  for ($i = 0; $i -lt 3; $i++) {
    $cx = 492 + $i * 100
    $iconBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245,245,245))
    $g2.FillEllipse($iconBrush, $cx, 670, 44, 44)
    $iconBrush.Dispose()
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80,80,80), 3)
    $g2.DrawEllipse($pen, $cx + 12, 682, 20, 20)
    $pen.Dispose()
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $textRect = New-Object System.Drawing.RectangleF ([single]($cx - 25)), ([single]719), ([single]94), ([single]24)
    $g2.DrawString($labels[$i], $fontLabel, $white, $textRect, $sf)
    $sf.Dispose()
  }

  $fontTitle.Dispose(); $fontSmall.Dispose(); $fontLabel.Dispose(); $white.Dispose(); $muted.Dispose()
  $g2.Dispose()
  $base.Dispose()
  $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $canvas.Dispose()
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$files = Get-ChildItem -LiteralPath $SourceDir -File | Where-Object { $_.Extension -match '^\.(jpg|jpeg|png|webp|bmp)$' }
$count = 0
foreach ($f in $files) {
  $out = Join-Path $OutputDir ($f.BaseName + ".png")
  Optimize-One -InputPath $f.FullName -OutputPath $out
  $count++
  if (($count % 20) -eq 0) { Write-Output "processed $count / $($files.Count)" }
}
Write-Output "done $count"
