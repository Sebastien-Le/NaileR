# Optional Gemini setup for NaileR development

Gemini generation is an optional external-service workflow. Ordinary package
examples and tests should remain offline and use `generate = FALSE`.

## API key

Obtain an API key through the official provider documentation and keep it in
the user environment, never in the package, a script, a prompt, Git, or a
validation log. See [Google's Gemini API key documentation](https://ai.google.dev/gemini-api/docs/api-key?hl=en).

For a private development session, define `GEMINI_API_KEY` in a personal
`.Renviron` file or in another user-controlled environment file. NaileR's
Gemini wrapper reads `GEMINI_API_KEY`; do not assume that a key configured for
another R project is the intended project key. A project-local `.Renviron`
must be excluded from Git and from package builds. An external file loaded by
`R_ENVIRON_USER` is preferable when several projects use different keys.

Set `R_ENVIRON_USER` before starting R or RStudio, then restart the R process.
Changing the variable after R has started does not retroactively reload the
environment. Avoid `Rscript --vanilla` for sessions that depend on this
loading mechanism.

An offline presence check may report only a boolean:

~~~r
stopifnot(nzchar(Sys.getenv("GEMINI_API_KEY")))
~~~

Never print, partially print, serialize or log the value. A presence check
does not prove that the key has the expected project, quota or permissions.

## Reproducible generation

Use an explicit provider and model, for example `provider = "gemini"` and
`model = "gemini-2.5-flash"`, only in an opt-in generation block. Before a
campaign, run the complete offline preview and record the package commit,
prompt hashes, statistical evidence, model, generation parameters and
responses. Keep `max_tries = 1` when the protocol requires one request per
prompt, and stop on an error rather than silently regenerating a result.

Record external-service use, possible costs, quota errors and privacy
constraints. Do not send private or identifying survey material without an
appropriate authorization. A successful response, or a successful structured
parse, is an operational result and not a scientific validation.

## Git and package hygiene

Before committing, inspect the staged paths and scan reports and logs for
secrets. Do not commit `.Renviron`, API keys, raw private responses or
temporary campaign archives. Keep exact private campaign artifacts outside
the public repository and publish only approved, aggregated or synthetic
material.
