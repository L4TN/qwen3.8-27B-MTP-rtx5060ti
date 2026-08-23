$ErrorActionPreference="Stop"
$scripts="C:\Users\Administrator\Documents\qwen3.8-27B-MTP-rtx5060ti\scripts"
function New-Start {
 param($fname,$quant,$ctx,$kv,$qname,$model,$label,$note)
 $psPath = Join-Path $scripts "$fname.ps1"
 $batPath = Join-Path $scripts "$fname.bat"
 $ps = @"
# Start $qname $ctx $kv - $label
`$ErrorActionPreference = "Stop"
`$LLAMA = "C:\llamacpp\llama-server.exe"
`$MODEL = "$model"
if (-not (Test-Path `$LLAMA)) { Write-Error "llama-server not found at `$LLAMA - install llama.cpp b10586 CUDA 13.3 to C:\llamacpp"; exit 1 }
if (-not (Test-Path `$MODEL)) { Write-Error "Model not found at `$MODEL - download $qname to C:\modelos"; exit 1 }
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
`$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS = '{"preserve-thinking":true,"reasoning_effort":"medium"}'
Write-Host "Starting $qname $ctx $kv - $label on http://127.0.0.1:1234" -ForegroundColor Green
Write-Host "Model: `$MODEL | ctx $ctx | KV $kv | MTP n=3 | threads 6 | $note" -ForegroundColor DarkGray
& `$LLAMA -m `$MODEL --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size $ctx --parallel 1 --cache-type-k $kv --cache-type-v $kv --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 0.0.0.0 --port 1234 -lv 4
"@
 $bat = @"
@echo off
set LLAMA=C:\llamacpp\llama-server.exe
set MODEL=$model
if not exist "%LLAMA%" echo llama-server not found && exit /b 1
if not exist "%MODEL%" echo Model not found && exit /b 1
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size $ctx --parallel 1 --cache-type-k $kv --cache-type-v $kv --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 0.0.0.0 --port 1234 -lv 4
"@
 Set-Content -LiteralPath $psPath -Value $ps -Encoding UTF8
 Set-Content -LiteralPath $batPath -Value $bat -Encoding ASCII
 Write-Host "Gen $fname $ctx $kv"
}
$iq4="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"
$iq3="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"
# IQ4 Q8
New-Start -fname "start-iq4-50k-q8" -quant iq4 -ctx 50000 -kv q8_0 -qname IQ4_XS -model $iq4 -label "colapso 50K" -note "beyond limite 45K - expect collapse"
New-Start -fname "start-iq4-64k-q8" -quant iq4 -ctx 64000 -kv q8_0 -qname IQ4_XS -model $iq4 -label "OOM 64K" -note "OOM expected"
# IQ4 Q4
New-Start -fname "start-iq4-64k-q4" -quant iq4 -ctx 64000 -kv q4_0 -qname IQ4_XS -model $iq4 -label "market 64K" -note "market 64K"
New-Start -fname "start-iq4-90k-q4" -quant iq4 -ctx 90000 -kv q4_0 -qname IQ4_XS -model $iq4 -label "colapso 90K" -note "collapse beyond 80K limite"
New-Start -fname "start-iq4-100k-q4" -quant iq4 -ctx 100000 -kv q4_0 -qname IQ4_XS -model $iq4 -label "OOM 100K" -note "OOM expected"
# IQ3 Q4
New-Start -fname "start-iq3-32k-q4" -quant iq3 -ctx 32768 -kv q4_0 -qname IQ3_XXS -model $iq3 -label "baseline 32K" -note "baseline vs IQ4"
New-Start -fname "start-iq3-64k-q4" -quant iq3 -ctx 64000 -kv q4_0 -qname IQ3_XXS -model $iq3 -label "market 64K" -note "market 64K"
New-Start -fname "start-iq3-100k-q4" -quant iq3 -ctx 100000 -kv q4_0 -qname IQ3_XXS -model $iq3 -label "market 100K" -note "market 100K"
New-Start -fname "start-iq3-148k-q4" -quant iq3 -ctx 148000 -kv q4_0 -qname IQ3_XXS -model $iq3 -label "market 148K" -note "market 148K near limite"
New-Start -fname "start-iq3-160k-q4" -quant iq3 -ctx 160000 -kv q4_0 -qname IQ3_XXS -model $iq3 -label "colapso 160K" -note "beyond limite"
New-Start -fname "start-iq3-170k-q4" -quant iq3 -ctx 170000 -kv q4_0 -qname IQ3_XXS -model $iq3 -label "colapso 170K" -note "quadratic attention collapse"
# IQ3 Q8
New-Start -fname "start-iq3-32k-q8" -quant iq3 -ctx 32768 -kv q8_0 -qname IQ3_XXS -model $iq3 -label "baseline 32K Q8" -note "baseline Q8"
New-Start -fname "start-iq3-64k-q8" -quant iq3 -ctx 64000 -kv q8_0 -qname IQ3_XXS -model $iq3 -label "market 64K Q8" -note "market 64K Q8"
New-Start -fname "start-iq3-100k-q8" -quant iq3 -ctx 100000 -kv q8_0 -qname IQ3_XXS -model $iq3 -label "market 100K Q8" -note "market 100K Q8"
New-Start -fname "start-iq3-110k-q8" -quant iq3 -ctx 110000 -kv q8_0 -qname IQ3_XXS -model $iq3 -label "limite 110K Q8" -note "limite IQ3 Q8"
New-Start -fname "start-iq3-120k-q8" -quant iq3 -ctx 120000 -kv q8_0 -qname IQ3_XXS -model $iq3 -label "colapso 120K Q8" -note "collapse Q8"
