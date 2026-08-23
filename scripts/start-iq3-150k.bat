@echo off
REM Start IQ3_XXS 150K Q4 - Extended Context (limit, 15.0GB / 16.3GB - recommended limit)
set LLAMA=C:\llamacpp\llama-server.exe
set MODEL=C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf
if not exist "%LLAMA%" echo llama-server not found at %LLAMA% && exit /b 1
if not exist "%MODEL%" echo Model not found at %MODEL% && exit /b 1
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}
echo Starting IQ3_XXS 150K Q4 on http://127.0.0.1:1234 - VRAM 15.0GB / 16.3GB (15323 MiB) - limit
"%LLAMA%" -m "%MODEL%" --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 150000 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 0.0.0.0 --port 1234 -lv 4
