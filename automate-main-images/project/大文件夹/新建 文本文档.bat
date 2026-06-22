@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ------------- 请确认这两个路径是正确的 -------------
set "picPath=C:\Users\荣越\Documents\自动化生图1\大文件夹\01_原图文件夹"
set "txtPath=C:\Users\荣越\Documents\自动化生图1\大文件夹\04_提示词文件夹"
:: --------------------------------------------------

:: 固定内容（用引号包裹，避免解析错误）
set "content=生成1张不同的电商主图，要求：不改变商品、不改变宣传卖点、更换跟原图不同的背景但要贴合产品、更换设计风格和排版（设计风格跟原图不要一样，让人有耳目一新的感觉，排版可以自由组合），左上角添加品牌LOGO（WCZ），最终目的是为了提高点击率和转化率 将宽高比设为 1:1"

:: 先检查图片文件夹是否存在
if not exist "%picPath%" (
    echo 错误：图片文件夹不存在！请检查路径：%picPath%
    pause
    exit /b
)

:: 创建txt文件夹（不存在就创建）
if not exist "%txtPath%" (
    md "%txtPath%"
    echo 已创建目标文件夹：%txtPath%
)

:: 遍历图片文件（增加了常见的webp格式）
echo 正在生成文件...
for %%a in ("%picPath%\*.jpg","%picPath%\*.png","%picPath%\*.jpeg","%picPath%\*.gif","%picPath%\*.webp") do (
    echo !content! > "%txtPath%\%%~na.txt"
    echo 已生成：%%~na.txt
)

echo.
echo 全部生成完成！
echo 生成的文件在：%txtPath%
pause