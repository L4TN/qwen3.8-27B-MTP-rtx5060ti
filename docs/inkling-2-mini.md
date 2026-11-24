# Inkling-2-Mini em 1x RTX 5060 Ti 16GB — Unsloth llama.cpp + DSpark

Registro completo do que foi usado para rodar o **Inkling-2-Mini** nesta máquina: build do llama.cpp, release da Unsloth (e o fix antecipado do DSpark que ela carrega), CUDA, quant, script e todos os números medidos. Tudo abaixo foi medido em hardware real em **2026-11-24**.

## Config aprovada (resumo)

| Item | Valor |
|---|---|
| Contexto | **102400 (100k)** |
| KV cache | **`--cache-type-k f16 --cache-type-v q8_0`** |
| Batch / ubatch | `--batch-size 512 --ubatch-size 128` |
| DSpark | `--spec-type draft-dspark --spec-draft-n-max 2 --spec-draft-n-min 0 --spec-draft-p-min 0` |
| VRAM | **15684–15721 MiB usados / 590–627 MiB livres** (96.2–96.4% de 16311 MiB) |
| Prompt | **243.5–256.9 t/s** (prompt de 391 tokens) |
| Geração | **58.9–63.6 t/s** |
| Aceitação do drafter | **46.7–52.3%** |
| Alias | `inkling-2-mini-ud-iq3xxs-100k` |
| Script | [`scripts/start-inkling2-mini-ud-iq3xxs-100k-q8.bat`](../scripts/start-inkling2-mini-ud-iq3xxs-100k-q8.bat) |

## Versões exatas

| Componente | Versão / identificador |
|---|---|
| GPU | NVIDIA GeForce RTX 5060 Ti — 16311 MiB, compute capability **12.0** (sm_120, Blackwell) |
| Driver | **621.24** |
| OS | Windows 11, PowerShell 5.1 |
| llama.cpp upstream | **[b12651](https://github.com/ggml-org/llama.cpp/releases/tag/b12651)** (ggml-org) |
| Release Unsloth | **[`b12651-mix-c7059d6`](https://github.com/unslothai/llama.cpp/releases/tag/b12651-mix-c7059d6)** — publicado 2026-11-23T21:34:46Z |
| Source commit | `d426a3774f880823d0064b5a13312bea946f2fb3` (`d426a37`) |
| Asset usado | `app-b12651-mix-c7059d6-windows-x64-cuda13-portable.zip` — 435,756,017 bytes |
| SHA-256 do zip | `e3b9282157da3ea76fae7c47f878201394496e0e563697d2e8fff1ee04cdd2a9` (confere com `llama-prebuilt-sha256.json`) |
| Toolkit do build | CUDA **13.3** (redist NVIDIA), MSVC 19.44.35230.0, sms 75/80/86/89/90/100/103/120 |
| Runtime CUDA copiado | `cudart64_13.dll` **13.5** (6.14.11.13050) + `cublas64_13.dll` / `cublasLt64_13.dll` **13.1** (6.14.11.13100), do pacote `cudart-llama-bin-win-cuda-13.5-x64` |
| `llama-server --version` | `1.0.0-dev (build 12651, commit d426a3774)` |
| Instalação | `C:\llamacpp-unsloth\` (53 entradas, `BUILD_INFO.txt` = `b12651-mix-c7059d6` / `variant: cuda13-portable`) |

### O fix antecipado do DSpark

O suporte a **Inkling 2 DSpark** entrou no upstream como `ggml-org#32218` (head `e4b1cb531`) **mais** o caminho fundido `0a9105de4` — ou seja, **dois layouts de drafter diferentes**. A release da Unsloth traz isso no prebuilt via:

| PR Unsloth | Commit | O que resolve |
|---|---|---|
| [#405](https://github.com/unslothai/llama.cpp/pull/405) | `b5ed9f2` | **Inkling 2 DSpark com os dois layouts de drafter** (head `e4b1cb531` + caminho fundido `0a9105de4`) — o fix que interessa aqui |
| [#397](https://github.com/unslothai/llama.cpp/pull/397) | `805b04c` | mantém os pesos de fusão do DSpark em F32 no `llama-quantize` |
| [#395](https://github.com/unslothai/llama.cpp/pull/395) | `dd330cc` | `inkling2_loop` também carrega o layout looped anterior do Inkling 2 |
| [#396](https://github.com/unslothai/llama.cpp/pull/396) | `bff7247` | camadas looped, placement por camadas de peso e views de peso no host |
| [#385](https://github.com/unslothai/llama.cpp/pull/385) / [#386](https://github.com/unslothai/llama.cpp/pull/386) | `4aae13c` / `210fc26` | atenção com relative-bias do Inkling 2 em chunks + flash attention banded |
| [#421](https://github.com/unslothai/llama.cpp/pull/421) | `b336a7e` | uma entrada de cache MoE por peso de expert nas camadas looped |
| [#378](https://github.com/unslothai/llama.cpp/pull/378) | `2c38e50` | modelo Inkling **1** no prebuilt |

Também vem no mesmo build: DiffusionGemma (#24423) e uma série de kernels CUDA novos (#400, #401, #402, #411–#418).

> **Por que essa build e não outra:** a build anterior `b12631-mix-acc0843` carregava **só um** dos layouts de drafter. A `b12651-mix-c7059d6` carrega os dois e é a que roda com o GGUF da raiz do repo Unsloth. A linha `b12676` (mainline) **não** foi usada — o GGUF dela (`Mainline_Support/`) tem layout incompatível com este build.

## Quant usado

| Papel | Arquivo | Bytes | SHA-256 (HF) | Link |
|---|---|---|---|---|
| Modelo | `Inkling-2-Mini-UD-IQ3_XXS.gguf` | 11,663,310,784 (10.86 GiB) | `6583a291d645dc5e234f45a18a99f673ca6a76b432ec52302764856db9a03922` | [unsloth/Inkling-2-Mini-GGUF](https://huggingface.co/unsloth/Inkling-2-Mini-GGUF/resolve/main/Inkling-2-Mini-UD-IQ3_XXS.gguf) |
| Drafter | `dspark-Inkling-2-Mini-Q8_0.gguf` | 503,889,952 (480 MiB) | `88cdbef7659a647a2a2453a0a546092165feb2070b0be9249ca8b3c8af559bd9` | [unsloth/Inkling-2-Mini-GGUF](https://huggingface.co/unsloth/Inkling-2-Mini-GGUF/resolve/main/dspark-Inkling-2-Mini-Q8_0.gguf) |

Repo: [unsloth/Inkling-2-Mini-GGUF](https://huggingface.co/unsloth/Inkling-2-Mini-GGUF) — **raiz**, não a subpasta `Mainline_Support/`.

Download (gravando em `.part` e renomeando ao concluir):

```powershell
mkdir C:\modelos -Force
curl.exe -L -C - --retry 10 --retry-delay 5 --fail --progress-bar `
  "https://huggingface.co/unsloth/Inkling-2-Mini-GGUF/resolve/main/Inkling-2-Mini-UD-IQ3_XXS.gguf" `
  -o "C:\modelos\Inkling-2-Mini-UD-IQ3_XXS-unsloth.gguf.part"
Move-Item "C:\modelos\Inkling-2-Mini-UD-IQ3_XXS-unsloth.gguf.part" "C:\modelos\Inkling-2-Mini-UD-IQ3_XXS-unsloth.gguf"

curl.exe -L -C - --retry 10 --retry-delay 5 --fail --progress-bar `
  "https://huggingface.co/unsloth/Inkling-2-Mini-GGUF/resolve/main/dspark-Inkling-2-Mini-Q8_0.gguf" `
  -o "C:\modelos\dspark-Inkling-2-Mini-Q8_0-unsloth.gguf.part"
Move-Item "C:\modelos\dspark-Inkling-2-Mini-Q8_0-unsloth.gguf.part" "C:\modelos\dspark-Inkling-2-Mini-Q8_0-unsloth.gguf"
```

## Instalação do runtime

```powershell
# 1. release Unsloth b12651-mix-c7059d6
curl.exe -L -C - --fail -o "$env:TEMP\app-b12651-mix-c7059d6-windows-x64-cuda13-portable.zip" `
  "https://github.com/unslothai/llama.cpp/releases/download/b12651-mix-c7059d6/app-b12651-mix-c7059d6-windows-x64-cuda13-portable.zip"
Expand-Archive "$env:TEMP\app-b12651-mix-c7059d6-windows-x64-cuda13-portable.zip" -DestinationPath C:\llamacpp-unsloth -Force

# 2. DLLs CUDA que o zip portable NAO inclui
Copy-Item "<pasta>\cudart-llama-bin-win-cuda-13.5-x64\*.dll" C:\llamacpp-unsloth -Force

# 3. sanidade
C:\llamacpp-unsloth\llama-server.exe --list-devices
# esperado: CUDA0: NVIDIA GeForce RTX 5060 Ti (16283 MiB, ... free)
```

> O zip `cuda13-portable` **não** traz `cudart64_13.dll` / `cublas64_13.dll` / `cublasLt64_13.dll`. Sem elas, `--list-devices` responde `(none)` e o servidor morre com `error while handling argument "--device": invalid device: CUDA0`. Basta deixá-las ao lado do `llama-server.exe` — **não** defina `GGML_BACKEND_PATH` apontando para o diretório (gera `load_backend: failed to load`).

## Script

[`scripts/start-inkling2-mini-ud-iq3xxs-100k-q8.bat`](../scripts/start-inkling2-mini-ud-iq3xxs-100k-q8.bat) — CRLF, auto-download embutido, sem `enable_thinking`.

| Arg | Default | Uso |
|---|---|---|
| `%1` ctx | `102400` | `--ctx-size` |
| `%2` ctk | `f16` | `--cache-type-k` |
| `%3` ctv | `q8_0` | `--cache-type-v` |
| `%4` ubatch | `128` | `--ubatch-size` |
| `%5` nmax | `2` | `--spec-draft-n-max` |

Ex.: `scripts\start-inkling2-mini-ud-iq3xxs-100k-q8.bat 65536 f16 q8_0 128 3`

Flags completas:

```
-m C:\modelos\Inkling-2-Mini-UD-IQ3_XXS-unsloth.gguf
-md C:\modelos\dspark-Inkling-2-Mini-Q8_0-unsloth.gguf
--alias inkling-2-mini-ud-iq3xxs-100k
--spec-type draft-dspark --spec-draft-n-max 2 --spec-draft-n-min 0 --spec-draft-p-min 0
--device CUDA0 --n-gpu-layers all --gpu-layers-draft all
--ctx-size 102400 --parallel 1
--cache-type-k f16 --cache-type-v q8_0
--batch-size 512 --ubatch-size 128
--threads 6 --threads-batch 6
--fit off --load-mode mmap --no-mmproj --no-warmup
--flash-attn on --ctx-checkpoints 32 --jinja
--temp 1.0 --top-p 1.0 --top-k 0 --min-p 0
--reasoning auto --reasoning-preserve --reasoning-effort medium
--host 0.0.0.0 --port 1234
```

Sem `--spec-draft-device` (`-devd`): o DSpark usa os **embeddings/LM head do alvo** e precisa estar na mesma GPU. Sem `enable_thinking` (depreciado) no `LLAMA_ARG_CHAT_TEMPLATE_KWARGS`.

## Escada de KV a 122880 (o teste que decidiu a config)

| KV K / V | VRAM usada | Livre | Veredito |
|---|---|---|---|
| f16 / f16 | 15967 MiB | 344 MiB | reprovado (<350 MiB) |
| **f16 / q8_0** | **15890 MiB** | **421 MiB** | **aprovado** |
| q8_0 / q8_0 | — | — | não necessário |

`--ubatch-size 256` não foi testado: a regra era só testar com >800 MiB livres e nenhum degrau chegou lá.

## Resultados a 102400

| Config | VRAM | Livre | Prompt (391 tok) | Geração | Draft |
|---|---|---|---|---|---|
| **DSpark n=2** | **15721 MiB (96.4%)** | **590 MiB** | 256.9 t/s | **63.6 t/s** | 45/86 (52.3%) |
| DSpark n=3 | 15765 MiB (96.6%) | 546 MiB | 254.3 t/s | 58.6 t/s | 49/138 (35.5%) |
| sem drafter | 14628 MiB (89.7%) | 1683 MiB | 346.5 t/s | 61.3 t/s | — |

Bench oficial (`bench-inkling.ps1`, servidor subido pelo `.bat`): **15684 MiB usados / 627 MiB livres**, prompt **243.5 t/s**, geração **58.9 t/s**, draft **42/90 (46.7%)**.

### DSpark vs contexto (n=3, mesmos flags, só muda `--ctx-size`)

| Contexto | VRAM | Geração | Draft |
|---|---|---|---|
| 16K (16384) | 13137 MiB | 69.8 t/s | 62/114 (54.4%) |
| 32K (32768) | 13634 MiB | 60.5 t/s | 55/132 (41.7%) |
| 100K (102400) | 15765 MiB | 58.6 t/s | 49/138 (35.5%) |
| 120K (122880) | 15905–15971 MiB | 24.9 t/s | 56/144 (38.9%) |

### Contexto preenchido (prompt de 58.981 tokens, ctx 102400)

| Config | Prompt | Geração | Draft |
|---|---|---|---|
| DSpark n=2 | 489.1 t/s | **26.6 t/s** | 51/96 (53.1%) |
| DSpark n=3 | 672.7 t/s | 23.8 t/s | 48/147 (32.7%) |
| sem drafter | 735.2 t/s | **34.0 t/s** | — |

## Metodologia

`bench-inkling.ps1`: poll de `/health` até `ok`, leitura de `/props` (`n_ctx`), `nvidia-smi memory.used,memory.total`, e `POST /v1/chat/completions` com prompt fixo de ~391 tokens, `max_tokens 200`, `temperature 1.0`, `top_p 1.0`, `top_k 0`, `min_p 0`; timings de `timings.prompt_per_second`, `predicted_per_second`, `draft_n`, `draft_n_accepted`. O teste de contexto preenchido repete o mesmo prompt com padding até 58.981 tokens. `clear-vram` (kill `llama-server` + 4 s de espera) entre casos.

## Limitações conhecidas

- **120k com DSpark não fecha**: em `122880` sobram 421 MiB e a geração cai para 24.9 t/s (~2.4× pior que sem drafter). Em `102400` sobram 590 MiB e o DSpark rende 63.6 t/s.
- **DSpark perde acima de ~60k de contexto preenchido**: 26.6 t/s (n=2) contra 34.0 t/s sem drafter — o drafter faz atenção sobre todo o contexto a cada passo.
- `--spec-draft-n-max 8` não ajuda (26.0 t/s a 120k, aceitação 54/357).
- `n-max 2` > `n-max 3` a 100k (+8.5% de geração) por reduzir o custo de validação em lote.
- `--ubatch-size` acima de 128 estoura a VRAM nesta GPU (OOM observado) — manter 128.
- Prompt t/s varia com o tamanho do prompt (batching): 243–257 t/s com 391 tokens, 489–735 t/s com ~59k.
- O DSpark é **lossless**: cada token sugerido é validado pelo modelo principal; `--cache-type-k f16` preserva a precisão da atenção.

## Referências

- Modelo: [unsloth/Inkling-2-Mini-GGUF](https://huggingface.co/unsloth/Inkling-2-Mini-GGUF)
- Build: [unslothai/llama.cpp `b12651-mix-c7059d6`](https://github.com/unslothai/llama.cpp/releases/tag/b12651-mix-c7059d6)
- Upstream: [ggml-org/llama.cpp b12651](https://github.com/ggml-org/llama.cpp/releases/tag/b12651)
- Fix do DSpark: [unslothai/llama.cpp#405](https://github.com/unslothai/llama.cpp/pull/405)
