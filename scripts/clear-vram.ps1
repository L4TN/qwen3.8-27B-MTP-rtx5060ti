# Clear VRAM - kills llama-server and frees GPU memory
$ErrorActionPreference = "SilentlyContinue"
Write-Host "Checking GPU before..." -ForegroundColor Cyan
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader | ForEach-Object { Write-Host "  $_" }

$procs = Get-Process llama-server -ErrorAction SilentlyContinue
if ($procs) {
    Write-Host "Found $($procs.Count) llama-server process(es) - killing..." -ForegroundColor Yellow
    $procs | Stop-Process -Force
    Start-Sleep 3
    Write-Host "Killed." -ForegroundColor Green
} else {
    Write-Host "No llama-server running." -ForegroundColor Green
}

# Also check any other GPU processes via nvidia-smi
Write-Host "GPU after:" -ForegroundColor Cyan
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader | ForEach-Object { Write-Host "  $_" }
nvidia-smi 2>$null | Out-String -Width 800 | Write-Host

Write-Host "VRAM cleared. You can now start another model." -ForegroundColor Green
