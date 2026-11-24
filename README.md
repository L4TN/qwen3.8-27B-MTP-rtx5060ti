# Qwen3.8-27B em 1x RTX 5060 Ti 16GB â€” Extraia o mÃ¡ximo com MTP nativo
Apos configurar no windows atravÃ©s do Schedule Tasks/Agendador de Tarefas o start do script (At User Logon (Any)), vamos pegar o ip da maquina em ipconfig, ipv4 adress, com esse ip config vamos alcanÃ§ar nosso server de AI na mesma rede local Wifi em outro computador (ou podemos disponibilizar para a internet via ngrok)

{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "local-llama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Local llama.cpp",
      "options": {
        "baseURL": "http://192.168.15.67:1234/v1",
        "apiKey": "sk-local"
      },
      "models": {
        "YOUR_EXACT_MODEL_ID": {
          "name": "Qwen 3.8 27B",
          "limit": {
            "context": 65536,
            "output": 8192
          }
        }
      }
    }
  },
  "model": "local-llama/YOUR_EXACT_MODEL_ID"
}
<p align="center">
  <img src="https://img.shields.io/badge/Windows%2011-0078D6?style=flat&logo=windows&logoColor=white" />
  <img src="https://img.shields.io/badge/CUDA%2013.3-76B900?style=flat&logo=nvidia&logoColor=white" />
  <img src="https://img.shields.io/badge/llama.cpp-b10586-000000?style=flat" />
  <img src="https://img.shields.io/badge/MTP-n=3-0A66C2?style=flat" />
  <img src="https://img.shields.io/badge/VRAM-16311_MiB-8A2BE2?style=flat" />
</p>

**Rode Qwen3.8-27B em casa, em uma Ãºnica GPU gamer, a 50+ t/s.** Este repo entrega a configuraÃ§Ã£o validada em hardware real para extrair o mÃ¡ximo da RTX 5060 Ti 16GB com MTP nativo â€” sem gambiarras, sem estimativas, sÃ³ nÃºmeros medidos.

TrÃªs quants validados, dois KVs testados, todos os contextos com VRAM, prompt e geraÃ§Ã£o documentados. Escolha qualidade mÃ¡xima ou contexto gigante e reproduza com um clique.

> **Novo (2026-11-24):** **Inkling-2-Mini UD-IQ3_XXS + DSpark** na stack Unsloth (`b12651-mix-c7059d6`): **100k (`102400`) de contexto com KV f16/q8_0**, 15721 MiB usados / 590 MiB livres, **63.6 t/s** de geraÃ§Ã£o e **52.3%** de aceitaÃ§Ã£o do drafter. Ver [Inkling-2-Mini](#inkling-2-mini-ud-iq3_xxs--1086-gib-unsloth-b12651--dspark).

> **Novo (2026-11-22):** o quant **IQ3_XXS 2.88bpw da ByteShape** (9.24 GiB) rende **184K de contexto com KV q4_0** ou **120K com KV q8_0**, mantendo ~51 t/s de geraÃ§Ã£o. Ver [ByteShape IQ3_XXS 2.88bpw](#byteshape-iq3_xxs-288bpw--924-gb-b12633).

## Ambiente

| Componente | VersÃ£o |
|---|---|
| GPU | ASUS RTX 5060 Ti PCIe 5.0 â€” 16311 MiB (16.3 GB) |
| Driver | 610.88 |
| CUDA | 13.3 (UMD) |
| OS | Windows 11 22H2, PowerShell 5.1 |
| llama.cpp | b10586 (`GGML_CUDA=1`) |
| Data | 2026-08-22 (revalidado 2026-08-22 em grid sistemÃ¡tico) |
| Placa-mÃ£e | ASUS PRIME B350M (PCIe 3.0) |
| MÃ©todo | MTP n=3, `flash-attn on`, `parallel 1`, `threads 6`, `batch 512`, `chat/completions 36 tok prompt / 70 tok gen`, `clear-vram` entre casos |

> GPU ASUS PCIe 5.0 operando em PCIe 3.0 x16 â€” banda limitada a ~15.75 GB/s. NÃºmeros medidos refletem essa condiÃ§Ã£o; em PCIe 4.0/5.0 a banda Ã© maior.

VRAM total: **16311 MiB**. Limite estÃ¡vel: **~15.9 GB (97-98%)**.

## Modelos

| Quant | Arquivo | Tamanho | Download |
|---|---|---|---|
| UD-IQ4_XS | `Qwen3.8-27B-UD-IQ4_XS.gguf` | 14.25 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf) |
| UD-IQ3_XXS | `Qwen3.8-27B-UD-IQ3_XXS.gguf` | 10.9 GB | [Hugging Face](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf) |
| **IQ3_XXS 2.88bpw (ByteShape)** | `Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf` | **9.24 GiB** (9,919,481,216 bytes) | [Hugging Face](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf) |

Exemplo: `C:\modelos` (fora do repo, como usado nos testes).

## Metodologia (acadÃªmica)

Grid sistemÃ¡tico em nÃºmeros de mercado `32K/64K/100K/128K/148K` + `limite` + `colapso +5K/+10K`. Procedimento por caso: `clear-vram` (kill `llama-server` + `nvidia-smi`), subida com `--fit off --load-mode none --no-warmup`, poll `http://127.0.0.1:1234/health` atÃ© 200s, captura `nvidia-smi memory.used` + `KV buffer size` do log (`CUDA0 KV ...` + draft), `POST /v1/chat/completions` com `messages=[user: "Explain quantum entanglement..."]`, `max_tokens=70`, `temperature=1`, `top_p=0.95`, captura `timings.prompt_n/prompt_ms/prompt_per_second` e `predicted_per_second` + `draft_n/draft_n_accepted`. CritÃ©rio de colapso: `prompt <15 t/s` ou `gen <15 t/s` (attention quadrÃ¡tico). Logs brutos em `C:\Temp\bench\bench_*.log(.err)` e CSV `bench-results-v2.csv`. Todos os `start-*.ps1` reproduzem exatamente os mesmos flags.

## Resultados (revalidados â€” grid sistemÃ¡tico)

### IQ4_XS â€” 14.25 GB

**Q8_0** â€” KV q8_0 (precisÃ£o)

| Contexto | VRAM | % | Prompt | GeraÃ§Ã£o | Draft | Reproduzir |
|---|---|---|---|---|---|---|
| 32K | 15705 MiB | 96.3% | 92.73 t/s | 52.68 t/s | 72.3% | [`start-iq4-32k-q8.ps1`](scripts/start-iq4-32k-q8.ps1) |
| **45K limite** | **15860 MiB** | **97.2%** | **94.85 t/s** | **45.55 t/s** | **76.2%** | [`start-iq4-45k-q8.ps1`](scripts/start-iq4-45k-q8.ps1) |
| 50K | 15750 MiB | 96.6% | 27.86 t/s | 10.75 t/s | 55.8% | colapso â€” alÃ©m do limite (`start-iq4-50k-q8.ps1`, 64K tambÃ©m colapsa 25/9) |

**Q4_0** â€” KV q4_0 (contexto)

| Contexto | VRAM | % | Prompt | GeraÃ§Ã£o | Draft | Reproduzir |
|---|---|---|---|---|---|---|
| 32K | 15105 MiB | 92.6% | 110.37 t/s | 46.18 t/s | 60.3% | [`start-iq4-32k-q4.ps1`](scripts/start-iq4-32k-q4.ps1) |
| 64K | 15865 MiB | 97.3% | 104.57 t/s | 41.82 t/s | 55.3% | [`start-iq4-64k-q4.ps1`](scripts/start-iq4-64k-q4.ps1) |
| 80K | 15842 MiB | 97.1% | 107.90 t/s | 41.32 t/s | 60.3% | [`start-iq4-80k-q4.ps1`](scripts/start-iq4-80k-q4.ps1) |
| **90K limite** | **15854 MiB** | **97.2%** | **107.26 t/s** | **46.28 t/s** | **72.3%** | [`start-iq4-90k-q4.ps1`](scripts/start-iq4-90k-q4.ps1) |
| 100K | 15856 MiB | 97.2% | 23.07 t/s | 8.25 t/s | 77.4% | colapso â€” alÃ©m do limite (`start-iq4-100k-q4.ps1`) |

> Limite IQ4 Q4 subiu de 80K â†’ 90K apÃ³s revalidaÃ§Ã£o sistemÃ¡tica; Q8 mantÃ©m 45K.

### IQ3_XXS â€” 10.9 GB

**Q4_0** â€” KV q4_0 (contexto gigante, mercado)

| Contexto | VRAM | % | Prompt | GeraÃ§Ã£o | Draft | Reproduzir |
|---|---|---|---|---|---|---|
| 32K | 12060 MiB | 73.9% | 72.24 t/s | 57.45 t/s | 78.7% | [`start-iq3-32k-q4.ps1`](scripts/start-iq3-32k-q4.ps1) |
| 64K | 12888 MiB | 79.0% | 76.00 t/s | 57.18 t/s | 76.2% | [`start-iq3-64k-q4.ps1`](scripts/start-iq3-64k-q4.ps1) |
| 100K | 13882 MiB | 85.1% | 63.98 t/s | 44.37 t/s | 53.2% | [`start-iq3-100k-q4.ps1`](scripts/start-iq3-100k-q4.ps1) |
| 128K | 14736 MiB | 90.3% | 80.25 t/s | 41.47 t/s | 49.4% | [`start-iq3-128k.ps1`](scripts/start-iq3-128k.ps1) |
| 148K | 15206 MiB | 93.2% | 83.29 t/s | 50.06 t/s | 63.4% | [`start-iq3-148k-q4.ps1`](scripts/start-iq3-148k-q4.ps1) |
| 150K | 15254 MiB | 93.5% | 80.68 t/s | 54.00 t/s | 72.3% | [`start-iq3-150k.ps1`](scripts/start-iq3-150k.ps1) |
| **160K limite** | **15528 MiB** | **95.2%** | **85.99 t/s** | **57.05 t/s** | **76.2%** | [`start-iq3-160k-q4.ps1`](scripts/start-iq3-160k-q4.ps1) |
| 170K | 15808 MiB | 96.9% | 5.76 t/s | 57.14 t/s | 80.0% | colapso prompt â€” attention quadrÃ¡tico (`start-iq3-170k-q4.ps1`, 250K mÃ¡x experimental) |

> Limite IQ3 Q4 subiu de 150K â†’ 160K; 170K jÃ¡ colapsa prompt (gen ainda 57).

**Q8_0** â€” KV q8_0

| Contexto | VRAM | % | Prompt | GeraÃ§Ã£o | Draft | Reproduzir |
|---|---|---|---|---|---|---|
| 32K | 12590 MiB | 77.2% | 82.80 t/s | 46.67 t/s | 55.1% | [`start-iq3-32k-q8.ps1`](scripts/start-iq3-32k-q8.ps1) |
| 64K | 13902 MiB | 85.2% | 87.33 t/s | 57.16 t/s | 77.4% | [`start-iq3-64k-q8.ps1`](scripts/start-iq3-64k-q8.ps1) |
| **100K limite** | **15452 MiB** | **94.7%** | **84.24 t/s** | **57.44 t/s** | **80.0%** | [`start-iq3-100k-q8.ps1`](scripts/start-iq3-100k-q8.ps1) |
| 110K | 15860 MiB | 97.2% | 5.72 t/s | 53.81 t/s | 74.6% | colapso prompt (`start-iq3-110k-q8.ps1`) |
| 120K | 15850 MiB | 97.2% | 5.76 t/s | 54.64 t/s | 83.1% | colapso prompt (`start-iq3-120k-q8.ps1`) |

> Limite IQ3 Q8 caiu de 110K â†’ 100K apÃ³s critÃ©rio prompt <15 t/s; 110K/120K colapsam prompt mas geraÃ§Ã£o mantÃ©m ~54 t/s.

### ByteShape IQ3_XXS 2.88bpw â€” 9.24 GB (b12633)

Modelo: [`Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf`](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf) â€” 9,919,481,216 bytes (9.24 GiB), ~0.65 GiB menor que o UD-IQ3_XXS. Esse espaÃ§o extra Ã© o que permite 184K de contexto.

Medido com llama.cpp **b12633** (CUDA 13.5), `--load-mode mmap` (RAM do sistema 15.8 GB â€” sem mmap o modelo nÃ£o cabe em RAM + VRAM), `--no-mmproj` (sem visÃ£o), MTP n=3, `flash-attn on`, `parallel 1`, `threads 6`, `batch/ubatch 512`.

**Q4_0** â€” KV q4_0 (contexto mÃ¡ximo)

| Contexto | VRAM | % | Prompt (1.5K) | GeraÃ§Ã£o | Draft | Reproduzir |
|---|---|---|---|---|---|---|
| 160K (163840) | ~14880 MiB | 91.2% | â€” | â€” | â€” | `start-iq3xxs-2.88bpw-184k-q4.ps1 -Ctx 163840` |
| 176K (180224) | ~15150 MiB | 92.9% | â€” | â€” | â€” | `start-iq3xxs-2.88bpw-184k-q4.ps1 -Ctx 180224` |
| **184K (188416) â€” definitivo** | **15359â€“15391 MiB** | **94.2%** | **945â€“1055 t/s** | **51â€“53 t/s** | **60â€“64%** | [`start-iq3xxs-2.88bpw-184k-q4.ps1`](scripts/start-iq3xxs-2.88bpw-184k-q4.ps1) |
| 192K (196608) | ~15600 MiB | 95.6% | â€” | â€” | â€” | `start-iq3xxs-2.88bpw-184k-q4.ps1 -Ctx 196608` |

**Q8_0** â€” KV q8_0 (precisÃ£o de KV)

| Contexto | VRAM | % | Prompt (1.5K) | GeraÃ§Ã£o | Draft | Reproduzir |
|---|---|---|---|---|---|---|
| **120K (122880) â€” recomendado** | **15474 MiB** | **94.9%** | **~962 t/s** | **51.2 t/s** | **58.8%** | [`start-iq3xxs-2.88bpw-120k-q8.ps1`](scripts/start-iq3xxs-2.88bpw-120k-q8.ps1) |
| 124K (126976) â€” limite prÃ¡tico | 15657 MiB | 96.0% | ~969 t/s | 51.2 t/s | â€” | `start-iq3xxs-2.88bpw-120k-q8.ps1 -Ctx 126976` |
| 128K (131072) â€” arriscado | 15769 MiB | 96.7% | 712â€“780 t/s | 48â€“49 t/s | â€” | `start-iq3xxs-2.88bpw-120k-q8.ps1 -Ctx 131072` |

> **Q4 vs Q8:** geraÃ§Ã£o praticamente idÃªntica (~51 t/s). Q8 melhora a precisÃ£o do KV cache mas custa ~64K de contexto (120K vs 184K). `--ctx-checkpoints 0` **nÃ£o** reduz VRAM em 128K â€” checkpoints nÃ£o sÃ£o o gargalo, o KV Ã©.
>
> **Limites:** Q4 184K deixa ~650 MiB livres (192K usa ~15600 MiB). Q8 128K deixa sÃ³ ~284 MiB livres e o prompt cai para 712â€“780 t/s; 124K (~396 MiB) Ã© o limite prÃ¡tico.
>
> Startup ~5â€“6 s com cache quente. Alias: `qwen3.8-27b-iq3xxs` (Q4) / `qwen3.8-27b-iq3xxs-q8` (Q8).

### Inkling-2-Mini UD-IQ3_XXS â€” 10.86 GiB (Unsloth b12651 + DSpark)

Outra famÃ­lia de modelo, rodando na stack **Unsloth** com o drafter **DSpark** (speculative decoding nativo). Build: [`unslothai/llama.cpp` `b12651-mix-c7059d6`](https://github.com/unslothai/llama.cpp/releases/tag/b12651-mix-c7059d6) (`app-...-windows-x64-cuda13-portable.zip` + DLLs `cudart64_13` / `cublas64_13` / `cublasLt64_13` 13.5 ao lado do exe). GGUFs da **raiz** de [unsloth/Inkling-2-Mini-GGUF](https://huggingface.co/unsloth/Inkling-2-Mini-GGUF) â€” a subpasta `Mainline_Support/` usa layout incompatÃ­vel com essa build.

| Arquivo | Bytes | Tamanho |
|---|---|---|
| `Inkling-2-Mini-UD-IQ3_XXS.gguf` | 11,663,310,784 | 10.86 GiB |
| `dspark-Inkling-2-Mini-Q8_0.gguf` (drafter) | 503,889,952 | 480 MiB |

Flags: `--spec-type draft-dspark --spec-draft-n-max 2 --spec-draft-n-min 0 --spec-draft-p-min 0`, `--n-gpu-layers all --gpu-layers-draft all`, `--flash-attn on`, `--ctx-checkpoints 32`, `--load-mode mmap --no-mmproj --no-warmup`, `--fit off`, `--parallel 1`, `threads 6`, `batch 512 / ubatch 128`. **Sem `--spec-draft-device`**: o DSpark precisa dos embeddings/LM head do alvo na mesma GPU.

**Escada de KV a 122880** (o teste que definiu a config):

| KV K / V | VRAM usada | Livre | Veredito |
|---|---|---|---|
| f16 / f16 | 15967 MiB | 344 MiB | reprovado (<350 MiB) |
| **f16 / q8_0** | **15890 MiB** | **421 MiB** | **aprovado** |
| q8_0 / q8_0 | â€” | â€” | nÃ£o necessÃ¡rio |

**100k (`102400`) â€” config final, KV f16/q8_0, ubatch 128:**

| Config | VRAM | Livre | Prompt (391 tok) | GeraÃ§Ã£o | Draft |
|---|---|---|---|---|---|
| **DSpark n=2** | **15721 MiB (96.4%)** | **590 MiB** | 256.9 t/s | **63.6 t/s** | 45/86 (52.3%) |
| DSpark n=3 | 15765 MiB (96.6%) | 546 MiB | 254.3 t/s | 58.6 t/s | 49/138 (35.5%) |
| sem drafter | 14628 MiB (89.7%) | 1683 MiB | 346.5 t/s | 61.3 t/s | â€” |

Com contexto preenchido (~59k tokens de prompt, ainda a 102400) o DSpark perde traÃ§Ã£o: **26.6 t/s** (n=2) e 23.8 t/s (n=3) contra **34.0 t/s** sem drafter â€” o drafter faz atenÃ§Ã£o sobre todo o contexto a cada passo.

**DSpark vs contexto** (n=3, mesma config de 120k, sÃ³ variando `--ctx-size`):

| Contexto | GeraÃ§Ã£o | Draft |
|---|---|---|
| 16K (16384) | 69.8 t/s | 62/114 (54.4%) |
| 32K (32768) | 60.5 t/s | 55/132 (41.7%) |
| 100K (102400) | 58.6 t/s | 49/138 (35.5%) |
| 120K (122880) | 24.9 t/s | 56/144 (38.9%) |

> **120k nÃ£o fecha com DSpark:** em `122880` a folga cai a 421 MiB e a geraÃ§Ã£o desaba para 24.9 t/s â€” ~2.4Ã— mais lento que sem drafter. Em `102400` sobram 590 MiB e o DSpark volta a renderizar 63.6 t/s.
> `--spec-draft-n-max 8` nÃ£o ajuda (26.0 t/s a 120k, aceitaÃ§Ã£o 54/357). `n-max 2` > `n-max 3` a 100k (+8.5%) porque reduz o custo de validaÃ§Ã£o em lote.
> Alias: `inkling-2-mini-ud-iq3xxs-100k`. Launcher: [`start-inkling2-mini-ud-iq3xxs-100k-q8.bat`](scripts/start-inkling2-mini-ud-iq3xxs-100k-q8.bat) â€” aceita `[ctx] [ctk] [ctv] [ubatch] [nmax]` (defaults `102400 f16 q8_0 128 2`) e baixa os dois GGUFs sozinho via `curl.exe -L -C -` em `.part`.
> Versões, hashes, fix do DSpark e curva de contexto: [docs/inkling-2-mini.md](docs/inkling-2-mini.md).

## InstalaÃ§Ã£o

**1. Verifique o CUDA**

```powershell
nvidia-smi
```

Deve exibir `610.88`, `CUDA UMD Version: 13.3` e `16311 MiB` para a RTX 5060 Ti.

**2. Instale o llama.cpp (b10586 Ã© o commit da release validada)**

Crie a pasta:

```powershell
mkdir C:\llamacpp
```

Baixe em [releases â€” b10586](https://github.com/ggml-org/llama.cpp/releases/tag/b10586) (ou `latest` em [releases](https://github.com/ggml-org/llama.cpp/releases)):
- `llama-b10586-bin-win-cuda-13.3-x64.zip`
- `cudart-llama-bin-win-cuda-13.3-x64.zip`

Extraia **ambos** para `C:\llamacpp` (clique direito > Extrair tudo, ou via PowerShell):

```powershell
Expand-Archive $HOME\Downloads\llama-b10586-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
Expand-Archive $HOME\Downloads\cudart-llama-bin-win-cuda-13.3-x64.zip -DestinationPath C:\llamacpp -Force
dir C:\llamacpp\llama-server.exe, C:\llamacpp\cudart64_13.dll, C:\llamacpp\cublas64_13.dll
C:\llamacpp\llama-server.exe --version
```

Deve constar `GGML_CUDA=1`. Se constar `Vulkan`, o pacote estÃ¡ incorreto â€” substitua pelo build CUDA 13.3.

**3. Baixe os modelos**

```powershell
mkdir C:\modelos
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ4_XS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ4_XS.gguf
curl.exe -L -o C:\modelos\Qwen3.8-27B-UD-IQ3_XXS.gguf https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-IQ3_XXS.gguf
curl.exe -L -o C:\modelos\Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf
dir C:\modelos\*.gguf
```

**4. Rode**

```powershell
.\run.ps1
.\scripts\clear-vram.ps1
```

Ou direto (exemplos â€” limites validados):

```powershell
.\scripts\start-iq4-45k-q8.ps1   # IQ4 45K Q8 limite (15705/15860 MiB, 50K colapsa)
.\scripts\start-iq4-90k-q4.ps1   # IQ4 90K Q4 limite (15854 MiB, 100K colapsa)
.\scripts\start-iq3-160k-q4.ps1  # IQ3 160K Q4 limite (15528 MiB, 170K colapsa prompt)
.\scripts\start-iq3-100k-q8.ps1  # IQ3 100K Q8 limite (15452 MiB, 110K colapsa)
.\scripts\start-iq3xxs-2.88bpw-184k-q4.ps1  # ByteShape 184K Q4 (15359-15391 MiB, 51-53 t/s)
.\scripts\start-iq3xxs-2.88bpw-120k-q8.ps1  # ByteShape 120K Q8 (15474 MiB, 51.2 t/s)
.\scripts\start-inkling2-mini-ud-iq3xxs-100k-q8.bat  # Inkling-2-Mini 100K + DSpark n=2 (15721 MiB, 63.6 t/s)
```

Demais scripts seguem o padrÃ£o `start-iq{quant}-{ctx}-{kv}.ps1` â€” mercado `32K/64K/100K/128K/148K` + `limite` + `colapso` (ver `scripts/` e `tools/bench-results-v2.csv`).

**5. Abra `http://127.0.0.1:1234`**

## Scripts

```
run.ps1 / run.bat
scripts/start-iq4-32k-q8.ps1    # Q8 32K  15705 MiB 92/52
scripts/start-iq4-45k-q8.ps1    # Q8 45K limite 15860 MiB 94/45
scripts/start-iq4-50k-q8.ps1    # Q8 50K colapso 27/10
scripts/start-iq4-32k-q4.ps1    # Q4 32K 15105 MiB 110/46
scripts/start-iq4-64k-q4.ps1    # Q4 64K 15865 MiB 104/41
scripts/start-iq4-90k-q4.ps1    # Q4 90K limite 15854 MiB 107/46
scripts/start-iq4-100k-q4.ps1   # Q4 100K colapso 23/8
scripts/start-iq3-32k-q4.ps1    # Q4 32K 12060 MiB 72/57
scripts/start-iq3-64k-q4.ps1    # Q4 64K 12888 MiB 76/57
scripts/start-iq3-100k-q4.ps1   # Q4 100K 13882 MiB 63/44
scripts/start-iq3-128k.ps1      # Q4 128K 14736 MiB 80/41
scripts/start-iq3-148k-q4.ps1   # Q4 148K 15206 MiB 83/50
scripts/start-iq3-160k-q4.ps1   # Q4 160K limite 15528 MiB 85/57
scripts/start-iq3-100k-q8.ps1   # Q8 100K limite 15452 MiB 84/57
scripts/start-iq3-110k-q8.ps1   # Q8 110K colapso prompt 5.7/53
scripts/start-iq3xxs-2.88bpw-184k-q4.ps1  # ByteShape Q4 184K limite 15359-15391 MiB 945-1055/51-53
scripts/start-iq3xxs-2.88bpw-120k-q8.ps1  # ByteShape Q8 120K 15474 MiB 962/51.2
scripts/start-inkling2-mini-ud-iq3xxs-100k-q8.bat  # Inkling-2-Mini 100K DSpark n=2 15721 MiB 257/63.6 (590 livres)
scripts/clear-vram.ps1
tools/bench-grid-v2.ps1         # bench sistemÃ¡tico
docs/tutorial.md
```

Cada `.ps1` tem seu `.bat` equivalente. Modelos ficam em `C:\modelos` (fora do repo).

## ReferÃªncias

- Modelo: [unsloth/Qwen3.8-27B-GGUF](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF)
- Modelo IQ3_XXS 2.88bpw: [byteshape/Qwen3.8-27B-GGUF](https://huggingface.co/byteshape/Qwen3.8-27B-GGUF/blob/main/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf)
- llama.cpp: https://github.com/ggml-org/llama.cpp
- DiscussÃ£o #26: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/discussions/26
