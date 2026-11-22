@echo off
REM Qwen3.8-27B IQ3_XXS 2.88bpw (ByteShape) - 120K Q8 - MTP n=3 - RTX 5060 Ti 16GB
REM Modelo: https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf
REM Medido: 122880 ctx | 15474 MiB | prompt ~962 t/s (1.5K) | gen 51.2 t/s | draft 58.8%
REM Limites: 124K = 15657 MiB (~396 livres), 128K = 15769 MiB (~284 livres, ~48 t/s)
setlocal
set LLAMA=C:\llamacpp\llama-server.exe
set MODEL=C:\modelos\Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf
if not exist "%MODEL%" set MODEL=C:\Users\Administrator\Documents\AI\Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf
if not exist "%LLAMA%" echo llama-server not found at %LLAMA% && exit /b 1
if not exist "%MODEL%" echo Model not found - coloque o GGUF em C:\modelos && exit /b 1
set CTX=122880
if not "%~1"=="" set CTX=%~1
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
set LLAMA_ARG_CHAT_TEMPLATE_KWARGS={"preserve-thinking":true,"reasoning_effort":"medium"}
echo.
echo Qwen3.8-27B IQ3_XXS 2.88bpw ^| ctx %CTX% ^| KV q8_0 ^| MTP n=3
echo API/WebUI: http://127.0.0.1:1234
echo.
"%LLAMA%" -m "%MODEL%" --alias qwen3.8-27b-iq3xxs-q8 --no-mmproj --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-n-min 0 --spec-draft-p-min 0 --n-gpu-layers all --threads 6 --threads-batch 6 --fit off --load-mode mmap --no-warmup --flash-attn on --ctx-size %CTX% --parallel 1 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --ctx-checkpoints 32 --jinja --temp 1 --top-p 0.95 --top-k 20 --min-p 0 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 0.0.0.0 --port 1234
