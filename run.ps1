# Qwen3.8-27B UD-IQ4_XS + MTP - RTX 5060 Ti
# Uso: .\run.ps1  (ou powershell -ExecutionPolicy Bypass -File .\run.ps1)

$ErrorActionPreference = "Stop"

# Caminhos - ajuste se necessario
$LLAMA = "C:\llamacpp\llama-server.exe"
$MODEL = "C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"

if (-not (Test-Path $LLAMA)) { Write-Error "llama-server nao encontrado em $LLAMA. Instale conforme README."; exit 1 }
if (-not (Test-Path $MODEL)) { Write-Error "Modelo nao encontrado em $MODEL. Baixe para C:\modelos\"; exit 1 }

# Checa VRAM
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'

Write-Host "Iniciando Qwen3.8-27B IQ4_XS + MTP n=3 em http://127.0.0.1:1234" -ForegroundColor Cyan

& $LLAMA -m $MODEL `
 --no-mmproj --device CUDA0 `
 --spec-draft-device CUDA0 --gpu-layers-draft all `
 --spec-type draft-mtp --spec-draft-n-max 3 `
 --n-gpu-layers all --threads 6 `
 --fit off --load-mode none --no-warmup --flash-attn on `
 --ctx-size 32768 --parallel 1 `
 --cache-type-k q8_0 --cache-type-v q8_0 `
 --batch-size 512 --ubatch-size 512 `
 --jinja --temp 1 --top-p 0.95 --top-k 20 `
 --reasoning auto --reasoning-preserve --reasoning-effort medium `
 --host 127.0.0.1 --port 1234 -lv 4
