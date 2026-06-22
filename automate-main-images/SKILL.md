---
name: automate-main-images
description: "电商商品主图自动化升级、提示词改写、批量处理、质量检查和归档工作流。Use when the user asks for 自动化主图, 批量主图优化, 商品主图升级, 电商主图质检, 根据提示词优化商品图, L3 主图升级, or processing product images with the bundled 自动化主图 project rules."
---

# Automate Main Images

Use this skill to run the user's bundled 自动化主图 workflow. This is a prompt- and rule-driven product image upgrade workflow, not a fixed overlay/template script.

## Bundled Project

The original project is bundled under:

`project/大文件夹/`

Key folders:

- `01_原图文件夹/`: source product images.
- `02_完成后文件夹/`: completed output/archive area.
- `03_规则文件夹/`: mandatory workflow and visual rules.
- `04_提示词文件夹/`: SPU-specific prompts and `通用提示词.txt`.
- `05_质检员/`: quality-check rubric.
- `tools/`: original helper scripts.
- `tmp/`: temporary/checking artifacts from prior runs.
- `商品编码命名图片_20260612_无角标/`: prior generated output batch.

## Required Reads

Before generating, editing, evaluating, or archiving product images, read these files from `project/大文件夹/`:

1. `AGENTS.md`
2. `03_规则文件夹/00_总规则.md`
3. `03_规则文件夹/01_不可改变项.md`
4. `03_规则文件夹/02_处理流程.md`
5. `03_规则文件夹/03_风格统一规则.md`
6. `03_规则文件夹/04_GPT生图规则.md`
7. `03_规则文件夹/05_失败处理规则.md`
8. `03_规则文件夹/06_人工确认规则.md`
9. `03_规则文件夹/09_太阳镜批次专项规则.md`
10. `03_规则文件夹/10_文案卖点排版提示词改写规则.md`
11. `05_质检员/电商主图质检员.md`

Also read `04_提示词文件夹/通用提示词.txt` when it exists. In the current bundled project this file may be absent; when absent, treat it as a missing fallback prompt rather than assuming a default prompt exists.

If the request mentions WCZ, 轻奢家居, home decor, or explicitly asks for the WCZ special workflow, also read:

- `03_规则文件夹/08_WCZ轻奢家居主图规则.md`

## Input Matching

Process one SPU or image task at a time unless the user explicitly asks for batch supervision.

- Treat each subfolder under `01_原图文件夹/` as one SPU.
- If images are directly inside `01_原图文件夹/`, treat each image as a single-image task.
- Match prompt files in `04_提示词文件夹/` by SPU or image base name first.
- If no same-name prompt exists and `04_提示词文件夹/通用提示词.txt` exists, use it and state that the general prompt was used.
- If neither a same-name prompt nor the general prompt exists, use the user's current message as the task prompt only when it contains enough concrete visual direction. Otherwise mark the task as blocked or pending confirmation.

Before formal processing, report:

- The task list: source image path, matched prompt source, and task type.
- Missing items: prompts, source images, size requirements, SPU folders, or other required materials.
- Suggested execution order: lower-risk and more complete tasks first.

## Image Upgrade Workflow

Use the bundled rules and the user's current prompt to guide image generation or image editing. Preserve product truth.

Default behavior:

- Upgrade strength is L3.
- Work from the provided product image. Do not invent a new product from scratch.
- Generate or edit toward an e-commerce main image with stronger layout, scene, composition, lighting, and information hierarchy.
- Output PNG with high visual quality.
- Use the prompt's requested size when present; otherwise default to 1440x1440 when available, falling back to 800x800 if needed.

Do not use a fixed overlay template on an already designed main image unless the user specifically asks for that template. If the input is already a complete designed main image and the user asks to optimize it, preserve the existing layout unless the prompt explicitly requests a redesign.

## Prompt Handling

When the user provides an instruction, combine it with the matched project prompt and rules:

1. Keep the user's newest request as the highest-priority creative direction.
2. Do not violate the immutable product constraints or quality-check rules.
3. Rewrite product selling points only according to `10_文案卖点排版提示词改写规则.md`.
4. Keep claims grounded in the original image, matched prompt, or explicit user request.
5. Do not copy unverifiable claims such as country of origin, certifications, patent claims, absolute guarantees, or unsupported technical specs.

For the sunglasses batch, preserve the sunglasses' frame shape, lens color, material, quantity, structure, hinge position, proportions, and core product meaning. If using an AI model, use compliant adult models and avoid unsafe or unrealistic person rendering.

## Quality Check

After each generated or edited image, run the quality-check workflow from `05_质检员/电商主图质检员.md`.

Pass criteria include:

- Product body is accurate and not swapped, distorted, or structurally changed.
- Text is readable and not garbled.
- Selling points are not duplicated or unsupported.
- Layout is clearly e-commerce-oriented and satisfies L3 upgrade requirements.
- No overlay, waist band, label, person, or background element blocks the product body.
- For wearable products, the wearing effect is physically plausible.

If quality check fails, do not move or mark source images as completed. Record the failure reason and ask for confirmation only when the rules require it.

## Batch Supervision

When the user says `跟进员跟进任务`, enter full batch supervision mode:

1. Continue through all processable tasks in `01_原图文件夹/`.
2. After each task, quality-check, confirm or auto-confirm according to the rules, archive, clear temporary files, rescan status, and continue.
3. Stop only for hard blocks: generation channel failure, P0 issue, missing required files, quality-check hard violation, temp cleanup failure, or explicit user pause.

## Archiving

Archive only after generation, quality check, and required confirmation:

- Move original images to `02_完成后文件夹/{SPU}/原图/`.
- Save upgraded images to `02_完成后文件夹/{SPU}/升级版/`.
- Write a processing log to `02_完成后文件夹/{SPU}/处理日志.md`.

For direct single-image tasks without SPU folders, save generated images under `02_完成后文件夹/升级版/` and logs under `02_完成后文件夹/处理日志/`.
