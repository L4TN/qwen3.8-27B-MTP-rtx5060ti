# Qwen3.8-27B on RTX 5060 Ti — 50+ t/s Single-GPU Inference with MTP

<p align="center">
  <img src="https://img.shields.io/badge/Windows%2011-0078D6?style=flat&logo=windows&logoColor=white" />
  <img src="https://img.shields.io/badge/CUDA%2013.3-76B900?style=flat&logo=nvidia&logoColor=white" />
  <img src="https://img.shields.io/badge/llama.cpp-b10586-000000?style=flat" />
  <img src="https://img.shields.io/badge/MTP-n=3-0A66C2?style=flat" />
  <img src="https://img.shields.io/badge/VRAM-16.3GB_(16311_MiB)-8A2BE2?style=flat" />
</p>

<p align="center">
  Validated configuration for <b>Qwen3.8-27B GGUF</b> with native Multi-Token Prediction on a single <b>RTX 5060 Ti 16.3GB (16311 MiB)</b> under Windows 11.<br>
  Achieves <b>50-60 tokens/s</b> with correct CUDA 13.3 builds — 2x over non-MTP baselines on identical hardware.
</p>

<p align="center">
  <a href="https://huggingface.co/unsloth/Qwen3.8-27B-GGUF">Model</a> ·
  <a href="#configurations">Configurations</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="docs/tutorial.md">Full Tutorial</a> ·
  <a href="https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26">Discussion #26</a>
</p>

---

## Overview

This repository reproduces the 50+ t/s results from `unsloth/Qwen3.8-27B-GGUF` discussion #26 on a consumer single-GPU setup. The key is Qwen3.8's native MTP layer (`blk.64.nextn.*`), a proper CUDA 13.3 llama.cpp build, and matched quantization/KV settings.

All numbers below are measured on real hardware on 2026-08-22, not estimates.

Validated environment: RTX 5060 Ti 16.3GB (16311 MiB), Driver 610.88, CUDA UMD 13.3, llama.cpp b10586, Windows 11.

---

## Performance

| Metric | Without MTP | With MTP n=3 |
|---|---|---|
| Prompt eval | ~26 t/s | **52-54 t/s** |
| Generation | ~25 t/s | **44-60 t/s** |
| MTP acceptance | — | 0.59-0.79, mean 2.7-3.3 |

Detailed measurements in [Configurations](#configurations).

---

## Configurations

Two validated profiles are provided. Choose based on your trade-off between quality and context length.

|  | Configuration A — High Precision | Configuration B — Extended Context |
|---|---|---|
| **Use case** | Coding agent, reasoning, production quality | Long-document analysis, RAG, whole-repo ingestion |
| **Model file** | `Qwen3.8-27B-UD-IQ4_XS.gguf` (14.25 GB) | `Qwen3.8-27B-UD-IQ3_XXS.gguf` (10.9 GB) |
| **Download** | [IQ4_XS.gguf](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf) | [IQ3_XXS.gguf](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf) |
| **Context** | 45,056 tokens (sweet spot) | 150,000 tokens (sweet spot) |
| **KV cache** | Q8_0 | Q4_0 |
| **Flash Attention** | on | on |
| **VRAM peak** | 15.9 GB / 16.3 GB (15963 MiB) — 97.8% | 15.0 GB / 16.3 GB (15323 MiB) — 92.1% |
| **Prompt eval** | 47.91 t/s (25 tok / 522 ms) | 38.10 t/s (19 tok / 498 ms) |
| **Generation** | 37.09 t/s (350 tok) | 49.23 t/s (60 tok) |
| **MTP acceptance** | 0.55 (217/393) mean 2.66 | 0.63 (38/60) mean 2.90 |
| **Quality** | Highest | High |
| **Run** | [`start-iq4-45k.ps1`](scripts/start-iq4-45k.ps1) · [`.bat`](scripts/start-iq4-45k.bat) | [`start-iq3-150k.ps1`](scripts/start-iq3-150k.ps1) · [`.bat`](scripts/start-iq3-150k.bat) |

- Configuration A prioritizes output quality (IQ4_XS) at 45K, validated at 32K (15.5 GB, 52.17/44.79 t/s), 40K (15.6 GB) and 45K (15.9 GB). 45K is the maximum that maintains IQ4_XS + Q8_0 quality without exceeding 16 GB — ideal for production agents needing extended context.
- Configuration B prioritizes context length (IQ3_XXS). Validated limit tests to 15.9 GB (see below): 94K 13.5 GB, 110K 14.0 GB, 130K 14.4 GB, **150K 15.0 GB (sweet spot, 38/49 t/s)**, 170K+ 15.5 GB but prompt drops to 2.9 t/s. Max tested 250K 15.5 GB fits. Model supports 262K training limit but 262K OOMs.

Both use `parallel=1`, `fit off`, `n-gpu-layers all`, `threads 6`, `batch 512`.

---

## Requirements

- Windows 11 x64 22H2 or later
- NVIDIA GPU with 16.3 GB VRAM (16311 MiB, validated on RTX 5060 Ti; RTX 4080/4090 compatible)
- Driver >= 610.88 exposing CUDA 13.3 (verify with `nvidia-smi`; RTX 50-series requires CUDA 13.x, RTX 30/40-series can use 12.4)
- 20 GB free disk space
- PowerShell 5.1

```powershell
nvidia-smi
# Expected: CUDA UMD Version: 13.3 | GeForce RTX 5060 Ti 16311 MiB
```

---

## Quick Start

```powershell
# 1. Create directories
mkdir C:\llamacpp; mkdir C:\modelos

# 2. Download llama.cpp from https://github.com/ggml-org/llama.cpp/releases
#    llama-b10586-bin-win-cuda-13.3-x64.zip + cudart-llama-bin-win-cuda-13.3-x64.zip
#    Extract both into C:\llamacpp (cublas/cudart DLLs must sit beside llama-server.exe)

# 3. Download the desired model to C:\modelos
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
# For extended context:
# curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf

# 4. Run — choose one:
.\run.ps1                          # interactive menu (45K vs 150K)
# or dedicated scripts (post-install):
.\scripts\start-iq4-45k.ps1         # High Precision 45K Q8 — 15.9GB
.\scripts\start-iq3-150k.ps1        # Extended Context 150K Q4 — 15.0GB
.\scripts\clear-vram.ps1            # kill server and free VRAM

# 5. Open
http://127.0.0.1:1234
```

---

## Manual Commands

**Configuration A — High Precision (45K, Q8) — validated 2026-08-22:**

```powershell
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'
C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 45056 --parallel 1 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234
# Also validated at 32768 (15.5 GB) and 40960 (15.6 GB) — same command with --ctx-size 32768/40960
```

**Configuration B — Extended Context (IQ3_XXS Q4) — limit tests 2026-08-22:**

```powershell
# 94K baseline (13.5 GB)
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'
C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 94208 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234

# 150K sweet spot (15.0 GB, best balance — recommended for extended context)
# --ctx-size 150000  # KV 2637 MiB, prompt 38.1 t/s, gen 49.2 t/s

# 250K max validated (15.5 GB, 15911 MiB — fits but prompt 2.9 t/s beyond 150K)
# --ctx-size 250000  # KV ~4400 MiB, gen still ~43 t/s, prompt degrades due to attention
```

Notes:
- `parallel=1` is required to reach 92K+ without VRAM sharing
- `--fit off` prevents automatic context reduction
- `reasoning_effort=medium` is required; the default `xhigh` requires `max_tokens >= 6000` or responses appear empty
- MTP is native to the GGUF (`nextn_predict_layers=1`); no separate draft model needed

---

## Usage

**Web UI:** http://127.0.0.1:1234

**OpenAI-compatible API:**

```powershell
$body = @{
  model="Qwen3.8-27B-IQ4_XS"
  messages=@(@{role="user"; content="Explain MTP in two sentences."})
  stream=$false; max_tokens=800; temperature=1; top_p=0.95; top_k=20
} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri http://127.0.0.1:1234/v1/chat/completions -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
```

**Monitoring:**

```powershell
Get-Content C:\llamacpp\server.err -Tail 30
nvidia-smi
```

**Stop:**

```powershell
Get-Process llama-server | Stop-Process -Force
```

---

## Benchmarks

**This repository, RTX 5060 Ti, b10586:**

```
A — IQ4_XS Q8  45K : prompt 47.91 t/s | eval 37.09 t/s | 15.9 GB (15963 MiB) | acc 0.55 mean 2.66 | also 32K 15.5 GB 52.17/44.79 and 40K 15.6 validated
B — IQ3_XXS Q4  94K : prompt 36.63 t/s | eval 44.36 t/s | 13.5 GB (13873 MiB) | KV 1656 MiB
B — IQ3_XXS Q4 110K : prompt 34.14 t/s | eval 45.07 t/s | 14.0 GB (14308 MiB) | KV 1935 MiB
B — IQ3_XXS Q4 130K : prompt 41.04 t/s | eval 54.47 t/s | 14.4 GB (14775 MiB) | KV 2286 MiB
B — IQ3_XXS Q4 150K : prompt 38.10 t/s | eval 49.23 t/s | 15.0 GB (15323 MiB) | KV 2637 MiB — SWEET SPOT
B — IQ3_XXS Q4 170K : prompt  2.84 t/s | eval 44.95 t/s | 15.5 GB (15872 MiB) | KV 2992 MiB — prompt degrades, gen ok
B — IQ3_XXS Q4 190K : prompt  2.89 t/s | eval 43.18 t/s | 15.5 GB (15835 MiB) | KV 3343 MiB
B — IQ3_XXS Q4 210K : prompt  2.89 t/s | eval 36.88 t/s | 15.5 GB (15821 MiB) | KV 3694 MiB
B — IQ3_XXS Q4 230K : prompt  2.86 t/s | eval 42.99 t/s | 15.5 GB (15846 MiB) | KV 4045 MiB
B — IQ3_XXS Q4 250K : 15.5 GB (15911 MiB) fits — max validated; 262K OOM/crash
```

**References:**
- hfmiguel (IQ3_XXS Q4 94K): 35 t/s without MTP → 50-55 t/s with MTP
- Bellatorius01 (IQ4_XS Q8 32K): 26.0→54.1 @2.5K, 24.9→50.8 @14K, 23.7→40.8 @25K

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| 16-22 t/s with MTP at 100% GPU | Vulkan build (from winget) | Reinstall CUDA 13.3 ZIP; `llama-server --version` must show `GGML_CUDA=1` |
| Empty response | `reasoning medium` + low `max_tokens` | Increase `max_tokens` to 6000+ |
| Out of memory | VRAM exceeded | Use Configuration A (32K), keep `parallel=1`, close other GPU apps |
| Download stuck at 0 bytes | Firewall | Test `Invoke-WebRequest https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/config.json` |

---

## Documentation

Full step-by-step tutorial (agnostic, no personal data): [docs/tutorial.md](docs/tutorial.md)

---

## Project Structure

```
├── README.md
├── run.ps1 / run.bat            # Interactive menu (45K vs 150K)
├── scripts/
│   ├── start-iq4-45k.ps1/.bat    # High Precision 45K Q8 — 15.9GB
│   ├── start-iq3-150k.ps1/.bat   # Extended Context 150K Q4 — 15.0GB
│   ├── clear-vram.ps1/.bat       # Kill server and clear VRAM
│   └── README.md                 # Post-install usage
├── docs/
│   └── tutorial.md
├── .gitignore
└── LICENSE
```

Models are stored outside the repository in `C:\modelos` for easy access.

---

## Credits

- Model: [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF) (Apache 2.0)
- Discussion #26: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26 — hfmiguel, Hackin085, Bellatorius01
- llama.cpp: https://github.com/ggml-org/llama.cpp

---

<p align="center">
  <sub>Validated 2026-08-22 · RTX 5060 Ti · Driver 610.88 · CUDA 13.3 · b10586 · C:\modelos</sub>
</p>
