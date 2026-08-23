# Scripts — Post-install (safe market defaults)

Use after installing `llama.cpp` to `C:\llamacpp` and models to `C:\modelos` (see main README).

| Script | Purpose | VRAM | Command |
|---|---|---|---|
| `start-iq4-32k.ps1` / `.bat` | **High Precision — SAFE** — IQ4_XS 32K Q8 (market standard, 15.5GB) | 15.5 GB / 16.3 GB (15843 MiB) — also 45K 15.9GB validated | `powershell -ExecutionPolicy Bypass -File scripts\start-iq4-32k.ps1` |
| `start-iq3-128k.ps1` / `.bat` | **Extended Context — SAFE** — IQ3_XXS 128K Q4 (market standard, ~14.3GB) | 14.3 GB / 16.3 GB (~14650 MiB) — also 150K 15.0GB sweet spot, 250K max | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-128k.ps1` |
| `clear-vram.ps1` / `.bat` | **Clear VRAM** — kills `llama-server.exe` and frees GPU | — | `powershell -ExecutionPolicy Bypass -File scripts\clear-vram.ps1` |

All `.bat` are double-clickable; `.ps1` require `ExecutionPolicy Bypass`.

Why safe? 32K and 128K are the most common market context windows (habitually seen), leave headroom on 16.3GB and keep prompt eval fast (52/38 t/s). Extremes 45K (15.9GB) and 150K (15.0GB) are validated and documented in main README/Benchmarks as sweet spots.

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
