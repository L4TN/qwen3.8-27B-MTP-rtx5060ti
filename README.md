# Qwen3.8-27B on RTX 5060 Ti — 50+ t/s Single-GPU with MTP

<p align="center">
  <img src="https://img.shields.io/badge/Windows%2011-0078D6?style=flat&logo=windows&logoColor=white" />
  <img src="https://img.shields.io/badge/CUDA%2013.3-76B900?style=flat&logo=nvidia&logoColor=white" />
  <img src="https://img.shields.io/badge/llama.cpp-b10586-000000?style=flat" />
  <img src="https://img.shields.io/badge/MTP-n=3-0A66C2?style=flat" />
  <img src="https://img.shields.io/badge/VRAM-16311_MiB-8A2BE2?style=flat" />
</p>

Single-GPU inference of **Qwen3.8-27B** with native MTP on **RTX 5060 Ti 16.3 GB**. **50+ t/s** validated on real hardware.

## Results

### Environment

| GPU | VRAM | Driver | CUDA | llama.cpp | OS | Date |
|---|---|---|---|---|---|---|
| RTX 5060 Ti | 16311 MiB | 610.88 | 13.3 | b10586 | Windows 11 | 2026-08-22 |

Method: MTP n=3, `24 tok prompt / 70 tok gen`, `flash-attn on`, `parallel 1`, `threads 6`.

### Measurements

| Model | Quant | KV | Context | VRAM | % | Prompt | Gen | Script |
|---|---|---|---|---|---|---|---|---|
| Qwen3.8-27B | IQ4_XS (14.25 GB) | Q8_0 | 32K | 15843 MiB | 97.1% | 44.81 t/s | 50.72 t/s | `start-iq4-32k` |
| Qwen3.8-27B | IQ4_XS (14.25 GB) | Q8_0 | **45K limit** | **15963 MiB** | **97.8%** | **52.36 t/s** | **46.14 t/s** | `start-iq4-45k` |
| Qwen3.8-27B | IQ3_XXS (10.9 GB) | Q4_0 | 128K | 15061 MiB | 92.3% | 41.35 t/s | 56.72 t/s | `start-iq3-128k` |
| Qwen3.8-27B | IQ3_XXS (10.9 GB) | Q4_0 | **150K limit** | **15323 MiB** | **92.1%** | **41.54 t/s** | **52.71 t/s** | `start-iq3-150k` |

* 45K Q8_0 and 150K Q4_0 are the maximum stable contexts at ~15.9 GB. Beyond: 170K Q4 → 2.9 t/s prompt (quadratic attention), 262K OOM, 90K Q4 → 28/10 t/s.
* MTP acceptance 0.68-0.76, mean 3.0-3.3.

### KV Cache vs Context

| Model | KV | Limit @ ~15.9 GB | VRAM | Prompt | Gen |
|---|---|---|---|---|---|
| IQ4_XS | Q8_0 | 45K | 15963 MiB | 52.36 t/s | 46.14 t/s |
| IQ4_XS | Q4_0 | 80K | 15844 MiB | 44.07 t/s | 43.85 t/s |
| IQ3_XXS | Q4_0 | 150K | 15323 MiB | 41.54 t/s | 52.71 t/s |
| IQ3_XXS | Q8_0 | 110K | 15908 MiB | 3.60 t/s | 44.05 t/s |

Q4_0 extends context +77% on IQ4 at same VRAM. Q8_0 at large context collapses prompt.

## Requirements

- NVIDIA GPU 16.3 GB (RTX 5060 Ti validated; 4080/4090 compatible)
- Driver >= 610.88 (CUDA 13.3) — `nvidia-smi`
- Windows 11, 20 GB disk, PowerShell 5.1

## Installation

1. Verify CUDA

```powershell
nvidia-smi
```

2. Download `llama.cpp`

Download `llama-b10586-bin-win-cuda-13.3-x64.zip` and `cudart-llama-bin-win-cuda-13.3-x64.zip` from [llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases). Extract both to `C:\llamacpp`.

3. Download model

```powershell
mkdir C:\modelos
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf
```

4. Run

```powershell
.\run.ps1
```

Or directly:

```powershell
.\scripts\start-iq4-32k.ps1
.\scripts\start-iq4-45k.ps1
.\scripts\start-iq3-128k.ps1
.\scripts\start-iq3-150k.ps1
```

5. Open `http://127.0.0.1:1234`

Switch models:

```powershell
.\scripts\clear-vram.ps1
```

## API

```powershell
$body = @{model="Qwen3.8-27B";messages=@(@{role="user";content="Hello"});stream=$false;max_tokens=800} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri http://127.0.0.1:1234/v1/chat/completions -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
```

## Structure

```
run.ps1 / run.bat
scripts/start-iq4-32k.ps1  # 32K Q8  15.5 GB
scripts/start-iq4-45k.ps1  # 45K Q8  15.9 GB limit
scripts/start-iq3-128k.ps1 # 128K Q4 14.7 GB
scripts/start-iq3-150k.ps1 # 150K Q4 15.0 GB limit
scripts/clear-vram.ps1
docs/tutorial.md
```

Models in `C:\modelos` (outside repo).

## References

- Model: [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF)
- Discussion #26: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26
- llama.cpp: https://github.com/ggml-org/llama.cpp
