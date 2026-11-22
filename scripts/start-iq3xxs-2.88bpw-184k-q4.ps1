# ============================================================================
# Qwen3.8-27B IQ3_XXS 2.88bpw - RTX 5060 Ti 16GB - 184K Q4 - MTP
# Config definitiva: contexto grande + alta velocidade
#
# Modelo (ByteShape, 9.24 GiB):
#   https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf
#
# Medido nesta maquina (b12633 CUDA 13.5):
#   188416 ctx | ~15.4 GB VRAM | prompt ~945-1055 t/s (1.5K tokens)
#   geracao ~51-53 t/s | MTP draft acceptance 60-64% | startup ~6s (cache quente)
#
# Alternativas (basta trocar $Ctx ou usar -Ctx):
#   196608 = 192K -> ~15600 MiB (mais contexto, ~400 MiB livres)
#   180224 = 176K -> ~15150 MiB (mais folga)
#   163840 = 160K -> ~14880 MiB (config historicamente validada)
#
# Exemplo via CMD: run-qwen3.8-27b.bat -Ctx 196608
# ============================================================================
param(
  [int]$Ctx = 188416,
  [int]$Port = 1234
)
$ErrorActionPreference = "Stop"

$LLAMA = "C:\llamacpp\llama-server.exe"
$MODEL = "C:\Users\Administrator\Documents\AI\Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf"
$BIND_HOST = "0.0.0.0"
$LOCAL_URL = "127.0.0.1"

if (-not (Test-Path $LLAMA)) {
  Write-Host "ERRO: llama-server nao encontrado em $LLAMA" -ForegroundColor Red
  Write-Host "Extraia o build llama.cpp CUDA 13.5 (b12633) em C:\llamacpp" -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Path $MODEL)) {
  $candidates = @(
    Get-ChildItem "C:\Users\Administrator\Documents\AI" -Filter "*2.88bpw*.gguf" -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Users\Administrator\Documents\AI" -Filter "*IQ3_XXS*.gguf" -ErrorAction SilentlyContinue
    Get-ChildItem "C:\modelos" -Filter "*IQ3_XXS*.gguf" -ErrorAction SilentlyContinue
  ) | Where-Object { $_ } | Select-Object -First 1
  if ($candidates) {
    $MODEL = $candidates.FullName
  } else {
    Write-Host "ERRO: modelo IQ3_XXS nao encontrado." -ForegroundColor Red
    Write-Host "Coloque o GGUF em C:\Users\Administrator\Documents\AI ou C:\modelos" -ForegroundColor Yellow
    exit 1
  }
}

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listener) {
  Write-Host "ERRO: a porta $Port ja esta em uso (PID $($listener.OwningProcess))." -ForegroundColor Red
  Write-Host "Feche o outro servidor ou use: -Port 1235" -ForegroundColor Yellow
  exit 1
}

$gpu = (nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free --format=csv,noheader,nounits | Select-Object -First 1)
Write-Host "GPU: $gpu" -ForegroundColor Cyan
$free = [int](($gpu -split ",")[3].Trim())
if ($free -lt 14800) {
  Write-Host "ERRO: VRAM livre insuficiente ($free MiB). Esta config precisa de ~15.4 GB." -ForegroundColor Red
  Write-Host "Feche jogos / navegador / LM Studio e tente novamente." -ForegroundColor Yellow
  exit 1
}
if ($free -lt 15200) {
  Write-Host "AVISO: apenas $free MiB de VRAM livre. Esta config usa ~15.4 GB." -ForegroundColor Yellow
  Write-Host "Feche jogos / navegador / LM Studio para evitar OOM. Continuando em 8s..." -ForegroundColor Yellow
  Start-Sleep -Seconds 8
}

# Parametros do template Qwen3.8: thinking preservado e esforco medio
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'

Write-Host ""
Write-Host "Qwen3.8-27B IQ3_XXS 2.88bpw | ctx $Ctx | KV q4_0 | MTP n=3" -ForegroundColor Green
Write-Host "API/WebUI: http://$($LOCAL_URL):$Port (LAN: http://<seu-ip>:$Port)" -ForegroundColor Green
Write-Host "Modelo: $MODEL" -ForegroundColor DarkGray
Write-Host "Aguarde o carregamento (10-40s)..." -ForegroundColor DarkGray
Write-Host ""

& $LLAMA `
  -m $MODEL `
  --alias "qwen3.8-27b-iq3xxs" `
  --no-mmproj `
  --device CUDA0 `
  --spec-draft-device CUDA0 `
  --gpu-layers-draft all `
  --spec-type draft-mtp `
  --spec-draft-n-max 3 `
  --spec-draft-n-min 0 `
  --spec-draft-p-min 0 `
  --n-gpu-layers all `
  --threads 6 `
  --threads-batch 6 `
  --fit off `
  --load-mode mmap `
  --no-warmup `
  --flash-attn on `
  --ctx-size $Ctx `
  --parallel 1 `
  --cache-type-k q4_0 `
  --cache-type-v q4_0 `
  --batch-size 512 `
  --ubatch-size 512 `
  --ctx-checkpoints 32 `
  --jinja `
  --temp 1 `
  --top-p 0.95 `
  --top-k 20 `
  --min-p 0 `
  --reasoning auto `
  --reasoning-preserve `
  --reasoning-effort medium `
  --host $BIND_HOST `
  --port $Port

Write-Host ""
Write-Host "Servidor encerrado." -ForegroundColor Yellow

