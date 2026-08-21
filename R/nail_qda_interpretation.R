#' Inspect or revise a QDA product interpretation
#'
#' `nail_qda_interpretation()` provides a simple expert-in-the-loop interface
#' for the reusable product interpretations attached by [nail_qda()].
#'
#' With no `product`, the function returns a compact overview of all product
#' interpretations. With a `product` and no interpretation fields, it returns
#' the retained interpretation for that product. If at least one
#' interpretation field is supplied, the function updates that product
#' interpretation, marks it as expert-retained, and returns the modified QDA
#' object.
#'
#' The function does not call an LLM and does not modify the canonical
#' `product_profiles` evidence. Existing `evidence_ids`, `response_key`, and
#' `raw_block` fields are preserved so the original LLM proposal and its
#' evidence remain inspectable.
#'
#' @param x An object returned by [nail_qda()] containing a
#'   `product_interpretations` attribute.
#' @param product Optional product/stimulus name. If `NULL`, return a compact
#'   overview of all product interpretations.
#' @param core_profile Optional replacement for the concise integrated sensory
#'   profile. A non-empty single character string is required when supplied.
#' @param dominant_configuration Optional replacement for the dominant sensory
#'   configuration. Supply a character vector. Use `character(0)` to clear it.
#' @param secondary_configuration Optional replacement for the secondary sensory
#'   configuration. Supply a character vector. Use `character(0)` to clear it.
#' @param distinctive_interpretation Optional replacement for the concise
#'   sensory distinctiveness statement. Supply `NA_character_` to clear it.
#' @param descriptive_name Optional replacement for the descriptive name.
#'   Supply `NA_character_` to clear it.
#' @param print If `TRUE`, print the requested overview or product
#'   interpretation. When editing, a short confirmation is printed.
#'
#' @return
#' If no interpretation field is supplied, a data frame (overview) or product
#' interpretation list is returned invisibly when `print = TRUE`, and normally
#' when `print = FALSE`.
#'
#' If at least one interpretation field is supplied, the modified QDA object is
#' returned. The edited product receives `status = "available"` and
#' `source = "expert"`.
#'
#' @examples
#' \dontrun{
#' qda <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   isolate.groups = TRUE,
#'   generate = TRUE
#' )
#'
#' nail_qda_interpretation(qda)
#' nail_qda_interpretation(qda, "choc6")
#'
#' qda <- nail_qda_interpretation(
#'   qda,
#'   product = "choc6",
#'   core_profile =
#'     "Crunchy and sweet, with lower melting and acidity.",
#'   dominant_configuration =
#'     c("higher crunchy", "higher sweetness"),
#'   secondary_configuration =
#'     c("lower melting", "lower acidity")
#' )
#' }
#'
#' @export
nail_qda_interpretation <- function(
    x,
    product = NULL,
    core_profile,
    dominant_configuration,
    secondary_configuration,
    distinctive_interpretation,
    descriptive_name,
    print = TRUE) {

  if (!is.logical(print) || length(print) != 1L || is.na(print)) {
    stop("`print` must be TRUE or FALSE.", call. = FALSE)
  }

  interpretations <- attr(
    x,
    "product_interpretations",
    exact = TRUE
  )

  if (is.null(interpretations) ||
      !is.list(interpretations) ||
      !is.list(interpretations$products)) {
    stop(
      paste(
        "`x` does not contain reusable QDA product interpretations.",
        "Run `nail_qda()` with the current QDA implementation first."
      ),
      call. = FALSE
    )
  }

  product_names <- names(interpretations$products)

  if (is.null(product_names) ||
      length(product_names) == 0L ||
      anyNA(product_names) ||
      any(!nzchar(product_names))) {
    stop(
      "The attached QDA product interpretations are invalid or unnamed.",
      call. = FALSE
    )
  }

  editing <- !missing(core_profile) ||
    !missing(dominant_configuration) ||
    !missing(secondary_configuration) ||
    !missing(distinctive_interpretation) ||
    !missing(descriptive_name)

  .return_view <- function(value) {
    if (isTRUE(print)) {
      return(invisible(value))
    }
    value
  }

  .clean_scalar <- function(value,
                            argument,
                            allow_na = FALSE) {
    if (length(value) != 1L || !is.character(value)) {
      stop(
        sprintf(
          "`%s` must be a single character value.",
          argument
        ),
        call. = FALSE
      )
    }

    if (is.na(value)) {
      if (isTRUE(allow_na)) {
        return(NA_character_)
      }

      stop(
        sprintf(
          "`%s` cannot be NA.",
          argument
        ),
        call. = FALSE
      )
    }

    value <- trimws(value)

    if (!nzchar(value)) {
      stop(
        sprintf(
          "`%s` cannot be empty.",
          argument
        ),
        call. = FALSE
      )
    }

    value
  }

  .clean_vector <- function(value,
                            argument) {
    if (!is.character(value)) {
      stop(
        sprintf(
          "`%s` must be a character vector.",
          argument
        ),
        call. = FALSE
      )
    }

    if (length(value) == 0L) {
      return(character(0))
    }

    if (anyNA(value)) {
      stop(
        sprintf(
          "`%s` cannot contain NA values.",
          argument
        ),
        call. = FALSE
      )
    }

    value <- trimws(value)
    value <- value[nzchar(value)]
    unique(value)
  }

  if (is.null(product)) {
    if (isTRUE(editing)) {
      stop(
        "`product` must be supplied when revising an interpretation.",
        call. = FALSE
      )
    }

    overview <- data.frame(
      product = product_names,
      status = vapply(
        interpretations$products,
        function(item) {
          if (is.null(item$status)) NA_character_
          else as.character(item$status)[1L]
        },
        character(1)
      ),
      source = vapply(
        interpretations$products,
        function(item) {
          if (is.null(item$source)) NA_character_
          else as.character(item$source)[1L]
        },
        character(1)
      ),
      core_profile = vapply(
        interpretations$products,
        function(item) {
          value <- item$core_profile
          if (is.null(value) ||
              length(value) == 0L ||
              is.na(value[[1L]]) ||
              !nzchar(trimws(as.character(value[[1L]])))) {
            NA_character_
          } else {
            as.character(value[[1L]])
          }
        },
        character(1)
      ),
      stringsAsFactors = FALSE
    )

    rownames(overview) <- NULL

    if (isTRUE(print)) {
      base::print(
        overview,
        row.names = FALSE,
        right = FALSE
      )
    }

    return(.return_view(overview))
  }

  if (!is.character(product) ||
      length(product) != 1L ||
      is.na(product) ||
      !nzchar(trimws(product))) {
    stop(
      "`product` must be a single non-empty character value.",
      call. = FALSE
    )
  }

  product <- trimws(product)

  if (!product %in% product_names) {
    stop(
      sprintf(
        "Unknown product '%s'. Available products: %s.",
        product,
        paste(product_names, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  item <- interpretations$products[[product]]

  if (!isTRUE(editing)) {
    if (isTRUE(print)) {
      cat(
        "Product: ", product, "\n",
        "Status: ", if (is.null(item$status)) "<unknown>" else item$status, "\n",
        "Source: ", if (is.null(item$source)) "<unknown>" else item$source, "\n",
        "Core profile: ",
        if (is.null(item$core_profile) ||
            length(item$core_profile) == 0L ||
            is.na(item$core_profile[[1L]])) {
          "<not available>"
        } else {
          item$core_profile[[1L]]
        },
        "\n",
        "Dominant configuration: ",
        if (is.null(item$dominant_configuration) ||
            length(item$dominant_configuration) == 0L) {
          "<none>"
        } else {
          paste(item$dominant_configuration, collapse = "; ")
        },
        "\n",
        "Secondary configuration: ",
        if (is.null(item$secondary_configuration) ||
            length(item$secondary_configuration) == 0L) {
          "<none>"
        } else {
          paste(item$secondary_configuration, collapse = "; ")
        },
        "\n",
        "Distinctive interpretation: ",
        if (is.null(item$distinctive_interpretation) ||
            length(item$distinctive_interpretation) == 0L ||
            is.na(item$distinctive_interpretation[[1L]])) {
          "<not available>"
        } else {
          item$distinctive_interpretation[[1L]]
        },
        "\n",
        sep = ""
      )
    }

    return(.return_view(item))
  }

  if (!missing(core_profile)) {
    item$core_profile <- .clean_scalar(
      core_profile,
      "core_profile"
    )
  }

  if (!missing(dominant_configuration)) {
    item$dominant_configuration <- .clean_vector(
      dominant_configuration,
      "dominant_configuration"
    )
  }

  if (!missing(secondary_configuration)) {
    item$secondary_configuration <- .clean_vector(
      secondary_configuration,
      "secondary_configuration"
    )
  }

  if (!missing(distinctive_interpretation)) {
    item$distinctive_interpretation <- .clean_scalar(
      distinctive_interpretation,
      "distinctive_interpretation",
      allow_na = TRUE
    )
  }

  if (!missing(descriptive_name)) {
    item$descriptive_name <- .clean_scalar(
      descriptive_name,
      "descriptive_name",
      allow_na = TRUE
    )
  }

  if (is.null(item$core_profile) ||
      length(item$core_profile) != 1L ||
      is.na(item$core_profile[[1L]]) ||
      !nzchar(trimws(as.character(item$core_profile[[1L]])))) {
    stop(
      paste(
        "An expert-retained interpretation requires a non-empty",
        "`core_profile`. Supply `core_profile` when repairing a failed parse."
      ),
      call. = FALSE
    )
  }

  # Preserve provenance fields from the original LLM proposal.
  item$status <- "available"
  item$source <- "expert"

  interpretations$products[[product]] <- item

  statuses <- vapply(
    interpretations$products,
    function(z) {
      if (is.null(z$status)) NA_character_
      else as.character(z$status)[1L]
    },
    character(1)
  )

  if (is.null(interpretations$metadata) ||
      !is.list(interpretations$metadata)) {
    interpretations$metadata <- list()
  }

  interpretations$metadata$n_available <-
    as.integer(sum(statuses == "available", na.rm = TRUE))
  interpretations$metadata$n_parse_failed <-
    as.integer(sum(statuses == "parse_failed", na.rm = TRUE))
  interpretations$metadata$n_not_generated <-
    as.integer(sum(statuses == "not_generated", na.rm = TRUE))

  attr(x, "product_interpretations") <- interpretations

  if (isTRUE(print)) {
    message(
      sprintf(
        "Updated QDA interpretation for '%s' (source = expert).",
        product
      )
    )
  }

  x
}
