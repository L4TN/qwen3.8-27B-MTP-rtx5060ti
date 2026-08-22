# Qwen 3 27B - RTX 5060 Ti - Menu Bisturi vs Canhao
$ErrorActionPreference = "Stop"
$LLAMA = "C:\llamacpp\llama-server.exe"

if (-not (Test-Path $LLAMA)) { Write-Error "llama-server nao encontrado em $LLAMA"; exit 1 }

nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

Write-Host ""
Write-Host "Escolha o modo:" -ForegroundColor Cyan
Write-Host "  [1] 🔪 BISTURI  - IQ4_XS 32K Q8  (precisao maxima, 52 t/s, 15.8GB) - Recomendado" -ForegroundColor Green
Write-Host "  [2] 🚀 CANHAO   - IQ3_XXS 94K Q4 (contexto monstro, 60 t/s, 14.1GB)" -ForegroundColor Yellow
Write-Host ""
$choice = Read-Host "Digite 1 ou 2 (default 1)"

if ($choice -eq "2") {
    $MODEL = "C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"
    $CTX = "94208"; $KVK = "q4_0"; $KVV = "q4_0"
    $DESC = "CANHAO - IQ3_XXS 94K Q4"
} else {
    $MODEL = "C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"
    $CTX = "32768"; $KVK = "q8_0"; $KVV = "q8_0"
    $DESC = "BISTURI - IQ4_XS 32K Q8"
}

if (-not (Test-Path $MODEL)) { Write-Error "Modelo nao encontrado em $MODEL. Baixe para C:\modelos\"; exit 1 }

$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'

Write-Host ""
Write-Host "Iniciando MODO $DESC em http://127.0.0.1:1234" -ForegroundColor Cyan
Write-Host "Modelo: $MODEL | ctx $CTX | KV $KVK" -ForegroundColor DarkGray

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
