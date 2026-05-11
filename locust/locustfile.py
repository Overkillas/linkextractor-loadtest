"""
Script Locust para o Trabalho 4 — Link Extractor.

Comportamento do usuário virtual (conforme PDF):
- Realiza uma SEQUÊNCIA de 10 invocações ao serviço de extração de link.
- Cada invocação usa uma URL diferente.
- A sequência é repetida durante toda a duração do teste para gerar carga.

Modos de cache (env CACHE_MODE):
- "warm" (com cache): todos os usuários compartilham o mesmo pool de URLs.
  Após as primeiras chamadas o Redis acumula respostas e a maioria das
  requisições passa a ser cache hit.
- "cold" (sem cache): cada requisição recebe um sufixo de query string único,
  forçando cache miss em 100% das chamadas.

Como rodar (modo headless, gerando CSV):
    locust -f locustfile.py --host=http://localhost:5000 \\
           --headless -u 50 -r 10 -t 2m \\
           --csv=../results/raw/python_warm_50u
"""

import os
import uuid
from urllib.parse import quote

from locust import HttpUser, SequentialTaskSet, task, between

from urls import URLS

CACHE_MODE = os.getenv("CACHE_MODE", "warm").lower()
if CACHE_MODE not in ("warm", "cold"):
    raise ValueError(f"CACHE_MODE deve ser 'warm' ou 'cold', recebido: {CACHE_MODE!r}")


def build_target_url(base_url: str, run_id: str, seq: int) -> str:
    """Gera a URL final passada ao serviço de extração.

    No modo cold acrescentamos um nonce que vira parte da chave de cache no
    Redis, garantindo cache miss em toda chamada.
    """
    if CACHE_MODE == "cold":
        sep = "&" if "?" in base_url else "?"
        return f"{base_url}{sep}_n={run_id}-{seq}"
    return base_url


class ExtractSequence(SequentialTaskSet):
    """Uma sequência = 10 invocações com URLs diferentes, na ordem."""

    @task
    def run_sequence(self):
        run_id = uuid.uuid4().hex[:8]
        for seq, base in enumerate(URLS):
            target = build_target_url(base, run_id, seq)
            # A API expõe GET /api/<url>. Codificamos a URL completa para evitar
            # que "://" seja colapsado como barra dupla no caminho HTTP.
            path = f"/api/{quote(target, safe='')}"
            with self.client.get(path, name="/api/extract", catch_response=True) as resp:
                if resp.status_code != 200:
                    resp.failure(f"HTTP {resp.status_code}")


class LinkExtractorUser(HttpUser):
    """Usuário virtual que executa a sequência de 10 invocações em loop."""

    tasks = [ExtractSequence]
    # Pequena pausa entre sequências para emular usuário real, mas baixa o
    # suficiente para manter pressão sobre o serviço sob teste.
    wait_time = between(0.5, 1.5)
