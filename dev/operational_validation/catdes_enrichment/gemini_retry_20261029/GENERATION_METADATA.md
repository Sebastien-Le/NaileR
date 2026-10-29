# Generation metadata — controlled retry campaign

- Package HEAD: `0497a4539ae3ccc66c6b45ea0e28f7bec201e5ed`
- Provider: `gemini`
- Model: `gemini-2.5-flash`
- `max_output_tokens`: 8192
- `timeout`: 90 seconds
- Backend `max_tries`: 5
- External retry loop: none
- Backoff base/cap: 2 / 16 seconds, with backend jitter
- `Retry-After`: unavailable from the current wrapper
- First pass: generated
- Second pass: generated
- Calls successfully completed: 2
- Retry notices: 0
- Total elapsed time: 67.948 seconds
- API key recorded: no

The previous HTTP 503 campaign is preserved separately in
`../gemini/`. This directory contains only the controlled retry attempt.
