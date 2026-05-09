# Trabalho 4 — Testes de Desempenho com Link Extractor

Projeto da disciplina (Trabalho 4) que realiza testes de desempenho contra as
duas versões (Python e Ruby) do serviço de extração de links da aplicação
**Link Extractor**, usando **Locust** em **Windows**.

PDF original do enunciado: [`docs/Trabalho 4 – Realização de Testes de Desempenho com a Aplicação Link Extractor.pdf`](docs/Trabalho%204%20%E2%80%93%20Realiza%C3%A7%C3%A3o%20de%20Testes%20de%20Desempenho%20com%20a%20Aplica%C3%A7%C3%A3o%20Link%20Extractor.pdf)

Plano detalhado: [`PLANO.md`](PLANO.md)

## O que é

A aplicação Link Extractor (https://github.com/ibnesayeed/linkextractor) tem:

- Front-end web em PHP
- Serviço de extração de links em **duas versões**: Python e Ruby
- Cache Redis (acelera respostas para URLs já vistas)

Aqui geramos carga contra a **API** do extrator (não o front-end) usando
Locust e variamos:

1. **Quantidade de usuários virtuais** — 10 / 50 / 100
2. **Versão do serviço** — Python / Ruby
3. **Modo de cache** — warm (com cache) / cold (sem cache)

Total: **12 cenários**. Cada usuário virtual executa uma sequência de **10
invocações** com URLs diferentes, conforme exigido pelo enunciado.

As métricas (média, mediana, p95, p99, throughput, falhas) saem em CSV pelo
próprio Locust, são consolidadas em `consolidado.xlsx` e plotadas em PNGs
para análise.

## Estrutura do projeto

```
trabalho-4-comp-dist/
├── README.md                    <- este arquivo
├── PLANO.md                     <- plano detalhado de execução
├── docs/
│   ├── Trabalho 4 ... .pdf      <- enunciado original
│   └── cenarios-teste.md        <- descrição dos 12 cenários
├── docker/
│   ├── docker-compose.python.yml  <- stack com API Python (porta 5000)
│   └── docker-compose.ruby.yml    <- stack com API Ruby   (porta 4567)
├── locust/
│   ├── locustfile.py            <- script do usuário virtual (10 invocações)
│   ├── urls.py                  <- as 10 URLs usadas no teste
│   └── requirements.txt
├── scripts/
│   ├── setup.ps1                <- setup único (venv, deps, pull de imagens)
│   ├── start-app.ps1            <- sobe a stack (-Version python|ruby)
│   ├── stop-app.ps1             <- derruba a stack
│   ├── clear-cache.ps1          <- FLUSHALL no Redis
│   ├── run-scenario.ps1         <- roda 1 cenário (-Version -Cache -Users)
│   └── run-all-scenarios.ps1    <- roda os 12 cenários em sequência
├── analysis/
│   ├── analise.ipynb            <- notebook: consolida CSVs + gera planilha + plota gráficos
│   └── requirements.txt
└── results/
    ├── raw/                     <- CSVs brutos do Locust (1 cenário = 4 arquivos)
    ├── processed/               <- consolidado.xlsx
    └── charts/                  <- PNGs com os gráficos
```

## Mapa: PDF → onde está no projeto

Use esta tabela para auditar a cobertura do enunciado.

| Item do PDF | Onde está aqui |
|---|---|
| Aplicação Link Extractor (PHP + API + Redis) | `docker/docker-compose.python.yml`, `docker/docker-compose.ruby.yml` (imagens oficiais `ibnesayeed/linkextractor:*`) |
| Duas versões da API (Python e Ruby) | mesmas duas compose files acima — porta 5000 (Python), 4567 (Ruby) |
| Ferramenta de teste de carga (Locust) | `locust/` |
| Script de configuração do usuário virtual | `locust/locustfile.py` |
| Sequência de **10 invocações** com **URL diferente** em cada uma | `locust/urls.py` (lista das 10) + `ExtractSequence.run_sequence` em `locust/locustfile.py` |
| Variar **quantidade de usuários virtuais** | parâmetro `-Users` em `scripts/run-scenario.ps1` (níveis 10/50/100) |
| Variar **versão do serviço** | parâmetro `-Version python|ruby` em `scripts/run-scenario.ps1` |
| Variar **modo de cache** | parâmetro `-Cache warm|cold` em `scripts/run-scenario.ps1` (env `CACHE_MODE` no Locust) |
| Armazenar métricas (média, mediana, percentis) | CSVs em `results/raw/` → consolidados em `results/processed/consolidado.xlsx` |
| Descrição dos cenários | `docs/cenarios-teste.md` |
| Gráficos dos resultados | `results/charts/*.png` (gerados pelo `analysis/analise.ipynb`) |

## Como rodar (Windows)

### Pré-requisitos (instalar manualmente)

1. **Docker Desktop for Windows** (com WSL2 backend) — https://www.docker.com/products/docker-desktop/
2. **Python 3.11+** — https://www.python.org/downloads/windows/ (marque "Add to PATH")
3. **Git for Windows** — https://git-scm.com/download/win

Abra um **PowerShell** dentro da pasta do projeto.

### 1. Setup único

```powershell
.\scripts\setup.ps1
```

Cria o virtualenv `.venv`, instala Locust + pandas + matplotlib + openpyxl,
e baixa as imagens Docker do Link Extractor.

### 2. Rodar todos os 12 cenários (~30 min)

```powershell
.\scripts\run-all-scenarios.ps1
```

Isso sobe a versão Python, roda os 6 cenários (warm/cold × 10/50/100 usuários),
derruba, sobe a versão Ruby, roda os outros 6, derruba. Os CSVs vão para
`results/raw/`.

Para uma execução mais rápida (smoke test):

```powershell
.\scripts\run-all-scenarios.ps1 -RunTime 30s
```

### 3. Rodar um cenário avulso

```powershell
.\scripts\start-app.ps1   -Version python
.\scripts\run-scenario.ps1 -Version python -Cache warm -Users 50
.\scripts\stop-app.ps1    -Version python
```

### 4. Análise — abrir o notebook

```powershell
.\.venv\Scripts\jupyter.exe lab analysis\analise.ipynb
```

Ou abra `analysis/analise.ipynb` no VSCode (extensão Jupyter). Rode todas
as células ("Run All") — o notebook:

1. Lê os CSVs de `results/raw/`
2. Gera `results/processed/consolidado.xlsx` (abas `resumo` e `series`)
3. Plota e salva os PNGs em `results/charts/`

A seção final do notebook tem espaço para anotar conclusões durante a análise.

Se preferir não usar Jupyter, dá para executar o notebook em modo headless:

```powershell
.\.venv\Scripts\jupyter.exe nbconvert --to notebook --execute analysis\analise.ipynb --inplace
```

## Modo interativo do Locust (opcional)

Se quiser ver a UI web do Locust (gráficos em tempo real):

```powershell
$env:CACHE_MODE = "warm"
.\.venv\Scripts\locust.exe -f locust\locustfile.py --host http://localhost:5000
```

Abra http://localhost:8089 no navegador, defina usuários e spawn rate, e
clique em "Start". Útil para depurar; para coletar dados oficiais use o modo
headless dos scripts acima.

## Solução de problemas

- **`docker: command not found`** — Docker Desktop não iniciou. Abra o app e
  espere o ícone ficar verde.
- **Locust dá erro de conexão** — confira se `start-app.ps1` terminou com
  sucesso. Teste manualmente: `curl "http://localhost:5000/?url=https://example.com/"`.
- **Falhas durante o cenário 100u** — pode ser saturação real da app
  (especialmente Ruby/Sinatra com 100 usuários paralelos). Reporte como
  resultado, não tente "consertar".
- **`FLUSHALL` falhou** — o container `lx-redis` não existe ou não está
  rodando. Confira `docker ps`.
