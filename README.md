# Trabalho 4 — Testes de Desempenho com Link Extractor

**Trabalho 4** da disciplina de Computação Distribuída. Realiza testes de desempenho contra as duas versões
(Python e Ruby) do serviço de extração de links da aplicação **Link Extractor**,
usando **Locust** como ferramenta de carga em **Windows**.

PDF original do enunciado: [`docs/Trabalho 4 – Realização de Testes de Desempenho com a Aplicação Link Extractor.pdf`](docs/Trabalho%204%20%E2%80%93%20Realiza%C3%A7%C3%A3o%20de%20Testes%20de%20Desempenho%20com%20a%20Aplica%C3%A7%C3%A3o%20Link%20Extractor.pdf)

## O que é o trabalho

A aplicação Link Extractor ([ibnesayeed/linkextractor](https://github.com/ibnesayeed/linkextractor)) expõe um serviço de extração de links em duas versões de API — Python (porta 5000) e Ruby (porta 4567) — com cache Redis para acelerar respostas a URLs já visitadas.

O objetivo é medir e comparar o desempenho das duas versões sob diferentes condições, variando três fatores:

| Fator | Valores |
|---|---|
| Versão da API | Python / Ruby |
| Modo de cache | Com cache (warm) / Sem cache (cold) |
| Usuários virtuais | 10 / 50 / 100 |

Isso resulta em **12 cenários** (3 × 2 × 2). Cada usuário virtual executa sequências de **10 invocações** com URLs diferentes, conforme exigido pelo enunciado.

O modo **sem cache** é simulado adicionando um nonce único por requisição na URL, forçando 100% de cache miss no Redis sem modificar o código da aplicação.

## Métricas coletadas

O Locust exporta automaticamente, por cenário:

- `*_stats.csv` — agregados: média, mediana, p95, p99, min, max, RPS e falhas
- `*_stats_history.csv` — série temporal segundo a segundo
- `*_failures.csv` e `*_exceptions.csv` — detalhes de erros

## Análise dos resultados

Toda a análise é feita no notebook `analysis/analise.ipynb`, que lê os CSVs brutos,
gera a planilha consolidada e produz **10 gráficos comparativos**:

| Gráfico | O que mostra |
|---|---|
| **4.1 Tempo médio de resposta** | Comportamento central do sistema por nível de carga |
| **4.2 Mediana (p50)** | Latência do usuário típico; divergência com a média indica cauda longa |
| **4.3 Percentil 95 (p95)** | Experiência do usuário "quase mais lento"; limiar comum em SLAs |
| **4.4 Percentil 99 (p99)** | Cauda extrema; picos esporádicos que afetam a minoria |
| **4.5 Throughput (RPS)** | Requisições por segundo; achatar = saturação do serviço |
| **4.6 Falhas absolutas** | Total de respostas HTTP não-200 por cenário |
| **4.7 Com cache vs Sem cache** | Barras lado a lado (média, mediana, p95) para comparação direta |
| **4.8 Speedup do cache** | Quantas vezes mais rápido com cache (`mean_cold / mean_warm`) |
| **4.9 Taxa de erros (%)** | Percentual de falhas — permite comparar cenários com volumes distintos |
| **4.10 Heatmap de latência** | Visão matricial versão/cache × carga com gradiente de cor |

Os PNGs são salvos em `results/charts/` e a planilha consolidada em
`results/processed/consolidado.xlsx` (abas `resumo` e `series`).

## Estrutura do projeto

```
linkextractor-loadtest/
├── analysis/
│   ├── analise.ipynb        ← notebook: consolida CSVs, planilha e 10 gráficos
│   └── requirements.txt
├── docker/
│   ├── docker-compose.python.yml  ← stack com API Python (porta 5000)
│   └── docker-compose.ruby.yml    ← stack com API Ruby   (porta 4567)
├── docs/
│   ├── Trabalho 4 ... .pdf  ← enunciado original
│   └── cenarios-teste.md    ← descrição dos 12 cenários
├── locust/
│   ├── locustfile.py        ← script do usuário virtual (10 invocações por iteração)
│   ├── urls.py              ← as 10 URLs usadas nos testes
│   └── requirements.txt
├── results/
│   ├── raw/                 ← CSVs brutos do Locust (4 arquivos por cenário)
│   ├── processed/           ← consolidado.xlsx
│   └── charts/              ← PNGs gerados pelo notebook
└── scripts/
    ├── setup.ps1            ← setup único (venv, dependências, imagens Docker)
    ├── run-all-scenarios.ps1← roda os 12 cenários em sequência (~30 min)
    ├── run-scenario.ps1     ← roda 1 cenário (-Version -Cache -Users)
    ├── clear-cache.ps1      ← FLUSHALL no Redis entre cenários
    ├── start-app.ps1        ← sobe a stack Docker
    └── stop-app.ps1         ← derruba a stack Docker
```

## Como rodar (Windows)

### Pré-requisitos

1. **Docker Desktop** (WSL2 backend) — https://www.docker.com/products/docker-desktop/
2. **Python 3.11+** — https://www.python.org/downloads/windows/ (marcar "Add to PATH")
3. **Git for Windows** — https://git-scm.com/download/win

Abra um **PowerShell** na raiz do projeto.

### 1. Setup único

```powershell
.\scripts\setup.ps1
```

Cria o virtualenv `.venv`, instala todas as dependências (Locust, pandas, matplotlib,
openpyxl, jupyterlab) e baixa as imagens Docker do Link Extractor.

### 2. Rodar todos os 12 cenários

```powershell
.\scripts\run-all-scenarios.ps1
```

Sobe Python, roda os 6 cenários (warm/cold × 10/50/100), derruba, sobe Ruby,
roda os outros 6, derruba. Duração total: ~30 min. Os CSVs vão para `results/raw/`.

Para um teste rápido de fumaça:

```powershell
.\scripts\run-all-scenarios.ps1 -RunTime 30s
```

### 3. Rodar um cenário avulso

```powershell
.\scripts\start-app.ps1    -Version python
.\scripts\run-scenario.ps1 -Version python -Cache warm -Users 50
.\scripts\stop-app.ps1     -Version python
```

### 4. Gerar análise e gráficos

Abra o notebook no VSCode (extensão Jupyter) ou via terminal:

```powershell
.\.venv\Scripts\jupyter.exe lab analysis\analise.ipynb
```

Clique em **Run All**. O notebook irá:

1. Ler os CSVs de `results/raw/`
2. Salvar `results/processed/consolidado.xlsx`
3. Gerar e salvar os 10 PNGs em `results/charts/`

Ou execute em modo headless (sem abrir o Jupyter):

```powershell
.\.venv\Scripts\jupyter.exe nbconvert --to notebook --execute analysis\analise.ipynb --inplace
```

## Solução de problemas

- **`docker: command not found`** — Docker Desktop não está rodando. Abra o app e aguarde o ícone ficar verde.
- **Erro de conexão no Locust** — confirme que `start-app.ps1` terminou com sucesso. Teste: `curl "http://localhost:5000/?url=https://example.com/"`.
- **Falhas no cenário de 100 usuários** — pode ser saturação real do serviço, especialmente Ruby. Reporte como resultado, não tente contornar.
- **`FLUSHALL` falhou** — o container `lx-redis` não está rodando. Verifique com `docker ps`.
