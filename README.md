# Qwen 3 27B — 50 t/s on a Single RTX 5060 Ti

<p align="center">
  <img src="https://img.shields.io/badge/Windows%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" />
  <img src="https://img.shields.io/badge/CUDA%2013.3-76B900?style=for-the-badge&logo=nvidia&logoColor=white" />
  <img src="https://img.shields.io/badge/llama.cpp-b10586-000000?style=for-the-badge" />
  <img src="https://img.shields.io/badge/MTP-n=3-0A66C2?style=for-the-badge" />
</p>

<p align="center">
  <b>Qwen3.8-27B UD-IQ4_XS + MTP draft + Q8 KV cache rodando a 50+ t/s em uma única RTX 5060 Ti 16GB.</b><br>
  Sem cluster. Sem quantização extrema. Sem truque de Vulkan.
</p>

<p align="center">
  <a href="https://huggingface.co/unsloth/Qwen3.8-27B-GGUF">Modelo</a> •
  <a href="https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf">Download IQ4_XS (14.2GB)</a> •
  <a href="https://github.com/ggml-org/llama.cpp/releases">llama.cpp</a> •
  <a href="https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26">Discussão #26</a>
</p>

---

### O que é isso?

Repo mínimo para reproduzir os **50-60 t/s** do thread #26 do `unsloth/Qwen3.8-27B-GGUF` no Windows 11. O segredo não é overclock — é **MTP nativo do Qwen3.8** (`blk.64.nextn.*`) + **CUDA 13.3 real** + `Q8 KV` + `flash-attn`.

Validado em hardware real em **22/08/2026**:

|  | Sem MTP | **Com MTP n=3** |
|---|---|---|
| **Prompt** | 26 t/s | **52.17 t/s** (22 tok / 421ms) |
| **Geração** | ~25 t/s | **44.79 t/s** (300 tok) |
| **VRAM** | — | **15.8GB / 16GB** sem spill |
| **Acceptance** | — | **0.59** (191/322) `mean 2.77` |

> Base `IQ4_XS` mantém qualidade máxima (vs `IQ3_XXS` que faz 60 t/s mas perde qualidade). 2× speedup confirmado pelo `Bellatorius01`: `54.1 → 50.8 → 40.8 t/s` no range de coding agent.

---

### ✨ Por que esta config?

- **MTP embutido** — `Qwen3.8` já vem com `nextn_predict_layers=1`, não precisa draft externo
- **CUDA puro** — corrige o erro clássico do `winget` que instala Vulkan e trava em 16-22 t/s
- **Q8 KV + 32K** — equilíbrio perfeito: cabe nos 16GB (`15.8GB pico`) e segura contexto de agente
- **Pasta fácil** — modelo em `C:\modelos` (não no cache oculto do HF)

---

### ✅ Requisitos

- **GPU** NVIDIA 16GB (RTX 5060 Ti validada, 4080/4090 OK)
- **Driver** ≥ 610.88 com CUDA 13.3 — confirme com `nvidia-smi`
- **Disco** 20GB livres (modelo 14.25GB)
- **SO** Windows 11 + PowerShell

```powershell
nvidia-smi
# CUDA UMD Version: 13.3 | GeForce RTX 5060 Ti 16311 MiB
```

---

### 🚀 Quick Start (3 comandos)

```powershell
# 1. Baixe o modelo para C:\modelos
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf

# 2. Rode (já vem pronto)
.\run.ps1
# ou
.\run.bat

# 3. Abra
http://127.0.0.1:1234
```

Pronto. O script `run.ps1` já seta `reasoning_effort=medium` e sobe com:

```
--device CUDA0 --spec-draft-device CUDA0 --spec-type draft-mtp --spec-draft-n-max 3
--ctx-size 32768 --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on
```

<details>
<summary><b>Comando completo (se quiser copiar manual)</b></summary>

```powershell
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'
C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 32768 --parallel 1 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234
```

</details>

---

### 📊 Benchmarks

**Este repo (RTX 5060 Ti, b10586, Q8, 32K):**
```
prompt: 52.17 t/s | eval: 44.79 t/s | acceptance 0.59 (0.778, 0.565, 0.426)
VRAM 15858 MiB | graphs reused 105
```

**hfmiguel (IQ3_XXS, Q4, 94K):** `36 → 60 t/s` com MTP  
**Bellatorius01 (IQ4_XS, Q8, 32K):** `26.0 → 54.1 @2.5K | 24.9 → 50.8 @14K | 23.7 → 40.8 @25K`

---

### 🛠️ Troubleshooting

<details>
<summary><b>Só 16-22 t/s mesmo com MTP?</b></summary>
Você instalou o build Vulkan do `winget`. Reinstale o ZIP `cuda-13.3` de https://github.com/ggml-org/llama.cpp/releases e confirme `llama-server --version` mostra `GGML_CUDA=1`.
</details>

<details>
<summary><b>Resposta vazia com reasoning?</b></summary>
`reasoning_effort=medium` consome tokens de thinking. Aumente `max_tokens` para `6000+`. Padrão `xhigh` overthinka.
</details>

<details>
<summary><b>Download trava em 0 bytes?</b></summary>
Libere `huggingface.co` no firewall. Teste: `Invoke-WebRequest https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/config.json`
</details>

---

### 📁 Estrutura

```
├── README.md      # você está aqui
├── run.ps1        # PowerShell (recomendado)
├── run.bat        # duplo clique
├── .gitignore
└── LICENSE (MIT)
```

Modelos ficam **fora** do repo em `C:\modelos` (fácil acesso).

---

### 🙏 Créditos

Modelo [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF) (Apache 2.0) • Discussão [#26](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26) • `Bellatorius01` (benchmarks) • `Hackin085` (fix CUDA) • `hfmiguel` (config base) • [llama.cpp](https://github.com/ggml-org/llama.cpp)

---

<p align="center">
  <sub>Validado 22/08/2026 • RTX 5060 Ti • Driver 610.88 • CUDA 13.3 • b10586 • <code>C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf</code></sub>
</p>
