# ---------------------------------------------------------------------------
# Public evidence accessor
# ---------------------------------------------------------------------------

.nail_evidence_specs <- function() {
  list(
    contextualized_evidence = list(
      attribute = "contextualized_evidence",
      class = "nail_catdes_textual_evidence",
      units = "groups",
      unit_type = "group",
      analysis = "nail_catdes_textual"
    ),
    qda_space_evidence = list(
      attribute = "qda_space_evidence",
      class = "nail_qda_space_evidence",
      units = "axes",
      unit_type = "dimension",
      analysis = "nail_qda_space"
    ),
    frequency_profiles = list(
      attribute = "frequency_profiles",
      class = "nail_descfreq_frequency_profiles",
      units = "rows",
      unit_type = "row",
      analysis = "nail_descfreq"
    ),
    textual_evidence = list(
      attribute = "textual_evidence",
      class = "nail_textual_evidence",
      units = "groups",
      unit_type = "group",
      analysis = "nail_textual"
    ),
    statistical_profiles = list(
      attribute = "statistical_profiles",
      class = "statistical_profiles",
      units = "groups",
      unit_type = "group",
      analysis = "nail_catdes"
    ),
    continuous_profile = list(
      attribute = "continuous_profile",
      class = "nail_condes_continuous_profile",
      units = NULL,
      unit_type = "target",
      analysis = "nail_condes"
    ),
    product_profiles = list(
      attribute = "product_profiles",
      class = "nail_qda_product_profiles",
      units = "products",
      unit_type = "product",
      analysis = "nail_qda"
    )
  )
}


.nail_evidence_extract <- function(x) {
  specs <- .nail_evidence_specs()

  for (name in names(specs)) {
    spec <- specs[[name]]

    if (inherits(x, spec$class)) {
      return(list(
        evidence = x,
        spec = spec,
        source = "direct"
      ))
    }
  }

  for (name in names(specs)) {
    spec <- specs[[name]]
    evidence <- attr(
      x,
      spec$attribute,
      exact = TRUE
    )

    if (is.null(evidence)) {
      next
    }

    if (!inherits(evidence, spec$class)) {
      stop(
        paste0(
          "The stored `", spec$attribute,
          "` artifact is not a valid canonical NaileR evidence object."
        ),
        call. = FALSE
      )
    }

    return(list(
      evidence = evidence,
      spec = spec,
      source = "attribute"
    ))
  }

  stop(
    paste(
      "No canonical NaileR evidence could be found in `x`.",
      "Use a result from a rebuilt evidence-first function such as",
      "`nail_catdes()`, `nail_condes()`, `nail_qda()`, `nail_descfreq()`,",
      "`nail_textual()`, `nail_qda_space()`, or `nail_catdes_textual()`."
    ),
    call. = FALSE
  )
}


.nail_evidence_normalize_select <- function(select) {
  if (is.null(select)) {
    return(NULL)
  }

  if (is.numeric(select) &&
      length(select) == 1L &&
      !is.na(select)) {
    if (select < 1 ||
        !is.finite(select) ||
        select != as.integer(select)) {
      stop(
        "Numeric `select` must be a positive integer.",
        call. = FALSE
      )
    }

    return(as.integer(select))
  }

  if (is.character(select) &&
      length(select) == 1L &&
      !is.na(select) &&
      nzchar(trimws(select))) {
    return(trimws(select))
  }

  stop(
    paste(
      "`select` must be NULL, one non-empty name,",
      "or one positive integer."
    ),
    call. = FALSE
  )
}


.nail_evidence_named_units <- function(evidence,
                                       field,
                                       unit_type) {
  units <- evidence[[field]]

  if (!is.list(units) ||
      length(units) == 0L) {
    stop(
      paste0(
        "The canonical evidence does not contain any ",
        unit_type, " units."
      ),
      call. = FALSE
    )
  }

  unit_names <- names(units)

  if (is.null(unit_names) ||
      anyNA(unit_names) ||
      any(!nzchar(unit_names)) ||
      anyDuplicated(unit_names)) {
    stop(
      paste0(
        "The canonical ", unit_type,
        " evidence units must have unique non-empty names."
      ),
      call. = FALSE
    )
  }

  units
}


.nail_evidence_select_named <- function(evidence,
                                        field,
                                        unit_type,
                                        select) {
  units <- .nail_evidence_named_units(
    evidence = evidence,
    field = field,
    unit_type = unit_type
  )

  if (is.integer(select)) {
    if (select > length(units)) {
      stop(
        sprintf(
          "`select = %d` is out of range; %d %s(s) are available.",
          select,
          length(units),
          unit_type
        ),
        call. = FALSE
      )
    }

    return(list(
      name = names(units)[[select]],
      value = units[[select]]
    ))
  }

  if (!select %in% names(units)) {
    stop(
      paste0(
        "Unknown `select = \"", select, "\"`. Available ",
        unit_type, " names are: ",
        paste(
          sprintf('"%s"', names(units)),
          collapse = ", "
        ),
        "."
      ),
      call. = FALSE
    )
  }

  list(
    name = select,
    value = units[[select]]
  )
}


.nail_evidence_select_textual <- function(evidence,
                                           select) {
  selected <- .nail_evidence_select_named(
    evidence = evidence,
    field = "groups",
    unit_type = "group",
    select = select
  )

  group <- selected$value
  registry <- evidence$text_registry

  if (!is.data.frame(registry) ||
      !all(c(
        "text_id",
        "group",
        "source_row",
        "text"
      ) %in% names(registry))) {
    stop(
      paste(
        "The canonical textual evidence contains an invalid",
        "`text_registry`."
      ),
      call. = FALSE
    )
  }

  ids <- group$text_ids

  if (is.null(ids)) {
    ids <- character(0)
  }

  positions <- match(
    ids,
    registry$text_id
  )

  if (anyNA(positions)) {
    stop(
      paste(
        "The canonical textual evidence is internally inconsistent:",
        "one or more group text IDs are absent from `text_registry`."
      ),
      call. = FALSE
    )
  }

  texts <- if (length(positions) == 0L) {
    registry[
      FALSE,
      c(
        "text_id",
        "group",
        "source_row",
        "text"
      ),
      drop = FALSE
    ]
  } else {
    registry[
      positions,
      c(
        "text_id",
        "group",
        "source_row",
        "text"
      ),
      drop = FALSE
    ]
  }

  rownames(texts) <- NULL

  out <- group
  out$texts <- texts

  class(out) <- c(
    "nail_textual_group_evidence",
    "list"
  )

  out
}


.nail_evidence_select_continuous <- function(evidence,
                                              select) {
  target <- evidence$target

  if (!is.list(target) ||
      is.null(target$variable) ||
      length(target$variable) != 1L ||
      is.na(target$variable) ||
      !nzchar(as.character(target$variable))) {
    stop(
      "The canonical continuous evidence has an invalid target.",
      call. = FALSE
    )
  }

  target_name <- as.character(
    target$variable
  )

  if (is.integer(select)) {
    if (select != 1L) {
      stop(
        paste(
          "`nail_condes()` has one canonical evidence target;",
          "only `select = 1` is valid."
        ),
        call. = FALSE
      )
    }

    return(evidence)
  }

  if (!identical(select, target_name)) {
    stop(
      paste0(
        "Unknown `select = \"", select,
        "\"`. The available target is \"",
        target_name, "\"."
      ),
      call. = FALSE
    )
  }

  evidence
}


.nail_evidence_select <- function(evidence,
                                  spec,
                                  select) {
  select <- .nail_evidence_normalize_select(
    select
  )

  if (is.null(select)) {
    return(evidence)
  }

  if (identical(
    spec$class,
    "nail_condes_continuous_profile"
  )) {
    return(
      .nail_evidence_select_continuous(
        evidence = evidence,
        select = select
      )
    )
  }

  if (identical(
    spec$class,
    "nail_textual_evidence"
  )) {
    return(
      .nail_evidence_select_textual(
        evidence = evidence,
        select = select
      )
    )
  }

  selected <- .nail_evidence_select_named(
    evidence = evidence,
    field = spec$units,
    unit_type = spec$unit_type,
    select = select
  )

  selected$value
}


#' Inspect canonical statistical or textual evidence stored by NaileR
#'
#' `nail_evidence()` provides a stable user-facing accessor to the canonical
#' evidence artifact retained by rebuilt evidence-first NaileR analyses.
#'
#' For primary analyses such as CATDES, CONDES, QDA, and TEXTUAL, this is the
#' complete canonical statistical or textual evidence, not the subset selected
#' for an LLM prompt. For composed analyses such as QDA-space or CATDES+TEXTUAL,
#' the returned artifact is the frozen structured evidence retained at that
#' analytical stage and may explicitly contain upstream model-assisted or
#' expert-edited components. Use [nail_prompt()] to inspect exactly what was
#' shown to the current-stage model, and [nail_response()] to inspect its raw
#' response.
#'
#' The current canonical mappings are:
#'
#' * [nail_catdes()] -> `statistical_profiles`;
#' * [nail_condes()] -> `continuous_profile`;
#' * [nail_qda()] -> `product_profiles`;
#' * [nail_descfreq()] -> `frequency_profiles`;
#' * [nail_textual()] -> `textual_evidence`;
#' * [nail_qda_space()] -> `qda_space_evidence`;
#' * [nail_catdes_textual()] -> `contextualized_evidence`.
#'
#' Direct canonical evidence objects, including the object returned by
#' [nail_catdes_prep()], are also accepted.
#'
#' @param x A rebuilt NaileR analysis result, or a canonical NaileR evidence
#'   object.
#' @param select Optional evidence-unit selector. Use a group name for CATDES
#'   or textual evidence, a product name for QDA evidence, a row name for
#'   DESCFREQ evidence, a dimension name for QDA-space evidence, or a positive
#'   integer position. For CONDES, which has
#'   one target, `select = 1` or the target variable name returns the complete
#'   continuous profile.
#'
#' @return With `select = NULL`, the complete canonical evidence object. With
#'   `select` supplied, the selected group, product, row, or dimension evidence.
#'   For textual evidence, a selected group also contains a `texts` data frame
#'   with the exact registered texts belonging to that group.
#'
#' @details
#' `nail_evidence()` never recomputes an analysis and never calls an LLM. It only
#' reads evidence already stored in `x`.
#'
#' This distinction is intentional:
#'
#' * `nail_evidence(x)` answers "What evidence is retained for this analysis?";
#' * `nail_prompt(x)` answers "What was shown to the current-stage LLM?";
#' * `nail_response(x)` answers "What did that LLM return?".
#'
#' @examples
#' data(iris)
#'
#' catdes_preview <- nail_catdes(
#'   iris,
#'   num.var = 5,
#'   interpretation_mode = "standard",
#'   isolate.groups = TRUE,
#'   generate = FALSE
#' )
#'
#' evidence <- nail_evidence(catdes_preview)
#'
#' setosa <- nail_evidence(
#'   catdes_preview,
#'   select = "setosa"
#' )
#'
#' @export
nail_evidence <- function(x,
                          select = NULL) {
  extracted <- .nail_evidence_extract(x)

  .nail_evidence_select(
    evidence = extracted$evidence,
    spec = extracted$spec,
    select = select
  )
}
