# Tutorial: Qwen3.8-27B UD-IQ4_XS + MTP n=3 + Q8 KV em RTX 5060 Ti 16GB (Windows 11)

> Validado em 22/08/2026: RTX 5060 Ti 16GB + Driver 610.88 + CUDA 13.3 + llama.cpp b10586 + `C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf` → **52.17 t/s prompt / 44.79 t/s geração, draft acceptance 0.59, VRAM 15.8GB**

Config recomendada pelo `Bellatorius01` para coding agent (mais qualidade que IQ3_XXS, 2x speedup com MTP).

Baseado na discussão #26: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26

---

## 0. Pré-requisitos

| Item | Requisito |
|---|---|
| **SO** | Windows 11 x64 22H2+ (PowerShell 5.1) |
| **GPU** | **NVIDIA 16GB VRAM** — RTX 5060 Ti 16GB validada. RTX 4080/4090 OK. 12GB ainda roda mas fica no limite |
| **RAM** | 32GB recomendado (16GB mínimo) |
| **Disco** | **20GB livres em C:** — modelo IQ4_XS tem 14.25GB + 1GB llama.cpp. Validado em `C:\modelos` (pasta de fácil acesso) |
| **Driver** | `>= 610.88` com **CUDA 13.3** — verifique `nvidia-smi` no canto sup esquerdo. RTX 50xx precisa CUDA 13.x, RTX 30xx/40xx pode usar 12.4 |
| **Internet** | 50 Mbps+ para baixar 14.25GB na 1ª vez |

```powershell
nvidia-smi
# deve mostrar: NVIDIA-SMI 610.88 ... CUDA UMD Version: 13.3  e  RTX 5060 Ti 16311 MiB
```

---

## 1. Dependências e Links

| O que | Link direto | Obs |
|---|---|---|
| **Driver NVIDIA** | https://www.nvidia.com/drivers — https://www.nvidia.com/Download/index.aspx | Game Ready / Studio ≥610.88 |
| **llama.cpp CUDA 13.3 (OFICIAL)** | https://github.com/ggml-org/llama.cpp/releases | Baixe `llama-b10586-bin-win-cuda-13.3-x64.zip` (ou `b10XXX` mais novo). **NÃO use `winget`** — instala Vulkan e cai pra 16-22 t/s |
| **CUDART runtime** | Mesmo releases acima → `cudart-llama-bin-win-cuda-13.3-x64.zip` | Contém `cublas64_13.dll`, `cublasLt64_13.dll`, `cudart64_13.dll` — extrair na mesma pasta do `llama-server.exe` |
| **Modelo IQ4_XS (14.25GB) - DOWNLOAD DIRETO** | **https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf** | Link direto para baixar. Página do arquivo: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-UD-IQ4_XS.gguf |
| **Repo com todos quants** | https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/tree/main | Lista de `UD-IQ3_XXS`, `Q4_K_S`, `Q8` etc. |
| **Discussão original** | https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26 | `hfmiguel` + `Hackin085` (fix CUDA) + `Bellatorius01` (benchmarks IQ4_XS) |

---

## 2. Instalação

### 2.1 Pastas

```powershell
mkdir C:\llamacpp
mkdir C:\modelos   # pasta de fácil acesso para os GGUFs
```

### 2.2 Baixar llama.cpp + CUDART

1. Baixe `llama-b10586-bin-win-cuda-13.3-x64.zip` e `cudart-llama-bin-win-cuda-13.3-x64.zip` de https://github.com/ggml-org/llama.cpp/releases
2. Extraia **ambos** para `C:\llamacpp` — as 3 DLLs devem ficar junto com `llama-server.exe`:

```powershell
Expand-Archive C:\Users\SeuUsuario\Downloads\llama-b10586-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
Expand-Archive C:\Users\SeuUsuario\Downloads\cudart-llama-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force

dir C:\llamacpp\llama-server.exe, C:\llamacpp\ggml-cuda.dll, C:\llamacpp\cudart64_13.dll
.\llama-server.exe --version
# version: 0.2.0-dev (build 10586) + GGML_CUDA=1
```

> Se aparecer `Vulkan` no `--version`, você baixou o ZIP errado.

### 2.3 Baixar o modelo IQ4_XS para C:\modelos

**Opção A — link direto (recomendado, pasta fácil acesso):**
```powershell
# PowerShell com curl (mais rápido que Invoke-WebRequest para 14GB)
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
# ou pelo navegador: abra o link e salve em C:\modelos
```

**Opção B — via llama-server (baixa sozinho para cache HF):**
```powershell
C:\llamacpp\llama-server.exe -hf unsloth/Qwen3.8-27B-GGUF:UD-IQ4_XS --help
# baixa para %USERPROFILE%\.cache\huggingface\hub (14.25GB)
```

Valide:
```powershell
dir C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf
# Length: 14252845984 (13.27 GB em disco)
```

---

## 3. Config IQ4_XS + Q8 KV + MTP n=3 (copie e cole)

> Testada neste PC em `C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf` — 32K contexto, `parallel=1`, `Flash-Attn on`, `reasoning medium`

```powershell
$env:LLAMA_ARG_CHAT_TEMPLATE_KWARGS='{"preserve-thinking":true,"reasoning_effort":"medium"}'

C:\llamacpp\llama-server.exe -m C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf `
 --no-mmproj --device CUDA0 `
 --spec-draft-device CUDA0 --gpu-layers-draft all `
 --spec-type draft-mtp --spec-draft-n-max 3 `
 --n-gpu-layers all --threads 6 `
 --fit off --load-mode none --no-warmup --flash-attn on `
 --ctx-size 32768 --parallel 1 `
 --cache-type-k q8_0 --cache-type-v q8_0 `
 --batch-size 512 --ubatch-size 512 `
 --jinja --temp 1 --top-p 0.95 --top-k 20 `
 --reasoning auto --reasoning-preserve --reasoning-effort medium `
 --host 127.0.0.1 --port 1234 -lv 4
```

**Alternativa com -hf (se não baixou manual):**
```powershell
C:\llamacpp\llama-server.exe -hf unsloth/Qwen3.8-27B-GGUF:UD-IQ4_XS --device CUDA0 --spec-draft-device CUDA0 --gpu-layers-draft all --spec-type draft-mtp --spec-draft-n-max 3 --n-gpu-layers all --threads 6 --ctx-size 32768 --cache-type-k q8_0 --cache-type-v q8_0 --host 127.0.0.1 --port 1234
```

### Resultado medido 22/08/2026 neste PC

```
Modelo: C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf (14.25GB)
VRAM: 15858 MiB / 16311 MiB (pico, sem spill para RAM)
prompt eval: 52.17 t/s (22 tokens / 421ms)
eval:       44.79 t/s (300 tokens / 6676ms)
draft acceptance: 0.59 (191/322) mean 2.77  acc/pos (0.778, 0.565, 0.426)
graphs reused: 105
# sem MTP seria ~26 t/s → 2x speedup, igual ao Bellatorius01:
#  2.5K: 54.1 t/s | 14.2K: 50.8 | 18.1K: 51.3 | 25.4K: 40.8
```

### Notas
- `parallel=1` obrigatório para 32K/94K não estourar VRAM
- `--fit off` impede o llama de reduzir ctx automaticamente
- `Q8_0 KV` gasta mais VRAM que `Q4_0` mas mantém qualidade IQ4_XS (15.8GB ainda cabe em 16GB)
- `reasoning-effort medium` — padrão `xhigh` overthinka e com `max_tokens=3000` não responde (use 6000+)
- MTP já dentro do GGUF (`nextn_predict_layers=1`, `blk.64.nextn.*`), não precisa draft separado

---

## 4. Como usar

WebUI: http://127.0.0.1:1234

API OpenAI:
```powershell
$body = @{
  model="Qwen3.8-27B-IQ4_XS"
  messages=@(@{role="user"; content="Explique o que e MTP em 2 frases."})
  stream=$false; max_tokens=800; temperature=1; top_p=0.95; top_k=20
} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri http://127.0.0.1:1234/v1/chat/completions -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
```

Logs:
```powershell
Get-Content C:\llamacpp\server.err -Tail 30
# procure: prompt eval ... tokens per second / eval ... tokens per second / draft acceptance
nvidia-smi
```

Parar:
```powershell
Get-Process llama-server | Stop-Process -Force
```

---

## 5. Troubleshooting

| Sintoma | Solução |
|---|---|
| 16-22 t/s com MTP | Build Vulkan — reinstale ZIP `cuda-13.3` |
| `CUDA error` | Atualize driver ≥610.88 (`nvidia-smi` CUDA 13.3) |
| `out of memory` | VRAM estourou — confirme `C:\modelos` em SSD, feche apps, mantenha `parallel=1`, reduza `ctx-size` |
| Resposta vazia | `reasoning medium` + `max_tokens` pequeno — aumente para 6000+ |
| Download 0 bytes | Firewall — teste `Invoke-WebRequest https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/config.json` |

---

## 6. Créditos

- Modelo: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF — arquivo IQ4_XS: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-UD-IQ4_XS.gguf
- Discussão #26: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26
- Bellatorius01 — benchmarks IQ4_XS + Q8 + MTP
- Hackin085 — fix `--device CUDA0` + diagnóstico Vulkan
- llama.cpp: https://github.com/ggml-org/llama.cpp

Atualizado em 22/08/2026 — config IQ4_XS validada em `C:\modelos` (RTX 5060 Ti, b10586).
