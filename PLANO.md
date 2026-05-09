# Plano Detalhado — Trabalho 4: Testes de Desempenho com Link Extractor

## 1. Visão geral

Conduzir testes de desempenho contra as duas versões (Python e Ruby) do serviço de
extração de links da aplicação **Link Extractor**, usando **Locust** como ferramenta de
carga em **Windows**. O usuário virtual realiza uma sequência de 10 invocações ao
serviço por iteração, cada uma com uma URL diferente. Vários cenários são
executados variando: (i) número de usuários virtuais; (ii) versão do serviço (Python /
Ruby); (iii) modo de cache (com / sem). As métricas são exportadas pelo próprio
Locust em CSV, consolidadas em uma planilha e plotadas em gráficos comparativos.

Repositório de referência da aplicação:
https://github.com/ibnesayeed/linkextractor

## 2. Mapeamento PDF → Projeto

| Requisito do PDF | Onde está no projeto |
|---|---|
| Aplicação Link Extractor (PHP + API Python/Ruby + Redis) | `docker/` (compose files) e `linkextractor/` (clone do repo) |
| Ferramenta de teste de carga (Locust) e script do usuário virtual | `locust/locustfile.py` |
| Sequência de 10 invocações com URL diferente a cada uma | `locust/urls.py` + `LinkExtractorUser.extract_sequence` |
| Variar quantidade de usuários | parâmetro `-u` em `scripts/run-scenario.ps1` |
| Variar versão (Python / Ruby) | `docker/docker-compose.python.yml` vs `docker/docker-compose.ruby.yml` |
| Variar modo de cache (com / sem) | env `CACHE_MODE=warm` ou `CACHE_MODE=cold` no Locust |
| Armazenar métricas (média, mediana, percentis) | `results/raw/*.csv` (Locust CSV) → `results/processed/consolidado.xlsx` (gerado por `analysis/analise.ipynb`) |
| Gráficos dos resultados | `results/charts/*.png` (gerados por `analysis/analise.ipynb`) |

## 3. Arquitetura da aplicação alvo

```
[Locust] ──HTTP──▶ [API Python ou Ruby] ◀──▶ [Redis]
   ↑                       ↑
   │                       └── porta exposta no host (5000 Python / 4567 Ruby)
   └── roda no host Windows
```

Não testamos o front-end PHP — o PDF pede testes do **serviço de extração de link**,
então o Locust ataca a API diretamente, isolando a variável.

## 4. Estratégia para "com cache" vs "sem cache"

A aplicação usa Redis como cache de URL→links. Para o teste:

- **Com cache (`CACHE_MODE=warm`)**: todos os usuários compartilham o mesmo
  conjunto de 10 URLs (`locust/urls.py`). As primeiras chamadas populam o Redis;
  as seguintes resultam em cache hit. Reflete a operação normal da aplicação.
- **Sem cache (`CACHE_MODE=cold`)**: cada requisição recebe um sufixo de
  query string único (nonce), de modo que a chave no Redis é sempre nova → todas
  as requisições resultam em cache miss. Não exige modificar o código da aplicação
  e dá um piso de comparação claro entre Python e Ruby sem ajuda do cache.

Antes de cada cenário, `scripts/clear-cache.ps1` faz `FLUSHALL` no Redis para
garantir estado limpo.

## 5. Cenários de teste (12 no total)

3 níveis de carga × 2 versões × 2 modos de cache = **12 cenários**.

| #  | Versão | Cache | Usuários | Spawn rate | Duração |
|----|--------|-------|----------|------------|---------|
| 01 | Python | warm  | 10       | 5/s        | 2 min   |
| 02 | Python | warm  | 50       | 10/s       | 2 min   |
| 03 | Python | warm  | 100      | 20/s       | 2 min   |
| 04 | Python | cold  | 10       | 5/s        | 2 min   |
| 05 | Python | cold  | 50       | 10/s       | 2 min   |
| 06 | Python | cold  | 100      | 20/s       | 2 min   |
| 07 | Ruby   | warm  | 10       | 5/s        | 2 min   |
| 08 | Ruby   | warm  | 50       | 10/s       | 2 min   |
| 09 | Ruby   | warm  | 100      | 20/s       | 2 min   |
| 10 | Ruby   | cold  | 10       | 5/s        | 2 min   |
| 11 | Ruby   | cold  | 50       | 10/s       | 2 min   |
| 12 | Ruby   | cold  | 100      | 20/s       | 2 min   |

Tempo total estimado: ~30 min de teste + ~10 min de transições/restarts.

## 6. Métricas coletadas

O Locust em modo headless com `--csv` gera quatro CSVs por execução:
- `*_stats.csv` — agregados por endpoint (count, RPS, mean, median, min, max,
  percentis 50/66/75/80/90/95/98/99/99.9/100, falhas)
- `*_stats_history.csv` — série temporal por intervalo de 1s
- `*_failures.csv` — falhas detalhadas
- `*_exceptions.csv` — exceções no script

Métricas que vão para os gráficos: **média, mediana, p95, p99, throughput (RPS)
e taxa de falha**, conforme pede o PDF ("média, mediana, e percentis do tempo de
resposta").

## 7. Etapas de execução

1. **Setup único** (uma vez): instalar Docker Desktop, Python 3.11+, Git. Rodar
   `scripts/setup.ps1` — clona o linkextractor, cria venv, instala Locust + pandas
   + matplotlib + openpyxl.
2. **Por versão** (Python e depois Ruby):
   1. `scripts/start-app.ps1 -Version python` (ou `ruby`) — sobe os containers.
   2. Para cada nível de carga (10, 50, 100):
      1. `scripts/clear-cache.ps1` (FLUSHALL).
      2. Rodar cenário **warm**: `scripts/run-scenario.ps1 -Version python -Cache warm -Users 10`.
      3. `scripts/clear-cache.ps1` de novo.
      4. Rodar cenário **cold**: `scripts/run-scenario.ps1 -Version python -Cache cold -Users 10`.
   3. `scripts/stop-app.ps1`.
3. **Análise**: abrir `analysis/analise.ipynb` (Jupyter Lab ou VSCode) e rodar
   todas as células. O notebook consolida os CSVs em
   `results/processed/consolidado.xlsx` e gera os PNGs em `results/charts/`.
   Tem uma seção final para anotar observações durante a análise.

Para rodar tudo de uma vez: `scripts/run-all-scenarios.ps1`.

## 8. Riscos e mitigações

- **Aplicação trava sob carga alta**: começamos com 10 usuários e subimos.
  Se 100 falhar, reportamos como achado (capacidade máxima) em vez de tentar
  contornar.
- **Variabilidade de rede para URLs externas**: as URLs do `urls.py` apontam
  para sites estáveis (example.com, wikipedia, etc.). Em caso de instabilidade
  da Internet, o Locust marca como falha e o resultado fica registrado.
- **Diferença de hardware Python vs Ruby**: ambas as imagens rodam no mesmo
  Docker, com os mesmos limites. Não fixamos CPU/memória; documentamos
  `docker stats` durante os testes para registrar consumo.
- **Cache "sem" via nonce não é equivalente a desabilitar cache no código**:
  o overhead do GET/SET no Redis ainda existe em ambos os modos. Limitação
  metodológica a registrar nas observações do notebook.

## 9. Saída final

- `results/processed/consolidado.xlsx` — planilha com aba `resumo` (uma linha
  por cenário, com média/mediana/p95/p99/RPS/falhas) e aba `series` (séries
  temporais).
- `results/charts/*.png` — gráficos comparativos por métrica.
- `analysis/analise.ipynb` — notebook executado com observações finais.
