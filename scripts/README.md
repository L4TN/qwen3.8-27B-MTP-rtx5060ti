# Scripts â€” Post-install (systematic grid)

Use after installing `llama.cpp` to `C:\llamacpp` and models to `C:\modelos` (see main README).

| Script | Purpose | VRAM | Command |
|---|---|---|---|
| `start-iq4-32k-q8.ps1` / `.bat` | **High Precision â€” SAFE** â€” IQ4_XS 32K Q8 | 15705 MiB 96.3% 92/52 â€” also **45K limite** 15860 MiB 94/45 | `powershell -ExecutionPolicy Bypass -File scripts\start-iq4-32k-q8.ps1` |
| `start-iq4-90k-q4.ps1` / `.bat` | **High Precision â€” MAX** â€” IQ4_XS 90K Q4 **limite** | 15854 MiB 97.2% 107/46 â€” 100K colapsa | `powershell -ExecutionPolicy Bypass -File scripts\start-iq4-90k-q4.ps1` |
| `start-iq3-128k.ps1` / `.bat` | **Extended Context â€” SAFE** â€” IQ3_XXS 128K Q4 | 14736 MiB 90.3% 80/41 â€” also 64K/100K/148K market | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-128k.ps1` |
| `start-iq3-160k-q4.ps1` / `.bat` | **Extended Context â€” MAX** â€” IQ3_XXS 160K Q4 **limite** | 15528 MiB 95.2% 85/57 â€” 170K colapsa prompt | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-160k-q4.ps1` |
| `start-iq3-100k-q8.ps1` / `.bat` | **Q8 MAX** â€” IQ3_XXS 100K Q8 **limite** | 15452 MiB 94.7% 84/57 â€” 110K colapsa | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-100k-q8.ps1` |
| `start-iq3xxs-2.88bpw-184k-q4.ps1` / `.bat` | **ByteShape Q4 â€” MAX CONTEXT** â€” IQ3_XXS 2.88bpw 184K Q4 **definitivo** | 15359â€“15391 MiB 94.2% 945â€“1055/51â€“53 â€” 192K ~15600 MiB | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3xxs-2.88bpw-184k-q4.ps1` |
| `start-iq3xxs-2.88bpw-120k-q8.ps1` / `.bat` | **ByteShape Q8 â€” BEST KV** â€” IQ3_XXS 2.88bpw 120K Q8 **recomendado** | 15474 MiB 94.9% 962/51.2 â€” 124K 15657 MiB, 128K 15769 MiB (~48 t/s) | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3xxs-2.88bpw-120k-q8.ps1` |

| `start-inkling2-mini-ud-iq3xxs-100k-q8.bat` | **Inkling-2-Mini â€” DSpark** â€” UD-IQ3_XXS 100K (`102400`) KV f16/q8_0, drafter DSpark n-max 2 | 15721 MiB 96.4% 257/63.6 â€” 590 MiB livres; draft 52.3% (26.6 t/s com ~59k de prompt) | `scripts\start-inkling2-mini-ud-iq3xxs-100k-q8.bat` |
| `clear-vram.ps1` / `.bat` | **Clear VRAM** â€” kills `llama-server.exe` and frees GPU | â€” | `powershell -ExecutionPolicy Bypass -File scripts\clear-vram.ps1` |

All `.bat` are double-clickable; `.ps1` require `ExecutionPolicy Bypass`.

Grid sistemÃ¡tico `32K/64K/100K/128K/148K` + `limite` + `colapso` validado via `tools/bench-grid-v2.ps1` (`chat/completions 36tok/70tok`, `clear-vram` entre casos). 32K e 128K sÃ£o Ã¢ncoras de mercado seguras, com headroom em 16.3GB. Limites reais: IQ4 Q8 45K (50K colapsa), IQ4 Q4 90K (100K colapsa), IQ3 Q4 160K (170K colapsa prompt), IQ3 Q8 100K (110K colapsa).

**ByteShape IQ3_XXS 2.88bpw (9.24 GiB)** â€” modelo menor que o UD-IQ3_XXS, medido com `b12633` e `--load-mode mmap`. Q4 184K (15359â€“15391 MiB, 51â€“53 t/s, draft 60â€“64%) ou Q8 120K (15474 MiB, 51.2 t/s, draft 58.8%). Q8 124K = 15657 MiB (~396 livres); Q8 128K = 15769 MiB (~284 livres, ~48 t/s). Os dois scripts aceitam `-Ctx` para testar outros contextos. Modelo: [byteshape/Qwen3.8-27B-GGUF](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf).

**Inkling-2-Mini UD-IQ3_XXS + DSpark (Unsloth `b12651-mix-c7059d6`)** â€” outro modelo, stack Unsloth, GGUFs da raiz de [unsloth/Inkling-2-Mini-GGUF](https://huggingface.co/unsloth/Inkling-2-Mini-GGUF) (nÃ£o usar `Mainline_Support/`). Contexto **100k (`102400`)** com KV **f16/q8_0** e `ubatch 128`: **15721 MiB usados / 590 MiB livres**, prompt **256.9 t/s**, geraÃ§Ã£o **63.6 t/s**, aceitaÃ§Ã£o do drafter **52.3%** (n-max 2). A 120k a folga cai para 421 MiB e a geraÃ§Ã£o desaba para 24.9 t/s (~2.4Ã— pior que sem drafter) â€” por isso 100k. Com ~59k de prompt preenchido: 26.6 t/s com DSpark vs 34.0 t/s sem. Escada de KV: f16/f16 = 344 MiB livres (reprovado) â†’ f16/q8_0 = 421 MiB (aprovado). O `.bat` aceita `[ctx] [ctk] [ctv] [ubatch] [nmax]` e baixa os dois GGUFs sozinho. Detalhes completos em [docs/inkling-2-mini.md](inkling-2-mini.md).

**Typical flow:**
```powershell
# 1. Start high-precision 32K (safe)
.\scripts\start-iq4-32k.ps1
# open http://127.0.0.1:1234

# 2. Need more context â€” clear and switch to 128K
.\scripts\clear-vram.ps1
.\scripts\start-iq3-128k.ps1

# 3. Want max â€” clear and try sweet spots
.\scripts\clear-vram.ps1
# edit scripts to 45K or 150K, or run manual command from README

# 4. Done â€” clear VRAM
.\scripts\clear-vram.ps1
nvidia-smi  # should show ~400 MiB used
```

Notes:
- All start scripts set `LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'` and `flash-attn on`, `MTP n=3`, `parallel=1`.
- `clear-vram` kills all `llama-server` processes; close other GPU apps if VRAM stays high.
- For extreme tests, change `--ctx-size` to `45056` (IQ4) or `150000` (IQ3) â€” see main README Configurations.
