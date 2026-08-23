# Start IQ3_XXS 150K Q4 - Extended Context (sweet spot 15.0GB / 16.3GB, max 250K fits)
$ErrorActionPreference = "Stop"
$LLAMA = "C:\llamacpp\llama-server.exe"
$MODEL = "C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"

if (-not (Test-Path $LLAMA)) { Write-Error "llama-server not found at $LLAMA - install llama.cpp b10586 CUDA 13.3 to C:\llamacpp"; exit 1 }
if (-not (Test-Path $MODEL)) { Write-Error "Model not found at $MODEL - download IQ3_XXS to C:\modelos"; exit 1 }

nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'

Write-Host "Starting IQ3_XXS 150K Q4 on http://127.0.0.1:1234 - VRAM 15.0GB / 16.3GB (15323 MiB)" -ForegroundColor Yellow
Write-Host "Model: $MODEL | ctx 150000 | KV q4_0 | MTP n=3 | threads 6" -ForegroundColor DarkGray
Write-Host "Note: 150K is sweet spot; 94K-250K validated, above 150K prompt drops to ~2.9 t/s" -ForegroundColor DarkGray

& $LLAMA -m $MODEL `
 --no-mmproj --device CUDA0 `
 --spec-draft-device CUDA0 --gpu-layers-draft all `
 --spec-type draft-mtp --spec-draft-n-max 3 `
 --n-gpu-layers all --threads 6 `
 --fit off --load-mode none --no-warmup --flash-attn on `
 --ctx-size 150000 --parallel 1 `
 --cache-type-k q4_0 --cache-type-v q4_0 `
 --batch-size 512 --ubatch-size 512 `
 --jinja --temp 1 --top-p 0.95 --top-k 20 `
 --reasoning auto --reasoning-preserve --reasoning-effort medium `
 --host 127.0.0.1 --port 1234 -lv 4
