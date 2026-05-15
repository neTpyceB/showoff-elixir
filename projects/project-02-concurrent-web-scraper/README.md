# Concurrent Web Scraper (Elixir)

Terminal utility that:

- fetches many URLs concurrently
- aggregates results
- handles timeouts

## Run

```bash
mix run -e 'ConcurrentWebScraper.CLI.main(["https://example.com", "https://elixir-lang.org"])'
```

## Build executable

```bash
mix escript.build
./concurrent_web_scraper --timeout 3000 --max-concurrency 4 https://example.com https://elixir-lang.org
```
