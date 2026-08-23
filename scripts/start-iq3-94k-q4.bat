@echo off
REM Start IQ3_XXS 94K Q4 - (13873 MiB 85.1%)
set LLAMA=C:\llamacpp\llama-server.exe
set MODEL=C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}
if not exist "%LLAMA%" echo ERROR: %LLAMA% not found && pause && exit /b 1
if not exist "%MODEL%" echo ERROR: %MODEL% not found && pause && exit /b 1
nvidia-smi
echo Starting IQ3_XXS 94K Q4 on http://127.0.0.1:1234 - VRAM 13873 MiB (85.1%) - 36.63/44.36 t/s
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 94208 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234 -lv 4
pause
