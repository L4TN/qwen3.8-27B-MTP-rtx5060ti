# Scripts — Post-install (systematic grid)

Use after installing `llama.cpp` to `C:\llamacpp` and models to `C:\modelos` (see main README).

| Script | Purpose | VRAM | Command |
|---|---|---|---|
| `start-iq4-32k-q8.ps1` / `.bat` | **High Precision — SAFE** — IQ4_XS 32K Q8 | 15705 MiB 96.3% 92/52 — also **45K limite** 15860 MiB 94/45 | `powershell -ExecutionPolicy Bypass -File scripts\start-iq4-32k-q8.ps1` |
| `start-iq4-90k-q4.ps1` / `.bat` | **High Precision — MAX** — IQ4_XS 90K Q4 **limite** | 15854 MiB 97.2% 107/46 — 100K colapsa | `powershell -ExecutionPolicy Bypass -File scripts\start-iq4-90k-q4.ps1` |
| `start-iq3-128k.ps1` / `.bat` | **Extended Context — SAFE** — IQ3_XXS 128K Q4 | 14736 MiB 90.3% 80/41 — also 64K/100K/148K market | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-128k.ps1` |
| `start-iq3-160k-q4.ps1` / `.bat` | **Extended Context — MAX** — IQ3_XXS 160K Q4 **limite** | 15528 MiB 95.2% 85/57 — 170K colapsa prompt | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-160k-q4.ps1` |
| `start-iq3-100k-q8.ps1` / `.bat` | **Q8 MAX** — IQ3_XXS 100K Q8 **limite** | 15452 MiB 94.7% 84/57 — 110K colapsa | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-100k-q8.ps1` |
| `start-iq3xxs-2.88bpw-184k-q4.ps1` / `.bat` | **ByteShape Q4 — MAX CONTEXT** — IQ3_XXS 2.88bpw 184K Q4 **definitivo** | 15359–15391 MiB 94.2% 945–1055/51–53 — 192K ~15600 MiB | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3xxs-2.88bpw-184k-q4.ps1` |
| `start-iq3xxs-2.88bpw-120k-q8.ps1` / `.bat` | **ByteShape Q8 — BEST KV** — IQ3_XXS 2.88bpw 120K Q8 **recomendado** | 15474 MiB 94.9% 962/51.2 — 124K 15657 MiB, 128K 15769 MiB (~48 t/s) | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3xxs-2.88bpw-120k-q8.ps1` |
| `clear-vram.ps1` / `.bat` | **Clear VRAM** — kills `llama-server.exe` and frees GPU | — | `powershell -ExecutionPolicy Bypass -File scripts\clear-vram.ps1` |

All `.bat` are double-clickable; `.ps1` require `ExecutionPolicy Bypass`.

Grid sistemático `32K/64K/100K/128K/148K` + `limite` + `colapso` validado via `tools/bench-grid-v2.ps1` (`chat/completions 36tok/70tok`, `clear-vram` entre casos). 32K e 128K são âncoras de mercado seguras, com headroom em 16.3GB. Limites reais: IQ4 Q8 45K (50K colapsa), IQ4 Q4 90K (100K colapsa), IQ3 Q4 160K (170K colapsa prompt), IQ3 Q8 100K (110K colapsa).

**ByteShape IQ3_XXS 2.88bpw (9.24 GiB)** — modelo menor que o UD-IQ3_XXS, medido com `b12633` e `--load-mode mmap`. Q4 184K (15359–15391 MiB, 51–53 t/s, draft 60–64%) ou Q8 120K (15474 MiB, 51.2 t/s, draft 58.8%). Q8 124K = 15657 MiB (~396 livres); Q8 128K = 15769 MiB (~284 livres, ~48 t/s). Os dois scripts aceitam `-Ctx` para testar outros contextos. Modelo: [byteshape/Qwen3.8-27B-GGUF](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf).

**Typical flow:**
```powershell
# 1. Start high-precision 32K (safe)
.\scripts\start-iq4-32k.ps1
# open http://127.0.0.1:1234

# 2. Need more context — clear and switch to 128K
.\scripts\clear-vram.ps1
.\scripts\start-iq3-128k.ps1

# 3. Want max — clear and try sweet spots
.\scripts\clear-vram.ps1
# edit scripts to 45K or 150K, or run manual command from README

# 4. Done — clear VRAM
.\scripts\clear-vram.ps1
nvidia-smi  # should show ~400 MiB used
```

Notes:
- All start scripts set `LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'` and `flash-attn on`, `MTP n=3`, `parallel=1`.
- `clear-vram` kills all `llama-server` processes; close other GPU apps if VRAM stays high.
- For extreme tests, change `--ctx-size` to `45056` (IQ4) or `150000` (IQ3) — see main README Configurations.
