# 🧠 Qwen 3 27B @ 50 t/s em 16GB — Uma RTX pra dominar todas

<p align="center">
  <img src="https://img.shields.io/badge/RTX_5060_Ti_16GB-50%2B_t%2Fs-76B900?style=for-the-badge&logo=nvidia&logoColor=white" />
  <img src="https://img.shields.io/badge/CUDA_13.3-BlackWell-000000?style=for-the-badge&logo=nvidia&logoColor=white" />
  <img src="https://img.shields.io/badge/MTP_n=3-2X_SPEEDUP-0A66C2?style=for-the-badge" />
  <img src="https://img.shields.io/badge/llama.cpp-b10586-8A2BE2?style=for-the-badge" />
</p>

<p align="center">
  <b>27 bilhões de parâmetros. Uma única RTX 5060 Ti. 50 tokens por segundo.</b><br>
  Não é mágica. É <b>MTP nativo do Qwen3.8</b> + <b>CUDA 13.3 de verdade</b> (não Vulkan) + o quant certo.
</p>

<p align="center">
  <a href="https://huggingface.co/unsloth/Qwen3.8-27B-GGUF"><b>Modelo</b></a> •
  <a href="#-dois-modos-um-hardware">Dois Modos</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26">Thread #26</a>
</p>

---

### 🎭 Dois modos. Um hardware. Você escolhe.

> Validado em 22/08/2026 — RTX 5060 Ti 16GB • Driver 610.88 • CUDA 13.3 • b10586 • `C:\modelos`

| | **🔪 MODO BISTURI**<br>Precisão Cirúrgica | **🚀 MODO CANHÃO**<br>Contexto Monstro |
|---|---|---|
| **Pra quem é** | Coding agent, raciocínio, produção | Análise de codebase, livros, RAG longo |
| **Modelo** | `UD-IQ4_XS` — 14.25GB | `UD-IQ3_XXS` — 10.9GB |
| **Download** | [IQ4_XS.gguf](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf) | [IQ3_XXS.gguf](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf) |
| **Contexto** | `32K` — ideal pra agente | `94K` — 92K usáveis (`parallel=1`) |
| **KV Cache** | `Q8_0` (qualidade máxima) | `Q4_0` (economia extrema) |
| **VRAM pico** | `15.8GB / 16GB` | `14.1GB / 16GB` |
| **Prompt** | **52.17 t/s** | **54.54 t/s** |
| **Geração** | **44.79 t/s** | **60.14 t/s** |
| **MTP accept** | `0.59` mean `2.77` | `0.79` mean `3.38` |
| **Qualidade** | ⭐⭐⭐⭐⭐ Melhor | ⭐⭐⭐⭐ Ótima |

> **Sem MTP seria ~26 t/s.** O `MTP n=3` dobra. É o `nextn_predict_layers` já dentro do GGUF (`blk.64.nextn.*`).

---

### ⚡ Por que isso importa?

Antes dessa thread, uma 5060 Ti fazia `26 t/s`. Agora faz `50+ t/s` no mesmo hardware. O truque que a maioria erra:

- ❌ `winget install llama.cpp` → instala **Vulkan** → `16-22 t/s` com GPU em 100%
- ✅ **Build CUDA 13.3 oficial** → `50-60 t/s` reais — 2× mais rápido sem mudar nada no PC

Este repo é o setup **que realmente passou** no `nvidia-smi` e no `server.err` — não teoria.

---

### 📦 Requisitos

```
Windows 11 + RTX 16GB (5060 Ti validada) + Driver ≥610.88 (CUDA 13.3) + 20GB livres
```

```powershell
nvidia-smi
# CUDA UMD Version: 13.3 | RTX 5060 Ti 16311 MiB
```

---

### 🚀 Quick Start

```powershell
# 1. Pastas
mkdir C:\llamacpp; mkdir C:\modelos

# 2. Baixe llama.cpp de https://github.com/ggml-org/llama.cpp/releases
#    llama-b10586-bin-win-cuda-13.3-x64.zip + cudart-llama-bin-win-cuda-13.3-x64.zip
#    Extraia AMBOS para C:\llamacpp (as 3 DLLs junto com llama-server.exe)

# 3. Baixe O MODELO QUE VOCÊ QUER:
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
# ou para 94K:
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf

# 4. Rode
.\run.ps1          # pergunta qual modo você quer
# ou duplo clique em run.bat
```

Abra **http://127.0.0.1:1234** — WebUI + API OpenAI.

---

### 🎛️ Os dois comandos (copie e cole)

<details open>
<summary><b>🔪 MODO BISTURI — IQ4_XS • 32K • Q8 (recomendado p/ 99% dos casos)</b></summary>

```powershell
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'
C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 32768 --parallel 1 --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234
```

*Use quando precisa de resposta perfeita. Coding, análise, produção.*

</details>

<details>
<summary><b>🚀 MODO CANHÃO — IQ3_XXS • 94K • Q4 (para contexto gigante)</b></summary>

```powershell
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'
C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --fit off --load-mode none --no-warmup --flash-attn on --ctx-size 94208 --parallel 1 --cache-type-k q4_0 --cache-type-v q4_0 --batch-size 512 --ubatch-size 512 --jinja --temp 1 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 0.0 --repeat-penalty 1.0 --reasoning auto --reasoning-preserve --reasoning-effort medium --host 127.0.0.1 --port 1234
```

*Use quando precisa enfiar documentação inteira, repo gigante ou livro no prompt. `parallel=1` é obrigatório pra chegar nos 94K.*

</details>

> **Dica de ouro:** `reasoning_effort=medium` é obrigatório. O padrão `xhigh` overthinka e com `max_tokens=3000` a resposta vem vazia. Use `6000+`.

---

### 📊 Benchmarks reais (não são estimativas)

**Este PC — RTX 5060 Ti:**

```
🔪 BISTURI  IQ4_XS  Q8  32K : prompt 52.17 t/s | eval 44.79 t/s | 15.8GB | acc 0.59
🚀 CANHÃO   IQ3_XXS Q4  94K : prompt 54.54 t/s | eval 60.14 t/s | 14.1GB | acc 0.79
```

**hfmiguel (IQ3_XXS 94K):** `35 t/s sem MTP → 50-55 t/s com MTP`  
**Bellatorius01 (IQ4_XS Q8 32K):** `26.0→54.1 @2.5K | 24.9→50.8 @14K | 23.7→40.8 @25K`

---

### 💻 Uso (API)

```powershell
$body = @{ model="Qwen3.8-27B-IQ4_XS"; messages=@(@{role="user"; content="Explique MTP em 2 frases."}); stream=$false; max_tokens=800; temperature=1; top_p=0.95; top_k=20 } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri http://127.0.0.1:1234/v1/chat/completions -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
```

Troque `model` para testar o outro quant — mesmo servidor, só reinicie com o outro comando.

---

### 🛠️ Se deu ruim

| Sintoma | Causa | Fix |
|---|---|---|
| `16-22 t/s` com MTP | Build Vulkan | Reinstale ZIP `cuda-13.3`, `llama-server --version` deve ter `GGML_CUDA=1` |
| Resposta vazia | `max_tokens` curto | Aumente pra `6000+` com `medium` |
| `out of memory` | VRAM | Use `BISTURI 32K`, feche apps, `parallel=1` |

---

### 📁 O que tem aqui

```
├── README.md  # você está aqui
├── run.ps1    # menu interativo: escolhe BISTURI ou CANHÃO
├── run.bat    # duplo clique
├── .gitignore
└── LICENSE
```
Modelos em `C:\modelos` — fora do repo, fácil acesso.

---

### 🙏 Créditos

Modelo [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF) (Apache 2.0) • Thread [#26](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26) • `Bellatorius01` • `Hackin085` (fix CUDA) • `hfmiguel` • [llama.cpp](https://github.com/ggml-org/llama.cpp)

<p align="center">
  <sub>Validado 22/08/2026 • b10586 • CUDA 13.3 • Driver 610.88 • <code>C:\modelos</code> • Feito pra quem não tem A100 mas quer performance de A100</sub>
</p>
