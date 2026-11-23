# publish_wasm_run_libs.ps1 — 打包本机编译的 wasm_run jniLibs 为 Release 资产
#
# grain_video 的 release CI 不交叉编译 .so（frb build.rs + libclang 环境重），
# 改为发布预编译产物：本脚本打包 → 上传到 grain_engine 仓的
# wasm-run-<版本> Release → CI 下载解压进 android/app/src/main。
#
# 用法（PowerShell，仓库根目录执行）：
#   powershell -File android/publish_wasm_run_libs.ps1
# 然后到 GitHub 网页（grain_engine 仓）：
#   Releases → Draft a new release → Tag: wasm-run-0.1.0+2 → 上传 jniLibs.zip。

$ErrorActionPreference = 'Stop'
$androidDir = $PSScriptRoot
$repoRoot = Split-Path $androidDir -Parent
$src = Join-Path $androidDir 'app\src\main\jniLibs'
$out = Join-Path $repoRoot 'jniLibs.zip'

if (-not (Test-Path (Join-Path $src 'arm64-v8a\libwasm_run_dart.so'))) {
  throw "未找到 arm64-v8a .so，请先运行 android/build_wasm_run_so.sh 交叉编译。"
}
if (-not (Test-Path (Join-Path $src 'x86_64\libwasm_run_dart.so'))) {
  throw "未找到 x86_64 .so（模拟器需要），请先运行 android/build_wasm_run_so.sh。"
}

if (Test-Path $out) { Remove-Item $out }
Compress-Archive -Path $src -DestinationPath $out -CompressionLevel Optimal
$hash = Get-FileHash $out -Algorithm SHA256
Write-Host "打包完成: $out ($([math]::Round((Get-Item $out).Length/1MB,1)) MB)"
Write-Host "SHA256: $($hash.Hash)"
Write-Host ""
Write-Host "下一步：浏览器打开 https://github.com/HW-public/grain_engine/releases/new"
Write-Host "  Tag: wasm-run-0.1.0+2   上传: jniLibs.zip"
Write-Host "(tag 内的 + 号在 URL 中写 %2B：wasm-run-0.1.0%2B2)"
