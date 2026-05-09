# Cenários de Teste

Os 12 cenários cobrem o cruzamento das três variáveis exigidas pelo PDF:

- **Quantidade de usuários virtuais**: 10 / 50 / 100
- **Versão do serviço de extração**: Python / Ruby
- **Modo de cache**: warm (com cache) / cold (sem cache)

Cada cenário roda por **2 minutos**, em modo headless do Locust, com spawn rate
proporcional (~1/5 dos usuários por segundo). Cada usuário virtual executa
**sequências de 10 invocações** (uma URL diferente por invocação) repetidamente
durante a janela de 2 minutos.

## Tabela de cenários

| ID  | Versão | Cache | Usuários | Spawn/s | Duração | Tag (prefixo dos CSVs) |
|-----|--------|-------|----------|---------|---------|-----------------------|
| C01 | Python | warm  | 10       | 2       | 2m      | `python_warm_10u_2m`  |
| C02 | Python | warm  | 50       | 10      | 2m      | `python_warm_50u_2m`  |
| C03 | Python | warm  | 100      | 20      | 2m      | `python_warm_100u_2m` |
| C04 | Python | cold  | 10       | 2       | 2m      | `python_cold_10u_2m`  |
| C05 | Python | cold  | 50       | 10      | 2m      | `python_cold_50u_2m`  |
| C06 | Python | cold  | 100      | 20      | 2m      | `python_cold_100u_2m` |
| C07 | Ruby   | warm  | 10       | 2       | 2m      | `ruby_warm_10u_2m`    |
| C08 | Ruby   | warm  | 50       | 10      | 2m      | `ruby_warm_50u_2m`    |
| C09 | Ruby   | warm  | 100      | 20      | 2m      | `ruby_warm_100u_2m`   |
| C10 | Ruby   | cold  | 10       | 2       | 2m      | `ruby_cold_10u_2m`    |
| C11 | Ruby   | cold  | 50       | 10      | 2m      | `ruby_cold_50u_2m`    |
| C12 | Ruby   | cold  | 100      | 20      | 2m      | `ruby_cold_100u_2m`   |

## Como o modo de cache é simulado

A imagem oficial do `linkextractor` sempre conversa com o Redis quando ele está
presente. Em vez de modificar o código da aplicação, controlamos o modo via
chave de cache:

- **warm**: todos os usuários virtuais reutilizam as 10 URLs do `locust/urls.py`.
  Após as primeiras chamadas, o Redis tem os links em cache e a maioria das
  requisições resulta em cache hit. Reflete o comportamento normal da app.
- **cold**: o `locustfile.py` adiciona um nonce único (`?_n=<uuid>-<seq>`) em
  cada URL antes de enviar. Como a chave do cache é a URL inteira, o sufixo
  novo a cada requisição garante 100% de cache miss — equivalente, do ponto
  de vista do extrator, a operar sem cache.

Antes de cada cenário, `scripts/run-scenario.ps1` chama `clear-cache.ps1` que
executa `FLUSHALL` no Redis, partindo de estado limpo.

## Métricas coletadas (por cenário)

O Locust gera quatro CSVs com o prefixo da tag acima:

- `<tag>_stats.csv` — agregados (count, RPS, mean, median, percentis 50/66/75/80/90/95/98/99/99.9/100, min, max, falhas)
- `<tag>_stats_history.csv` — série temporal por intervalo
- `<tag>_failures.csv` — falhas detalhadas
- `<tag>_exceptions.csv` — exceções no script

`analysis/consolidate.py` extrai a linha "Aggregated" de cada `*_stats.csv` e
monta a aba `resumo` em `results/processed/consolidado.xlsx`.
