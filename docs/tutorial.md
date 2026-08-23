# Tutorial — Qwen3.8-27B with MTP on RTX 5060 Ti 16.3 GB

Single-GPU inference of **Qwen3.8-27B** with native MTP. All numbers measured on real hardware.

## Environment

| Component | Version |
|---|---|
| GPU | ASUS RTX 5060 Ti PCIe 5.0 — 16311 MiB |
| Driver | 610.88 |
| CUDA | 13.3 (UMD) |
| OS | Windows 11 22H2, PowerShell 5.1 |
| llama.cpp | b10586 (`GGML_CUDA=1`) |
| Date | 2026-08-22 (revalidated 2026-08-22 systematic grid) |
| Placa-mãe | ASUS PRIME B350M (PCIe 3.0) |
| Method | MTP n=3, `flash-attn on`, `parallel 1`, `threads 6`, `batch 512`, `chat/completions 36 tok prompt / 70 tok gen`, `clear-vram` between cases |

> GPU ASUS PCIe 5.0 running at PCIe 3.0 x16 — bandwidth limited to ~15.75 GB/s. Results reflect this condition; PCIe 4.0/5.0 offers higher bandwidth.

## Models

| Quant | File | Size | Download |
|---|---|---|---|
| UD-IQ4_XS | `Qwen3.8-27B-UD-IQ4_XS.gguf` | 14.25 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf) |
| UD-IQ3_XXS | `Qwen3.8-27B-UD-IQ3_XXS.gguf` | 10.9 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf) |

Example: `C:\modelos` (outside repo, as used in tests).

## Methodology (academic)

Systematic grid at market numbers `32K/64K/100K/128K/148K` + `limit` + `collapse +5K/+10K`. Per case: `clear-vram` (kill `llama-server` + `nvidia-smi`), load with `--fit off --load-mode none --no-warmup`, poll `http://127.0.0.1:1234/health` up to 200s, capture `nvidia-smi memory.used` + `KV buffer size` from log (`CUDA0 KV ...` + draft), `POST /v1/chat/completions` with `messages=[user: "Explain quantum entanglement..."]`, `max_tokens=70`, capture `timings.prompt_per_second` and `predicted_per_second` + `draft_n/draft_n_accepted`. Collapse criterion: `prompt <15 t/s` or `gen <15 t/s` (quadratic attention). Raw logs at `C:\Temp\bench\bench_*.log(.err)` and CSV `bench-results-v2.csv`. All `start-*.ps1` reproduce exact flags.

## Results (revalidated — systematic grid)

Total VRAM: **16311 MiB**. Stable limit **~15.9 GB (97-98%)**.

### IQ4_XS — 14.25 GB

**Q8_0** — KV q8_0 (precision)

| Context | VRAM | % | Prompt | Gen | Draft | Reproduce |
|---|---|---|---|---|---|---|
| 32K | 15705 MiB | 96.3% | 92.73 t/s | 52.68 t/s | 72.3% | [`start-iq4-32k-q8.ps1`](../scripts/start-iq4-32k-q8.ps1) |
| **45K limit** | **15860 MiB** | **97.2%** | **94.85 t/s** | **45.55 t/s** | **76.2%** | [`start-iq4-45k-q8.ps1`](../scripts/start-iq4-45k-q8.ps1) |
| 50K | 15750 MiB | 96.6% | 27.86 t/s | 10.75 t/s | 55.8% | collapse beyond limit (`start-iq4-50k-q8.ps1`, 64K also collapses 25/9) |

**Q4_0** — KV q4_0 (context)

| Context | VRAM | % | Prompt | Gen | Reproduce |
|---|---|---|---|---|---|
| 32K | 15105 MiB | 92.6% | 110.37 t/s | 46.18 t/s | 60.3% | [`start-iq4-32k-q4.ps1`](../scripts/start-iq4-32k-q4.ps1) |
| 64K | 15865 MiB | 97.3% | 104.57 t/s | 41.82 t/s | 55.3% | [`start-iq4-64k-q4.ps1`](../scripts/start-iq4-64k-q4.ps1) |
| 80K | 15842 MiB | 97.1% | 107.90 t/s | 41.32 t/s | 60.3% | [`start-iq4-80k-q4.ps1`](../scripts/start-iq4-80k-q4.ps1) |
| **90K limit** | **15854 MiB** | **97.2%** | **107.26 t/s** | **46.28 t/s** | **72.3%** | [`start-iq4-90k-q4.ps1`](../scripts/start-iq4-90k-q4.ps1) |
| 100K | 15856 MiB | 97.2% | 23.07 t/s | 8.25 t/s | 77.4% | collapse (`start-iq4-100k-q4.ps1`) |

> Limit IQ4 Q4 moved 80K → 90K after systematic revalidation; Q8 stays 45K.

### IQ3_XXS — 10.9 GB

**Q4_0** — KV q4_0 (giant context, market)

| Context | VRAM | % | Prompt | Gen | Draft | Reproduce |
|---|---|---|---|---|---|---|
| 32K | 12060 MiB | 73.9% | 72.24 t/s | 57.45 t/s | 78.7% | [`start-iq3-32k-q4.ps1`](../scripts/start-iq3-32k-q4.ps1) |
| 64K | 12888 MiB | 79.0% | 76.00 t/s | 57.18 t/s | 76.2% | [`start-iq3-64k-q4.ps1`](../scripts/start-iq3-64k-q4.ps1) |
| 100K | 13882 MiB | 85.1% | 63.98 t/s | 44.37 t/s | 53.2% | [`start-iq3-100k-q4.ps1`](../scripts/start-iq3-100k-q4.ps1) |
| 128K | 14736 MiB | 90.3% | 80.25 t/s | 41.47 t/s | 49.4% | [`start-iq3-128k.ps1`](../scripts/start-iq3-128k.ps1) |
| 148K | 15206 MiB | 93.2% | 83.29 t/s | 50.06 t/s | 63.4% | [`start-iq3-148k-q4.ps1`](../scripts/start-iq3-148k-q4.ps1) |
| 150K | 15254 MiB | 93.5% | 80.68 t/s | 54.00 t/s | 72.3% | [`start-iq3-150k.ps1`](../scripts/start-iq3-150k.ps1) |
| **160K limit** | **15528 MiB** | **95.2%** | **85.99 t/s** | **57.05 t/s** | **76.2%** | [`start-iq3-160k-q4.ps1`](../scripts/start-iq3-160k-q4.ps1) |
| 170K | 15808 MiB | 96.9% | 5.76 t/s | 57.14 t/s | 80.0% | prompt collapse — quadratic attention (`start-iq3-170k-q4.ps1`, 250K max experimental) |

> Limit IQ3 Q4 moved 150K → 160K; 170K collapses prompt (gen still 57).

**Q8_0** — KV q8_0

| Context | VRAM | % | Prompt | Gen | Draft | Reproduce |
|---|---|---|---|---|---|---|
| 32K | 12590 MiB | 77.2% | 82.80 t/s | 46.67 t/s | 55.1% | [`start-iq3-32k-q8.ps1`](../scripts/start-iq3-32k-q8.ps1) |
| 64K | 13902 MiB | 85.2% | 87.33 t/s | 57.16 t/s | 77.4% | [`start-iq3-64k-q8.ps1`](../scripts/start-iq3-64k-q8.ps1) |
| **100K limit** | **15452 MiB** | **94.7%** | **84.24 t/s** | **57.44 t/s** | **80.0%** | [`start-iq3-100k-q8.ps1`](../scripts/start-iq3-100k-q8.ps1) |
| 110K | 15860 MiB | 97.2% | 5.72 t/s | 53.81 t/s | 74.6% | prompt collapse (`start-iq3-110k-q8.ps1`) |
| 120K | 15850 MiB | 97.2% | 5.76 t/s | 54.64 t/s | 83.1% | prompt collapse (`start-iq3-120k-q8.ps1`) |

> Limit IQ3 Q8 moved 110K → 100K after prompt <15 criterion; 110K/120K collapse prompt but gen stays ~54.

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

### 2. Install llama.cpp (b10586 is the commit of the validated release)

Create the folder:

```powershell
mkdir C:\llamacpp
```

Download from [releases — b10586](https://github.com/ggml-org/llama.cpp/releases/tag/b10586) (or `latest` at [releases](https://github.com/ggml-org/llama.cpp/releases)):
- `llama-b10586-bin-win-cuda-13.3-x64.zip`
- `cudart-llama-bin-win-cuda-13.3-x64.zip`

Extract **both** to `C:\llamacpp` (right-click > Extract All, or via PowerShell):

```powershell
Expand-Archive $HOME\Downloads\llama-b10586-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
Expand-Archive $HOME\Downloads\cudart-llama-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
dir C:\llamacpp\llama-server.exe, C:\llamacpp\cudart64_13.dll, C:\llamacpp\cublas64_13.dll
C:\llamacpp\llama-server.exe --version
```

Output must contain `GGML_CUDA=1`. If it shows `Vulkan`, the build is incorrect — replace with the CUDA 13.3 package.

### 3. Download models

```powershell
mkdir C:\modelos
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf
dir C:\modelos\*.gguf
```

### 4. Run

```powershell
.\run.ps1
.\scripts\clear-vram.ps1
```

Direct (examples — validated limits):

```powershell
.\scripts\start-iq4-45k-q8.ps1   # IQ4 45K Q8 limite (50K collapses)
.\scripts\start-iq4-90k-q4.ps1   # IQ4 90K Q4 limite (100K collapses)
.\scripts\start-iq3-160k-q4.ps1  # IQ3 160K Q4 limite (170K collapses prompt)
.\scripts\start-iq3-100k-q8.ps1  # IQ3 100K Q8 limite (110K collapses)
```

Other scripts follow the pattern `start-iq{quant}-{ctx}-{kv}.ps1` — market `32K/64K/100K/128K/148K` + `limit` + `collapse` (see `scripts/` and `tools/bench-results-v2.csv`).

Custom context and KV:

```powershell
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'
C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 45056 --parallel 1 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234
```

Change `--ctx-size` and `--cache-type-k/v` per tables above.

### 5. Use

Web UI: `http://127.0.0.1:1234`

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
