@echo off
REM ============================================================================
REM  Inkling-2-Mini UD-IQ3_XXS  -  stack Unsloth (b12651-mix-c7059d6) + DSpark
REM  GGUF da RAIZ do repo (NAO usar Mainline_Support/: layout incompativel)
REM  Alvo: RTX 5060 Ti 16 GB  |  ctx 102400 (100k)  |  DSpark n-max 2
REM  Uso: start-inkling2-mini-ud-iq3xxs-100k-q8.bat [ctx] [ctk] [ctv] [ubatch] [nmax]
REM       defaults: 102400  f16  q8_0  128  2
REM  Escada de KV testada: f16/f16 (344 MiB livres) -> f16/q8_0 (aprovada)
REM ============================================================================
setlocal

set LLAMA=C:\llamacpp-unsloth\llama-server.exe
set MODEL_DIR=C:\modelos
set MODEL=%MODEL_DIR%\Inkling-2-Mini-UD-IQ3_XXS-unsloth.gguf
set DRAFT=%MODEL_DIR%\dspark-Inkling-2-Mini-Q8_0-unsloth.gguf

set MODEL_URL=https://huggingface.co/unsloth/Inkling-2-Mini-GGUF/resolve/main/Inkling-2-Mini-UD-IQ3_XXS.gguf
set DRAFT_URL=https://huggingface.co/unsloth/Inkling-2-Mini-GGUF/resolve/main/dspark-Inkling-2-Mini-Q8_0.gguf

set CTX=102400
set CTK=f16
set CTV=q8_0
set UBATCH=128
set NMAX=2
if not "%~1"=="" set CTX=%~1
if not "%~2"=="" set CTK=%~2
if not "%~3"=="" set CTV=%~3
if not "%~4"=="" set UBATCH=%~4
if not "%~5"=="" set NMAX=%~5

if not exist "%LLAMA%" (
    echo [ERRO] llama-server.exe nao encontrado em %LLAMA%
    echo [ERRO] Baixe a build Unsloth b12651-mix-c7059d6 windows-x64-cuda13-portable.zip
    echo [ERRO] e as DLLs cudart64_13 / cublas64_13 / cublasLt64_13 ao lado do exe.
    exit /b 1
)

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

if not exist "%MODEL%" (
    echo [INFO] Modelo nao encontrado em %MODEL%
    echo [INFO] Baixando Inkling-2-Mini-UD-IQ3_XXS.gguf da raiz do repo Unsloth...
    curl.exe -L -C - --retry 10 --retry-delay 5 --fail --progress-bar "%MODEL_URL%" -o "%MODEL%.part"
    if errorlevel 1 (
        echo [ERRO] Falha ao baixar o modelo.
        exit /b 1
    )
    move /y "%MODEL%.part" "%MODEL%" >nul
)

if not exist "%DRAFT%" (
    echo [INFO] Drafter nao encontrado em %DRAFT%
    echo [INFO] Baixando dspark-Inkling-2-Mini-Q8_0.gguf da raiz do repo Unsloth...
    curl.exe -L -C - --retry 10 --retry-delay 5 --fail --progress-bar "%DRAFT_URL%" -o "%DRAFT%.part"
    if errorlevel 1 (
        echo [ERRO] Falha ao baixar o drafter DSpark.
        exit /b 1
    )
    move /y "%DRAFT%.part" "%DRAFT%" >nul
)

nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader

echo.
echo Inkling-2-Mini UD-IQ3_XXS ^(Unsloth b12651-mix-c7059d6^) ^| ctx %CTX% ^| KV %CTK%/%CTV% ^| ubatch %UBATCH% ^| DSpark n=%NMAX%
echo API/WebUI: http://127.0.0.1:1234 ^(LAN: http://^<seu-ip^>:1234^)
echo.

REM Sem --spec-draft-device: o drafter DSpark compartilha embeddings/LM head do alvo
"%LLAMA%" ^
  -m "%MODEL%" ^
  -md "%DRAFT%" ^
  --alias inkling-2-mini-ud-iq3xxs-100k ^
  --spec-type draft-dspark ^
  --spec-draft-n-max %NMAX% ^
  --spec-draft-n-min 0 ^
  --spec-draft-p-min 0 ^
  --device CUDA0 ^
  --n-gpu-layers all ^
  --gpu-layers-draft all ^
  --ctx-size %CTX% ^
  --parallel 1 ^
  --cache-type-k %CTK% ^
  --cache-type-v %CTV% ^
  --batch-size 512 ^
  --ubatch-size %UBATCH% ^
  --threads 6 ^
  --threads-batch 6 ^
  --fit off ^
  --load-mode mmap ^
  --no-mmproj ^
  --no-warmup ^
  --flash-attn on ^
  --ctx-checkpoints 32 ^
  --jinja ^
  --temp 1.0 ^
  --top-p 1.0 ^
  --top-k 0 ^
  --min-p 0 ^
  --reasoning auto ^
  --reasoning-preserve ^
  --reasoning-effort medium ^
  --host 0.0.0.0 ^
  --port 1234
