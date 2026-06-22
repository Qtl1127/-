---
name: automate-main-images
description: Batch optimize product/e-commerce main images using the project's automated main-image workflow. Use when the user asks for 自动化主图, 批量主图优化, 批量生成/处理商品主图, main image optimization, or converting a folder of product photos into consistent 800x800 PNG main images.
---

# Automate Main Images

Use this skill to batch process a folder of product photos into marketplace-style main images with the existing PowerShell workflow.

## Inputs

- `SourceDir`: folder containing source images.
- `OutputDir`: folder where optimized PNG files should be written.
- Supported source extensions: `.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`.

If the user does not provide paths, ask for the source folder and output folder. If only a source folder is provided, choose a clear output folder such as `optimized-main-images` next to the source folder.

## Workflow

1. Locate this skill folder, then use `scripts/batch_optimize_main_images.ps1`.
2. Use absolute paths for both input and output folders.
3. Run the script from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill-folder>\scripts\batch_optimize_main_images.ps1" -SourceDir "<source-folder>" -OutputDir "<output-folder>"
```

4. Verify the script reports `done <count>`.
5. Count supported source files and generated `.png` files. If counts differ, inspect the command output and source file formats before reporting success.
6. For user-facing delivery, report the output folder and number of processed images. If visual inspection tools are available, inspect one representative output image before finalizing.

## Output Style

The bundled script creates 800x800 PNG images. It scales/crops the source photo to fill the square canvas, lightly brightens the image, samples colors from the source, and adds a bottom information band with Chinese product-display labels.

## Editing The Workflow

If the user asks to change image size, label text, layout, colors, badge placement, or export format, edit `scripts/batch_optimize_main_images.ps1` and test with a small image set before processing a full folder.

Preserve the script's batch interface unless the user asks otherwise:

```powershell
param(
  [Parameter(Mandatory=$true)][string]$SourceDir,
  [Parameter(Mandatory=$true)][string]$OutputDir
)
```

## Troubleshooting

- This workflow is intended for Windows PowerShell with `System.Drawing`.
- If font rendering differs, keep using `Microsoft YaHei` unless the user asks for a different Chinese font.
- If the output folder already contains files with the same base names, the script may overwrite those PNG outputs. Choose a fresh output folder when preserving previous results matters.
