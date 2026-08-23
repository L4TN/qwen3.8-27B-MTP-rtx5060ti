# bench-grid-v2.ps1 — Scientific grid validation (academic)
# Metodologia: clear-vram, 1 run per ctx, health poll, capture nvidia-smi + KV + chat/completions timings (prompt_n, predicted_n)
$ErrorActionPreference="Continue"
$LLAMA="C:\llamacpp\llama-server.exe"
$LOGDIR="C:\Temp\bench"
$CSV="$LOGDIR\bench-results-v2.csv"
$PORT=1234
$HOSTADDR="127.0.0.1"
$TOTAL_VRAM=16311
if(-not (Test-Path $LOGDIR)){ New-Item -ItemType Directory -Path $LOGDIR -Force | Out-Null }
"quant,ctx,kv,model,memory_used_mib,memory_percent,kv_main_mib,kv_draft_mib,kv_total_mib,prompt_n,prompt_ms,prompt_tps,pred_n,pred_ms,gen_tps,draft_n,draft_accept,accept_rate,status,log_file" | Set-Content -LiteralPath $CSV -Encoding UTF8

$GRID=@(
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=32768; kv="q8_0"; label="IQ4 Q8 32K market safe"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=45056; kv="q8_0"; label="IQ4 Q8 45K limite"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=50000; kv="q8_0"; label="IQ4 Q8 50K colapso"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=64000; kv="q8_0"; label="IQ4 Q8 64K OOM"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=32768; kv="q4_0"; label="IQ4 Q4 32K market"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=64000; kv="q4_0"; label="IQ4 Q4 64K market"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=80000; kv="q4_0"; label="IQ4 Q4 80K limite"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=90000; kv="q4_0"; label="IQ4 Q4 90K colapso"},
 @{quant="IQ4_XS"; model="C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf"; ctx=100000; kv="q4_0"; label="IQ4 Q4 100K OOM"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=32768; kv="q4_0"; label="IQ3 Q4 32K baseline"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=64000; kv="q4_0"; label="IQ3 Q4 64K market"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=100000; kv="q4_0"; label="IQ3 Q4 100K market"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=131072; kv="q4_0"; label="IQ3 Q4 128K market"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=148000; kv="q4_0"; label="IQ3 Q4 148K market"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=150000; kv="q4_0"; label="IQ3 Q4 150K limite"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=160000; kv="q4_0"; label="IQ3 Q4 160K colapso"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=170000; kv="q4_0"; label="IQ3 Q4 170K colapso"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=32768; kv="q8_0"; label="IQ3 Q8 32K baseline"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=64000; kv="q8_0"; label="IQ3 Q8 64K market"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=100000; kv="q8_0"; label="IQ3 Q8 100K market"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=110000; kv="q8_0"; label="IQ3 Q8 110K limite"},
 @{quant="IQ3_XXS"; model="C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf"; ctx=120000; kv="q8_0"; label="IQ3 Q8 120K colapso"}
)

function Clear-VRAM {
 Get-Process llama-server -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
 Start-Sleep 3
 $v=0; try{ $v=[int]((nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits) -replace '\D','') }catch{}
 Write-Host "  VRAM after clear: $v MiB" -ForegroundColor DarkGray
 return $v
}
function Get-VRAM-Used {
 try{ return [int]((nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits).Trim()) }catch{ return -1 }
}
function Get-KV-Buffers($logFile){
 try{
   $txt = Get-Content -LiteralPath $logFile -Raw -ErrorAction SilentlyContinue
   $main=""; $draft=""
   # match "KV buffer size = 1088.00 MiB" first occurrence main, second draft
   $matches = [regex]::Matches($txt, "KV buffer size\s*=\s*([\d\.]+)\s*MiB")
   if($matches.Count -ge 1){ $main=$matches[0].Groups[1].Value }
   if($matches.Count -ge 2){ $draft=$matches[1].Groups[1].Value }
   $total=""
   if($main -ne "" -and $draft -ne ""){ $total=[math]::Round([double]$main+[double]$draft,2) }
   elseif($main -ne ""){ $total=$main }
   return @{main=$main; draft=$draft; total=$total}
 }catch{ return @{main="";draft="";total=""} }
}
function Wait-Health($timeoutSec=180){
 $deadline=(Get-Date).AddSeconds($timeoutSec)
 while((Get-Date) -lt $deadline){
   try{
     $r=Invoke-WebRequest -Uri "http://$HOSTADDR`:$PORT/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
     if($r.StatusCode -eq 200){ return $true }
   }catch{}
   $proc=Get-Process llama-server -ErrorAction SilentlyContinue
   if(-not $proc){ return $false }
   Start-Sleep 2
 }
 return $false
}

$caseNum=0
foreach($case in $GRID){
 $caseNum++
 $quant=$case.quant; $ctx=$case.ctx; $kv=$case.kv; $model=$case.model; $label=$case.label
 Write-Host ""
 Write-Host "[$caseNum/$($GRID.Count)] $label (ctx $ctx kv $kv)" -ForegroundColor Yellow
 $logFile = Join-Path $LOGDIR ("bench_{0}_{1}_{2}.log" -f ($quant -replace '_',''), $ctx, $kv)
 $logErr = "$logFile.err"
 if(Test-Path $logFile){ Remove-Item $logFile -Force -ErrorAction SilentlyContinue }
 if(Test-Path $logErr){ Remove-Item $logErr -Force -ErrorAction SilentlyContinue }
 Clear-VRAM | Out-Null
 if(-not (Test-Path $model)){
   Write-Host "  Model missing" -ForegroundColor Red
   "$quant,$ctx,$kv,$model,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,MODEL_MISSING,$logFile" | Add-Content -LiteralPath $CSV -Encoding UTF8
   continue
 }
 $argList=@("-m",$model,"--no-mmproj","--device","CUDA0","--spec-draft-device","CUDA0","--gpu-layers-draft","all","--spec-type","draft-mtp","--spec-draft-n-max","3","--n-gpu-layers","all","--threads","6","--fit","off","--load-mode","none","--no-warmup","--flash-attn","on","--ctx-size","$ctx","--parallel","1","--cache-type-k",$kv,"--cache-type-v",$kv,"--batch-size","512","--ubatch-size","512","--jinja","--temp","1","--top-p","0.95","--top-k","20","--reasoning","auto","--reasoning-preserve","--reasoning-effort","medium","--host",$HOSTADDR,"--port","$PORT","-lv","4")
 Write-Host "  Starting..." -ForegroundColor DarkGray
 try{
   $proc=Start-Process -FilePath $LLAMA -ArgumentList $argList -RedirectStandardOutput $logFile -RedirectStandardError $logErr -WindowStyle Hidden -PassThru
 }catch{
   Write-Host "  start failed $_" -ForegroundColor Red
   "$quant,$ctx,$kv,$model,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,START_FAIL,$logFile" | Add-Content -LiteralPath $CSV -Encoding UTF8
   continue
 }
 Start-Sleep 3
 $ready=Wait-Health -timeoutSec 200
 if(-not $ready){
   Write-Host "  NOT READY" -ForegroundColor Red
   $status="FAIL_START"
   $tail=""; if(Test-Path $logFile){ $tail=(Get-Content $logFile -Tail 100 | Out-String) } ; if(Test-Path $logErr){ $tail+=(Get-Content $logErr -Tail 100 | Out-String) }
   if($tail -match "OOM|out of memory|failed to allocate|exceeds|CUDA error"){ $status="OOM" }
   $vram=Get-VRAM-Used; $kvb=Get-KV-Buffers $logFile; $perc=if($vram -gt 0){[math]::Round($vram/$TOTAL_VRAM*100,1)}else{-1}
   "$quant,$ctx,$kv,$model,$vram,$perc,$($kvb.main),$($kvb.draft),$($kvb.total),-1,-1,-1,-1,-1,-1,-1,-1,-1,$status,$logFile" | Add-Content -LiteralPath $CSV -Encoding UTF8
   Get-Process llama-server -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
   Start-Sleep 4; Clear-VRAM | Out-Null
   continue
 }
 Write-Host "  READY" -ForegroundColor Green
 $vram=Get-VRAM-Used; $kvb=Get-KV-Buffers $logFile; $perc=[math]::Round($vram/$TOTAL_VRAM*100,1)
 Write-Host "  VRAM $vram MiB ($perc%) KV main $($kvb.main) draft $($kvb.draft) total $($kvb.total)" -ForegroundColor Cyan
 # Chat completion benchmark - prompt ~36 tok prompt (user) -> 70 gen
 $chatBody=@{
   model="Qwen3.8-27B"
   messages=@(@{role="user"; content="Explain quantum entanglement in simple terms for a high school student, include one analogy, in about 70 tokens."})
   max_tokens=70
   temperature=1
   top_p=0.95
   stream=$false
 } | ConvertTo-Json -Depth 5 -Compress
 $headers=@{"Content-Type"="application/json"}
 $resp=$null; $success=$false; $tries=0
 while($tries -lt 2 -and -not $success){
   try{
     $resp=Invoke-RestMethod -Uri "http://$HOSTADDR`:$PORT/v1/chat/completions" -Method Post -Headers $headers -Body $chatBody -TimeoutSec 120 -ErrorAction Stop
     $success=$true
   }catch{
     Write-Host "  chat error try $($tries+1): $_" -ForegroundColor Yellow
     $tries++
     Start-Sleep 2
   }
 }
 $prompt_n=-1; $prompt_ms=-1; $prompt_tps=-1; $pred_n=-1; $pred_ms=-1; $gen_tps=-1; $draft_n=-1; $draft_acc=-1; $acc_rate=-1; $status="COMPLETION_FAIL"
 if($success -and $resp.timings){
   $t=$resp.timings
   $prompt_n=$t.prompt_n; $prompt_ms=$t.prompt_ms; $pred_n=$t.predicted_n; $pred_ms=$t.predicted_ms
   $draft_n=$t.draft_n; $draft_acc=$t.draft_n_accepted
   if($prompt_ms -gt 0){ $prompt_tps=[math]::Round($prompt_n/($prompt_ms/1000),2) }
   if($pred_ms -gt 0){ $gen_tps=[math]::Round($pred_n/($pred_ms/1000),2) }
   if($draft_n -gt 0){ $acc_rate=[math]::Round($draft_acc/$draft_n*100,1) }
   Write-Host "  Prompt $prompt_n tok ${prompt_ms}ms => $prompt_tps t/s | Gen $pred_n tok ${pred_ms}ms => $gen_tps t/s | draft $draft_acc/$draft_n ($acc_rate%)" -ForegroundColor Green
   $status="OK"
   # colapso detection: prompt <15 t/s or gen <20 t/s considered degraded
   if($prompt_tps -gt 0 -and $prompt_tps -lt 10){ $status="COLLAPSE_PROMPT" }
   elseif($gen_tps -gt 0 -and $gen_tps -lt 20){ $status="COLLAPSE_GEN" }
 } else {
   Write-Host "  no timings" -ForegroundColor Red
   if($resp){ $resp | ConvertTo-Json -Depth 4 | Out-String -Width 3000 | Write-Host }
 }
 "$quant,$ctx,$kv,$model,$vram,$perc,$($kvb.main),$($kvb.draft),$($kvb.total),$prompt_n,$prompt_ms,$prompt_tps,$pred_n,$pred_ms,$gen_tps,$draft_n,$draft_acc,$acc_rate,$status,$logFile" | Add-Content -LiteralPath $CSV -Encoding UTF8
 Write-Host "  Stopping..." -ForegroundColor DarkGray
 Get-Process llama-server -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
 Start-Sleep 5; Clear-VRAM | Out-Null
}
Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Cyan
Get-Content $CSV | Out-String -Width 3000 | Write-Host
nvidia-smi | Out-String -Width 2000 | Write-Host
