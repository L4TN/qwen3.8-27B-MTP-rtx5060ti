# Qwen3.8-27B - RTX 5060 Ti - MTP (IQ4 45K vs IQ3 94K)
$ErrorActionPreference = "Stop"
$LLAMA = "C:\llamacpp\llama-server.exe"

if (-not (Test-Path $LLAMA)) { Write-Error "llama-server not found at $LLAMA"; exit 1 }

nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

Write-Host ""
Write-Host "Select mode:" -ForegroundColor Cyan
Write-Host "  [1] High Precision - IQ4_XS 45K Q8  (max quality, 47.9/37.1 t/s, 15.9GB) - Recommended" -ForegroundColor Green
Write-Host "  [2] Extended Context - IQ3_XXS 94K Q4 (max context, 54.5/60.1 t/s, 14.1GB)" -ForegroundColor Yellow
Write-Host "      Also validated: IQ4_XS 32K 15.5GB and 40K 15.6GB with same Q8"
Write-Host ""
$choice = Read-Host "Enter 1 or 2 (default 1)"

if ($choice -eq "2") {
    $MODEL = "C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"
    $CTX = "94208"; $KVK = "q4_0"; $KVV = "q4_0"
    $DESC = "Extended Context - IQ3_XXS 94K Q4"
} else {
    $MODEL = "C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"
    $CTX = "45056"; $KVK = "q8_0"; $KVV = "q8_0"
    $DESC = "High Precision - IQ4_XS 45K Q8"
}

if (-not (Test-Path $MODEL)) { Write-Error "Model not found at $MODEL. Download to C:\modelos\"; exit 1 }

$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'

Write-Host ""
Write-Host "Starting $DESC on http://127.0.0.1:1234" -ForegroundColor Cyan
Write-Host "Model: $MODEL | ctx $CTX | KV $KVK" -ForegroundColor DarkGray

& $LLAMA -m $MODEL `
 --no-mmproj --device CUDA0 `
 --spec-draft-device CUDA0 --gpu-layers-draft all `
 --spec-type draft-mtp --spec-draft-n-max 3 `
 --n-gpu-layers all --threads 6 `
 --fit off --load-mode none --no-warmup --flash-attn on `
 --ctx-size $CTX --parallel 1 `
 --cache-type-k $KVK --cache-type-v $KVV `
 --batch-size 512 --ubatch-size 512 `
 --jinja --temp 1 --top-p 0.95 --top-k 20 `
 --reasoning auto --reasoning-preserve --reasoning-effort medium `
 --host 127.0.0.1 --port 1234 -lv 4
