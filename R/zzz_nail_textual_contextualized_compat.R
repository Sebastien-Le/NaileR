# ---------------------------------------------------------------------------
# Compatibility facade for the historical contextualized textual workflow
# ---------------------------------------------------------------------------
#
# This file is deliberately loaded after R/nail_textual_contextualized.R.
# It preserves the historical implementation under an internal name, then
# redefines the public entry point as a thin router:
#
#   modern canonical route:
#     nail_textual_contextualized(catdes = ..., textual = ...)
#       -> nail_catdes_textual(...)
#
#   historical route:
#     all previous arguments
#       -> unchanged historical implementation
#
# The canonical architecture is therefore unique for new workflows, while
# existing user code remains functional during the compatibility period.


if (!exists(
  ".nail_textual_contextualized_legacy",
  inherits = FALSE
)) {
  .nail_textual_contextualized_legacy <-
    nail_textual_contextualized
}


.has_legacy_source_textual_contextualized <- function(group_profile_prep,
                                                       textual_prep,
                                                       representative_verbatims,
                                                       dataset,
                                                       num.var,
                                                       num.text,
                                                       row.w) {
  any(vapply(
    list(
      group_profile_prep,
      textual_prep,
      representative_verbatims,
      dataset,
      num.var,
      num.text,
      row.w
    ),
    function(x) !is.null(x),
    logical(1)
  ))
}


.legacy_options_explicit_textual_contextualized <- function(
    proba_missing,
    sample_text_missing,
    sample_profile_missing,
    profile_mode_missing,
    prompt_style_missing,
    interpretation_mode_missing,
    include_verbatims_missing,
    n_central_missing,
    n_tension_missing,
    max_chars_missing) {

  any(c(
    !proba_missing,
    !sample_text_missing,
    !sample_profile_missing,
    !profile_mode_missing,
    !prompt_style_missing,
    !interpretation_mode_missing,
    !include_verbatims_missing,
    !n_central_missing,
    !n_tension_missing,
    !max_chars_missing
  ))
}


# Public compatibility entry point.
#
# Documentation remains owned temporarily by R/nail_textual_contextualized.R
# during the compatibility period. The canonical public function for new
# workflows is nail_catdes_textual().
nail_textual_contextualized <- function(
    group_profile_prep = NULL,
    textual_prep = NULL,
    representative_verbatims = NULL,
    dataset = NULL,
    num.var = NULL,
    num.text = NULL,
    proba = 0.05,
    sample.pct.text = 1,
    sample.pct.profile = 1,
    profile_mode = c("balanced", "categorical", "quantitative"),
    prompt_style = c("compact", "detailed"),
    interpretation_mode = c("groupwise", "comparative"),
    include_verbatims = TRUE,
    n_central_verbatims = 2,
    n_tension_verbatims = 1,
    max_verbatim_chars = 220,
    introduction = NULL,
    request = NULL,
    conclusion = NULL,
    isolate.groups = FALSE,
    model = "llama3",
    provider = c("ollama", "gemini"),
    row.w = NULL,
    generate = FALSE,
    catdes = NULL,
    textual = NULL,
    ...) {

  # Record whether historical-only tuning arguments were explicitly supplied
  # before evaluating/matching them. This prevents silent ignoring on the
  # canonical route.
  proba_missing <- missing(proba)
  sample_text_missing <- missing(sample.pct.text)
  sample_profile_missing <- missing(sample.pct.profile)
  profile_mode_missing <- missing(profile_mode)
  prompt_style_missing <- missing(prompt_style)
  interpretation_mode_missing <- missing(interpretation_mode)
  include_verbatims_missing <- missing(include_verbatims)
  n_central_missing <- missing(n_central_verbatims)
  n_tension_missing <- missing(n_tension_verbatims)
  max_chars_missing <- missing(max_verbatim_chars)

  modern_requested <- !is.null(catdes) || !is.null(textual)

  if (isTRUE(modern_requested)) {
    if (is.null(catdes) || is.null(textual)) {
      stop(
        paste(
          "For the canonical `nail_textual_contextualized()` route,",
          "`catdes` and `textual` must be supplied together."
        ),
        call. = FALSE
      )
    }

    legacy_source_supplied <-
      .has_legacy_source_textual_contextualized(
        group_profile_prep = group_profile_prep,
        textual_prep = textual_prep,
        representative_verbatims = representative_verbatims,
        dataset = dataset,
        num.var = num.var,
        num.text = num.text,
        row.w = row.w
      )

    legacy_option_supplied <-
      .legacy_options_explicit_textual_contextualized(
        proba_missing = proba_missing,
        sample_text_missing = sample_text_missing,
        sample_profile_missing = sample_profile_missing,
        profile_mode_missing = profile_mode_missing,
        prompt_style_missing = prompt_style_missing,
        interpretation_mode_missing = interpretation_mode_missing,
        include_verbatims_missing = include_verbatims_missing,
        n_central_missing = n_central_missing,
        n_tension_missing = n_tension_missing,
        max_chars_missing = max_chars_missing
      )

    if (isTRUE(legacy_source_supplied) ||
        isTRUE(legacy_option_supplied)) {
      stop(
        paste(
          "Do not mix canonical `catdes`/`textual` inputs with historical",
          "`nail_textual_contextualized()` inputs or tuning arguments.",
          "Use `nail_catdes_textual()` options for the canonical workflow."
        ),
        call. = FALSE
      )
    }

    provider <- match.arg(provider)

    out <- nail_catdes_textual(
      catdes = catdes,
      textual = textual,
      introduction = introduction,
      request = request,
      conclusion = conclusion,
      model = model,
      provider = provider,
      isolate.groups = isolate.groups,
      generate = generate,
      ...
    )

    attr(out, "compatibility_route") <- list(
      entry_point = "nail_textual_contextualized",
      route = "canonical",
      canonical_function = "nail_catdes_textual"
    )

    return(out)
  }

  # Historical route: preserve the previous implementation and its exact
  # argument contract. No new canonical preprocessing is inserted here.
  .nail_textual_contextualized_legacy(
    group_profile_prep = group_profile_prep,
    textual_prep = textual_prep,
    representative_verbatims = representative_verbatims,
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    proba = proba,
    sample.pct.text = sample.pct.text,
    sample.pct.profile = sample.pct.profile,
    profile_mode = profile_mode,
    prompt_style = prompt_style,
    interpretation_mode = interpretation_mode,
    include_verbatims = include_verbatims,
    n_central_verbatims = n_central_verbatims,
    n_tension_verbatims = n_tension_verbatims,
    max_verbatim_chars = max_verbatim_chars,
    introduction = introduction,
    request = request,
    conclusion = conclusion,
    isolate.groups = isolate.groups,
    model = model,
    provider = provider,
    row.w = row.w,
    generate = generate,
    ...
  )
}
