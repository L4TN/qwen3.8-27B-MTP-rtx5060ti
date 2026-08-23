# Qwen3.8-27B em 1x RTX 5060 Ti 16GB — Extraia o máximo com MTP nativo

<p align="center">
  <img src="https://img.shields.io/badge/Windows%2011-0078D6?style=flat&logo=windows&logoColor=white" />
  <img src="https://img.shields.io/badge/CUDA%2013.3-76B900?style=flat&logo=nvidia&logoColor=white" />
  <img src="https://img.shields.io/badge/llama.cpp-b10586-000000?style=flat" />
  <img src="https://img.shields.io/badge/MTP-n=3-0A66C2?style=flat" />
  <img src="https://img.shields.io/badge/VRAM-16311_MiB-8A2BE2?style=flat" />
</p>

**Rode Qwen3.8-27B em casa, em uma única GPU gamer, a 50+ t/s.** Este repo entrega a configuração validada em hardware real para extrair o máximo da RTX 5060 Ti 16GB com MTP nativo — sem gambiarras, sem estimativas, só números medidos.

Dois quants validados, dois KVs testados, todos os contextos com VRAM, prompt e geração documentados. Escolha qualidade máxima ou contexto gigante e reproduza com um clique.

## Ambiente

| Componente | Versão |
|---|---|
| GPU | RTX 5060 Ti 16311 MiB (16.3 GB) |
| Driver | 610.88 |
| CUDA | 13.3 (UMD) |
| OS | Windows 11 22H2, PowerShell 5.1 |
| llama.cpp | b10586 (`GGML_CUDA=1`) |
| Data | 2026-08-22 |
| Método | MTP n=3, `flash-attn on`, `parallel 1`, `threads 6`, `batch 512`, `24 tok prompt / 70 tok gen` |

VRAM total: **16311 MiB**. Limite estável: **~15.9 GB (97-98%)**.

## Modelos

| Quant | Arquivo | Tamanho | Download |
|---|---|---|---|
| UD-IQ4_XS | `Qwen3.8-27B-UD-IQ4_XS.gguf` | 14.25 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf) |
| UD-IQ3_XXS | `Qwen3.8-27B-UD-IQ3_XXS.gguf` | 10.9 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf) |

Exemplo: `C:\modelos` (fora do repo, como usado nos testes).

## Resultados

### IQ4_XS — 14.25 GB — Alta Precisão

**Q8_0 — qualidade máxima**

| Contexto | VRAM | % | Prompt | Geração | Reproduzir |
|---|---|---|---|---|---|
| 32K | 15843 MiB | 97.1% | 44.81 t/s | 50.72 t/s | [`start-iq4-32k.ps1`](scripts/start-iq4-32k.ps1) |
| **45K limite** | **15963 MiB** | **97.8%** | **52.36 t/s** | **46.14 t/s** | [`start-iq4-45k.ps1`](scripts/start-iq4-45k.ps1) |

> Q8_0 é o teto de qualidade do IQ4_XS. 45K é o máximo que cabe em 16GB.

**Q4_0 — mais contexto, mesma VRAM**

| Contexto | VRAM | % | Prompt | Geração | Reproduzir |
|---|---|---|---|---|---|
| 32K | 15347 MiB | 94.1% | 60.60 t/s | 48.94 t/s | [`start-iq4-32k-q4.ps1`](scripts/start-iq4-32k-q4.ps1) |
| 45K | 15585 MiB | 95.5% | 53.45 t/s | 48.32 t/s | [`start-iq4-45k-q4.ps1`](scripts/start-iq4-45k-q4.ps1) |
| 60K | 15891 MiB | 97.4% | 50.87 t/s | 42.67 t/s | [`start-iq4-60k-q4.ps1`](scripts/start-iq4-60k-q4.ps1) |
| 70K | 15851 MiB | 97.2% | 54.66 t/s | 43.54 t/s | [`start-iq4-70k-q4.ps1`](scripts/start-iq4-70k-q4.ps1) |
| **80K limite** | **15844 MiB** | **97.1%** | **44.07 t/s** | **43.85 t/s** | [`start-iq4-80k-q4.ps1`](scripts/start-iq4-80k-q4.ps1) |
| 90K | 15914 MiB | 97.6% | 28.10 t/s | 10.27 t/s | colapso — além do limite |

> Q4_0 troca um pouco de fidelidade do KV por **+77% de contexto** (45K→80K) na mesma VRAM.

### IQ3_XXS — 10.9 GB — Contexto Gigante

**Q4_0 — capacidade máxima**

| Contexto | VRAM | % | Prompt | Geração | Reproduzir |
|---|---|---|---|---|---|
| 94K | 13873 MiB | 85.1% | 36.63 t/s | 44.36 t/s | `--ctx-size 94208` |
| 110K | 14308 MiB | 87.7% | 34.14 t/s | 45.07 t/s | `--ctx-size 110000` |
| 128K | 15061 MiB | 92.3% | 41.35 t/s | 56.72 t/s | [`start-iq3-128k.ps1`](scripts/start-iq3-128k.ps1) |
| 130K | 14775 MiB | 90.6% | 41.04 t/s | 54.47 t/s | `--ctx-size 130000` |
| **150K limite** | **15323 MiB** | **93.9%** | **41.54 t/s** | **52.71 t/s** | [`start-iq3-150k.ps1`](scripts/start-iq3-150k.ps1) |
| 170K | 15872 MiB | 97.3% | 2.84 t/s | 44.95 t/s | colapso — attention quadrático |
| 250K | 15911 MiB | 97.5% | — | — | máximo que cabe; 262K OOM |

**Q8_0 — para comparação**

| Contexto | VRAM | % | Prompt | Geração | Reproduzir |
|---|---|---|---|---|---|
| **110K limite** | **15908 MiB** | **97.5%** | **3.60 t/s** | **44.05 t/s** | `--ctx-size 110000 --cache-type-k q8_0 --cache-type-v q8_0` |

> Com IQ3, Q8_0 é contraproducente: perde **-27% de contexto** (150K→110K) e colapsa o prompt 10x (41→3.6 t/s). Use Q4_0 para contexto longo. Até 150K estável; geração mantém ~43 t/s via MTP mesmo após colapso de prompt.

Todos os comandos usam `--cache-type-k/v` correspondente e demais flags padrão do repo.

## Instalação

**1. Verifique o CUDA**

```powershell
nvidia-smi
```

Tem que mostrar `610.88` e `CUDA UMD Version: 13.3` e `16311 MiB`.

**2. Baixe o llama.cpp**

Baixe `llama-b10586-bin-win-cuda-13.3-x64.zip` e `cudart-llama-bin-win-cuda-13.3-x64.zip` em [llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases). Extraia ambos para `C:\llamacpp`.

```powershell
Expand-Archive llama-b10586-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
Expand-Archive cudart-llama-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
.\llama-server.exe --version
```

Valide com `.\llama-server.exe --version` — deve constar `GGML_CUDA=1`. Se constar `Vulkan`, o build é incorreto e deve ser substituído pelo pacote CUDA 13.3.

**3. Baixe os modelos**

```powershell
mkdir C:\modelos
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf
```

**4. Rode**

```powershell
.\run.ps1
.\scripts\clear-vram.ps1
```

Ou direto:

```powershell
.\scripts\start-iq4-32k.ps1      # Q8  32K 15.5 GB
.\scripts\start-iq4-45k.ps1      # Q8  45K 15.9 GB limite
.\scripts\start-iq4-32k-q4.ps1   # Q4  32K 94.1%
.\scripts\start-iq4-45k-q4.ps1   # Q4  45K 95.5%
.\scripts\start-iq4-60k-q4.ps1   # Q4  60K 97.4%
.\scripts\start-iq4-70k-q4.ps1   # Q4  70K 97.2%
.\scripts\start-iq4-80k-q4.ps1   # Q4  80K 97.1% limite
.\scripts\start-iq3-128k.ps1     # Q4 128K 92.3%
.\scripts\start-iq3-150k.ps1     # Q4 150K 93.9% limite
```

**5. Abra `http://127.0.0.1:1234`**

## API

```powershell
$body = @{model="Qwen3.8-27B";messages=@(@{role="user";content="Olá"});stream=$false;max_tokens=800} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri http://127.0.0.1:1234/v1/chat/completions -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"
```

## Scripts

```
run.ps1 / run.bat
scripts/start-iq4-32k.ps1       # Q8 32K  15.5 GB safe
scripts/start-iq4-45k.ps1       # Q8 45K  15.9 GB limite
scripts/start-iq4-32k-q4.ps1    # Q4 32K  94.1%
scripts/start-iq4-45k-q4.ps1    # Q4 45K  95.5%
scripts/start-iq4-60k-q4.ps1    # Q4 60K  97.4%
scripts/start-iq4-70k-q4.ps1    # Q4 70K  97.2%
scripts/start-iq4-80k-q4.ps1    # Q4 80K  97.1% limite
scripts/start-iq3-128k.ps1      # Q4 128K 92.3% safe
scripts/start-iq3-150k.ps1      # Q4 150K 93.9% limite
scripts/clear-vram.ps1
docs/tutorial.md
```

Cada `.ps1` tem seu `.bat` equivalente. Modelos ficam em `C:\modelos` (fora do repo).

## Referências

- Modelo: [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF)
- llama.cpp: https://github.com/ggml-org/llama.cpp
- Discussão #26: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26
