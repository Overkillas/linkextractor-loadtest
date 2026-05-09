"""
Conjunto de 10 URLs usadas pelo usuário virtual.

O PDF exige uma "sequência de 10 invocações ao serviço de extração de link,
passando uma URL diferente como parâmetro a cada invocação". Estas são as 10.

Critérios de escolha:
- Páginas públicas, estáveis e com vários links (HTML real, não SPAs).
- Domínios diferentes — exercita resolução de DNS e TCP do serviço extrator.
- Tamanhos variados (homepages curtas e páginas longas tipo wiki).
"""

URLS = [
    "https://example.com/",
    "https://www.iana.org/",
    "https://www.python.org/",
    "https://www.ruby-lang.org/en/",
    "https://www.wikipedia.org/",
    "https://en.wikipedia.org/wiki/Web_scraping",
    "https://news.ycombinator.com/",
    "https://www.djangoproject.com/",
    "https://flask.palletsprojects.com/",
    "https://redis.io/",
]

assert len(URLS) == 10, "A sequência DEVE ter exatamente 10 URLs (requisito do PDF)."
