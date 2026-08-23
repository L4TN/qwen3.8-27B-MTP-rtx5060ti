# Tutorial — Qwen3.8-27B with MTP on RTX 5060 Ti 16.3 GB

Single-GPU inference of **Qwen3.8-27B** with native MTP. All numbers measured on real hardware.

## Environment

| Component | Version |
|---|---|
| GPU | RTX 5060 Ti 16311 MiB |
| Driver | 610.88 |
| CUDA | 13.3 (UMD) |
| OS | Windows 11 22H2, PowerShell 5.1 |
| llama.cpp | b10586 (`GGML_CUDA=1`) |
| Date | 2026-08-22 |
| Method | MTP n=3, `flash-attn on`, `parallel 1`, `threads 6`, `batch 512`, `24 tok prompt / 70 tok gen` |

## Models

| Quant | File | Size | Download |
|---|---|---|---|
| UD-IQ4_XS | `Qwen3.8-27B-UD-IQ4_XS.gguf` | 14.25 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf) |
| UD-IQ3_XXS | `Qwen3.8-27B-UD-IQ3_XXS.gguf` | 10.9 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf) |

Stored in `C:\modelos` (outside repo).

## Results

Total VRAM: **16311 MiB**. Limit target **~15.9 GB (97-98%)**.

### IQ4_XS — 14.25 GB

**Q8_0 — qualidade máxima**

| Context | VRAM | % | Prompt | Gen | Reproduce |
|---|---|---|---|---|---|
| 32K | 15843 MiB | 97.1% | 44.81 t/s | 50.72 t/s | [`start-iq4-32k.ps1`](../scripts/start-iq4-32k.ps1) |
| **45K limit** | **15963 MiB** | **97.8%** | **52.36 t/s** | **46.14 t/s** | [`start-iq4-45k.ps1`](../scripts/start-iq4-45k.ps1) |

**Q4_0 — mais contexto, mesma VRAM**

| Context | VRAM | % | Prompt | Gen | Reproduce |
|---|---|---|---|---|---|
| 32K | 15347 MiB | 94.1% | 60.60 t/s | 48.94 t/s | [`start-iq4-32k-q4.ps1`](../scripts/start-iq4-32k-q4.ps1) |
| 45K | 15585 MiB | 95.5% | 53.45 t/s | 48.32 t/s | [`start-iq4-45k-q4.ps1`](../scripts/start-iq4-45k-q4.ps1) |
| 60K | 15891 MiB | 97.4% | 50.87 t/s | 42.67 t/s | [`start-iq4-60k-q4.ps1`](../scripts/start-iq4-60k-q4.ps1) |
| 70K | 15851 MiB | 97.2% | 54.66 t/s | 43.54 t/s | [`start-iq4-70k-q4.ps1`](../scripts/start-iq4-70k-q4.ps1) |
| **80K limit** | **15844 MiB** | **97.1%** | **44.07 t/s** | **43.85 t/s** | [`start-iq4-80k-q4.ps1`](../scripts/start-iq4-80k-q4.ps1) |
| 90K | 15914 MiB | 97.6% | 28.10 t/s | 10.27 t/s | collapse beyond limit |

Q8_0 max 45K. Q4_0 extends to 80K (+77% context at same VRAM).

### IQ3_XXS — 10.9 GB

**Q4_0 — capacidade máxima**

| Context | VRAM | % | Prompt | Gen | Reproduce |
|---|---|---|---|---|---|
| 94K | 13873 MiB | 85.1% | 36.63 t/s | 44.36 t/s | `--ctx-size 94208` |
| 110K | 14308 MiB | 87.7% | 34.14 t/s | 45.07 t/s | `--ctx-size 110000` |
| 128K | 15061 MiB | 92.3% | 41.35 t/s | 56.72 t/s | [`start-iq3-128k.ps1`](../scripts/start-iq3-128k.ps1) |
| 130K | 14775 MiB | 90.6% | 41.04 t/s | 54.47 t/s | `--ctx-size 130000` |
| **150K limit** | **15323 MiB** | **93.9%** | **41.54 t/s** | **52.71 t/s** | [`start-iq3-150k.ps1`](../scripts/start-iq3-150k.ps1) |
| 170K | 15872 MiB | 97.3% | 2.84 t/s | 44.95 t/s | collapse — attention quadratic |
| 250K | 15911 MiB | 97.5% | — | — | max fits; 262K OOM |

**Q8_0 — para comparação**

| Context | VRAM | % | Prompt | Gen | Reproduce |
|---|---|---|---|---|---|
| **110K limit** | **15908 MiB** | **97.5%** | **3.60 t/s** | **44.05 t/s** | `--ctx-size 110000 --cache-type-k q8_0 --cache-type-v q8_0` |

Q8_0 at large context is counter-productive: 150K Q4 → 110K Q8 (-27%) and 10x prompt collapse.

## Requirements

- NVIDIA GPU 16.3 GB (RTX 5060 Ti validated; 4080/4090 compatible)
- Driver >= 610.88 (CUDA 13.3) — `nvidia-smi`
- 20 GB disk, PowerShell 5.1

## Installation

### 1. Verify CUDA

```powershell
nvidia-smi
```

Expected: `610.88` and `CUDA UMD Version: 13.3` and `16311 MiB`.

### 2. Download llama.cpp

Download `llama-b10586-bin-win-cuda-13.3-x64.zip` and `cudart-llama-bin-win-cuda-13.3-x64.zip` from [llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases). Extract both to `C:\llamacpp`.

```powershell
Expand-Archive llama-b10586-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
Expand-Archive cudart-llama-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
.\llama-server.exe --version
```

Must show `GGML_CUDA=1`. If `Vulkan`, wrong ZIP.

### 3. Download models

```powershell
mkdir C:\modelos
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf
```

### 4. Run

```powershell
.\run.ps1
.\scripts\clear-vram.ps1
```

Direct:

```powershell
.\scripts\start-iq4-32k.ps1      # Q8  32K
.\scripts\start-iq4-45k.ps1      # Q8  45K limit
.\scripts\start-iq4-32k-q4.ps1   # Q4  32K
.\scripts\start-iq4-45k-q4.ps1   # Q4  45K
.\scripts\start-iq4-60k-q4.ps1   # Q4  60K
.\scripts\start-iq4-70k-q4.ps1   # Q4  70K
.\scripts\start-iq4-80k-q4.ps1   # Q4  80K limit
.\scripts\start-iq3-128k.ps1     # Q4 128K
.\scripts\start-iq3-150k.ps1     # Q4 150K limit
```

Custom context and KV:

```powershell
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'
C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 45056 --parallel 1 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234
```

Change `--ctx-size` and `--cache-type-k/v` per tables above.

### 5. Use

Web UI: `http://127.0.0.1:1234`

API:

```powershell
$body = @{model="Qwen3.8-27B";messages=@(@{role="user";content="Explain MTP in two sentences."});stream=$false;max_tokens=800} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri http://127.0.0.1:1234/v1/chat/completions -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
```

Stop:

```powershell
Get-Process llama-server | Stop-Process -Force
```

## Notes

- `parallel=1` and `--fit off` required to reach limit without VRAM sharing or auto-reduction.
- `reasoning_effort medium` — `xhigh` needs `max_tokens >= 6000` or responses appear empty.
- MTP is native to the GGUF (`nextn_predict_layers=1`), no separate draft model.

## References

- Model: [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF)
- IQ4_XS file: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-UD-IQ4_XS.gguf
- IQ3_XXS file: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-UD-IQ3_XXS.gguf
- All quants: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/tree/main
- llama.cpp: https://github.com/ggml-org/llama.cpp
- Discussion #26: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26 — hfmiguel, Hackin085, Bellatorius01
