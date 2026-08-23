# Generator for standardized grid scripts
$ErrorActionPreference="Stop"
$repo="C:\Users\Administrator\Documents\qwen3.8-27B-MTP-rtx5060ti"
$scripts="$repo\scripts"

function New-StartScript {
  param($quant,$ctx,$kv,$label,$note)
  $model = if($quant -eq "iq4") { "C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf" } else { "C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf" }
  $qname = if($quant -eq "iq4") { "IQ4_XS" } else { "IQ3_XXS" }
  $ctxK = [math]::Round($ctx/1024)
  $fname = "start-$quant-${ctxK}k-$kv"
  # special case for existing 128k 131072
  if($ctx -eq 131072) { $fname = "start-iq3-128k" }
  $psPath = Join-Path $scripts "$fname.ps1"
  $batPath = Join-Path $scripts "$fname.bat"
  $psContent = @"
# Start $qname ${ctxK}K $kv - $label
`$ErrorActionPreference = "Stop"
`$LLAMA = "C:\llamacpp\llama-server.exe"
`$MODEL = "$model"
if (-not (Test-Path `$LLAMA)) { Write-Error "llama-server not found at `$LLAMA - install llama.cpp b10586 CUDA 13.3 to C:\llamacpp"; exit 1 }
if (-not (Test-Path `$MODEL)) { Write-Error "Model not found at `$MODEL - download $qname to C:\modelos"; exit 1 }
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
`$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'
Write-Host "Starting $qname ${ctx} $kv - $label on http://127.0.0.1:1234" -ForegroundColor Green
Write-Host "Model: `$MODEL | ctx $ctx | KV $kv | MTP n=3 | threads 6 | $note" -ForegroundColor DarkGray
& `$LLAMA -m `$MODEL --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size $ctx --parallel 1 --cache-type-k $kv --cache-type-v $kv --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 0.0.0.0 --port 1234 -lv 4
"@
  $batContent = @"
@echo off
set LLAMA=C:\llamacpp\llama-server.exe
set MODEL=$model
if not exist "%LLAMA%" echo llama-server not found at %LLAMA% && exit /b 1
if not exist "%MODEL%" echo Model not found at %MODEL% && exit /b 1
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size $ctx --parallel 1 --cache-type-k $kv --cache-type-v $kv --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 0.0.0.0 --port 1234 -lv 4
"@
  Set-Content -LiteralPath $psPath -Value $psContent -Encoding UTF8
  Set-Content -LiteralPath $batPath -Value $batContent -Encoding ASCII
  Write-Host "Generated $fname"
}

# Grid padrao academico
# IQ4 Q8: 32K, 45K limite, 50K colapso
New-StartScript -quant iq4 -ctx 32768 -kv q8_0 -label "market 32K safe" -note "market standard"
New-StartScript -quant iq4 -ctx 45056 -kv q8_0 -label "limite 45K" -note "limite IQ4 Q8"
New-StartScript -quant iq4 -ctx 50000 -kv q8_0 -label "colapso 50K" -note "beyond limite - expect collapse/OOM"
New-StartScript -quant iq4 -ctx 64000 -kv q8_0 -label "OOM 64K" -note "beyond - OOM expected"
# IQ4 Q4: 32K, 64K, 80K limite, 90K colapso, 100K OOM
New-StartScript -quant iq4 -ctx 32768 -kv q4_0 -label "market 32K" -note "market standard"
New-StartScript -quant iq4 -ctx 64000 -kv q4_0 -label "market 64K" -note "market 64K"
New-StartScript -quant iq4 -ctx 80000 -kv q4_0 -label "limite 80K" -note "limite IQ4 Q4"
New-StartScript -quant iq4 -ctx 90000 -kv q4_0 -label "colapso 90K" -note "collapse beyond limite"
New-StartScript -quant iq4 -ctx 100000 -kv q4_0 -label "OOM 100K" -note "OOM expected - shows why IQ3 needed"
# IQ3 Q4: 32K baseline, 64K, 100K, 128K, 148K market, 150K limite, 160K/170K collapse, 250K max
New-StartScript -quant iq3 -ctx 32768 -kv q4_0 -label "baseline 32K" -note "baseline compare vs IQ4"
New-StartScript -quant iq3 -ctx 64000 -kv q4_0 -label "market 64K" -note "market 64K"
New-StartScript -quant iq3 -ctx 100000 -kv q4_0 -label "market 100K" -note "market 100K"
New-StartScript -quant iq3 -ctx 131072 -kv q4_0 -label "market 128K" -note "market 128K safe"
New-StartScript -quant iq3 -ctx 148000 -kv q4_0 -label "market 148K" -note "market 148K"
New-StartScript -quant iq3 -ctx 150000 -kv q4_0 -label "limite 150K" -note "limite IQ3 Q4"
New-StartScript -quant iq3 -ctx 160000 -kv q4_0 -label "colapso 160K" -note "beyond limite 5K steps"
New-StartScript -quant iq3 -ctx 170000 -kv q4_0 -label "colapso 170K" -note "attention quadratic collapse"
# IQ3 Q8: 64K, 100K, 110K limite, 120K collapse (plus 32K baseline)
New-StartScript -quant iq3 -ctx 32768 -kv q8_0 -label "baseline 32K Q8" -note "baseline Q8"
New-StartScript -quant iq3 -ctx 64000 -kv q8_0 -label "market 64K Q8" -note "market 64K Q8"
New-StartScript -quant iq3 -ctx 100000 -kv q8_0 -label "market 100K Q8" -note "market 100K Q8"
New-StartScript -quant iq3 -ctx 110000 -kv q8_0 -label "limite 110K Q8" -note "limite IQ3 Q8"
New-StartScript -quant iq3 -ctx 120000 -kv q8_0 -label "colapso 120K Q8" -note "collapse Q8"

Write-Host "Done"
