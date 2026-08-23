# Start IQ4_XS 64000 q4_0 - market 64K
$ErrorActionPreference = "Stop"
$LLAMA = "C:\llamacpp\llama-server.exe"
$MODEL = "C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"
if (-not (Test-Path $LLAMA)) { Write-Error "llama-server not found at $LLAMA - install llama.cpp b10586 CUDA 13.3 to C:\llamacpp"; exit 1 }
if (-not (Test-Path $MODEL)) { Write-Error "Model not found at $MODEL - download IQ4_XS to C:\modelos"; exit 1 }
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'
Write-Host "Starting IQ4_XS 64000 q4_0 - market 64K on http://127.0.0.1:1234" -ForegroundColor Green
Write-Host "Model: $MODEL | ctx 64000 | KV q4_0 | MTP n=3 | threads 6 | market 64K" -ForegroundColor DarkGray
& $LLAMA -m $MODEL --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 64000 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234 -lv 4
