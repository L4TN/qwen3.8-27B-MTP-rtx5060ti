# Scripts — Post-install

Use after installing `llama.cpp` to `C:\llamacpp` and models to `C:\modelos` (see main README).

| Script | Purpose | VRAM | Command |
|---|---|---|---|
| `start-iq4-45k.ps1` / `.bat` | **High Precision** — IQ4_XS 45K Q8 (sweet spot) | 15.9 GB / 16.3 GB (15963 MiB) | `powershell -ExecutionPolicy Bypass -File scripts\start-iq4-45k.ps1` |
| `start-iq3-150k.ps1` / `.bat` | **Extended Context** — IQ3_XXS 150K Q4 (sweet spot, 94K–250K validated) | 15.0 GB / 16.3 GB (15323 MiB) | `powershell -ExecutionPolicy Bypass -File scripts\start-iq3-150k.ps1` |
| `clear-vram.ps1` / `.bat` | **Clear VRAM** — kills `llama-server.exe` and frees GPU | — | `powershell -ExecutionPolicy Bypass -File scripts\clear-vram.ps1` |

All `.bat` are double-clickable; `.ps1` require `ExecutionPolicy Bypass`.

**Typical flow:**
```powershell
# 1. Start high-precision 45K
.\scripts\start-iq4-45k.ps1
# open http://127.0.0.1:1234

# 2. Need more context — clear and switch to 150K
.\scripts\clear-vram.ps1
.\scripts\start-iq3-150k.ps1

# 3. Done — clear VRAM
.\scripts\clear-vram.ps1
nvidia-smi  # should show ~400 MiB used
```

Notes:
- Both start scripts set `LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'` and `flash-attn on`, `MTP n=3`, `parallel=1`.
- `clear-vram` kills all `llama-server` processes; close other GPU apps if VRAM stays high.
