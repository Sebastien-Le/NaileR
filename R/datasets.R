
#' Rorschach inkblots
#'
#' This dataset was initially collected to understand the perception of the Rorschach test.
#'
#' @docType data
#'
#' @format
#' A data frame with 600 rows and 5 columns:
#' * The Panel effect (3 panels)
#' * The Inkblot effect (10 inkblots)
#' * The Panelist effect (20 panelists par panel)
#' * The interaction Panel and Panelist
#' * The perception of the inkblot
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(rorschach)
#'
#' ### Example 1: perception of the inkblots for one panel ###
#' intro_rorschach <- "For this study,
#' we asked 20 people to briefly describe
#' the 10 inkblots of the Rorschach test."
#' intro_rorschach <- gsub('\n', ' ', intro_rorschach) |>
#' stringr::str_squish()
#'
#' request_rorschach <- "Based on the comments of the 20 people,
#' please give me a description of each inkblot
#' in terms of how it was perceived. Tell me if it was
#' a rather positive or negative perception."
#' request_rorschach <- gsub('\n', ' ', request_rorschach) |>
#' stringr::str_squish()
#'
#' rorschach_A <- droplevels(rorschach[rorschach$Panel=="A",])
#'
#' res_nail_textual_rorschach <- nail_textual(rorschach_A, num.var = 2,
#'                                            num.text = 5,
#'                                            introduction = intro_rorschach,
#'                                            request = request_rorschach,
#'                                            model = 'llama3',
#'                                            isolate.groups = FALSE,
#'                                            generate = FALSE)
#' res_nail_textual_rorschach |> cat()
#'
#' ppt <- gsub("## Group", "## Inkblot", res_nail_textual_rorschach)
#' ppt |> cat()
#'
#' res_inkblot <- ollamar::generate(model = 'llama3', prompt = ppt,
#'                                  output = "text")
#' res_inkblot |> cat()
#' }
"rorschach"

#' Car seat fabrics
#'
#' This dataset was initially collected to understand the free jar data.
#'
#' @docType data
#'
#' @format
#' A data frame with 567 rows and 4 columns:
#' * The ID of the judge
#' * The product
#' * The reason why the product was liked or disliked
#' * O if the product was disliked, 1 otherwise
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(fabric)
#'
#' intro_car <- "For this consumer study,
#' a car seat fabric was evaluated by consumers.
#' Some of them didn't like it (group '0'),
#' others liked it (group '1'). The consumers
#' gave their reasons for disliking or liking the fabric."
#' intro_car <- gsub('\n', ' ', intro_car) |>
#' stringr::str_squish()
#'
#' request_car <- "Based on the comments provided by the consumers,
#' please explain the reasons why
#' the fabric was not appreciated for group '0',
#' and the reasons why the fabric was appreciated for group '1'.
#' In other words, what are the drivers
#' for disliking and liking this fabric."
#' request_car <- gsub('\n', ' ', request_car) |>
#' stringr::str_squish()
#'
#' fabric_A <- droplevels(fabric[fabric$Fabric=="A",])
#'
#' res_nail_textual_fabric <- nail_textual(fabric_A, num.var = 4,
#'                                         num.text = 3,
#'                                         introduction = intro_car,
#'                                         request = request_car,
#'                                         model = 'llama3',
#'                                         isolate.groups = FALSE,
#'                                         generate = FALSE)
#' res_nail_textual_fabric |> cat()
#'
#' res_nail_textual_fabric <- nail_textual(fabric_A, num.var = 4,
#'                                         num.text = 3,
#'                                         introduction = intro_car,
#'                                         request = request_car,
#'                                         model = 'llama3',
#'                                         isolate.groups = FALSE,
#'                                         generate = TRUE)
#' res_nail_textual_fabric$response |> cat()
#' }
"fabric"

#' Atomic habits survey
#'
#' These data come from a questionnaire about declared capacity to adopt
#' ecological or everyday changes and the perceived restrictiveness of those
#' changes. Ten capability items, ten numeric restrictiveness ratings, ten
#' binary restrictiveness items, ten explanation fields and ten derived
#' combinations are retained. Capability and restrictiveness are reported
#' perceptions, not observations of behaviour.
#'
#' @docType data
#'
#' @format
#' A data frame with 167 rows and 50 columns:
#' * columns 1-10, do you feel able to...
#' * columns 11-20, from 0 to 5 how restrictive...
#' * columns 21-30, is it restrictive, yes or no...
#' * columns 31-40, justify your answers
#' * columns 41-50, a combination of able and restrictive
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' library(FactoMineR)
#' library(NaileR)
#' data(atomic_habit, package = "NaileR")
#'
#' habits_mfa <- FactoMineR::MFA(
#'   atomic_habit[, 1:30],
#'   group = c(10, 10, 10),
#'   type = c("n", "s", "n"),
#'   num.group.sup = 3,
#'   name.group = c("capable", "restrictive", "restrictive binary"),
#'   graph = FALSE
#' )
#' habits_hcpc <- FactoMineR::HCPC(habits_mfa, nb.clust = 3, graph = FALSE)
#' summary(habits_hcpc$data.clust)
#'
#' # One paired capability/explanation question can also be previewed with
#' # the public TEXTUAL API. The full response text is not printed here.
#' habits_textual <- nail_textual(
#'   dataset = atomic_habit,
#'   num.var = 1,
#'   num.text = 31,
#'   introduction = paste(
#'     "This questionnaire records declared capacity and perceived",
#'     "restrictiveness for everyday changes. The selected text column contains",
#'     "participants' explanations associated with one questionnaire item."
#'   ),
#'   request = paste(
#'     "Summarize the recurring and divergent ideas in the responses.",
#'     "Keep reported reasons distinct from observed behaviour and causal claims."
#'   ),
#'   isolate.groups = TRUE,
#'   generate = FALSE
#' )
#' habits_textual_evidence <- nail_evidence(habits_textual)
#' habits_textual_prompt <- nail_prompt(habits_textual, print = FALSE)
#' stopifnot(length(habits_textual_prompt) > 0L)
#'
#' \dontrun{
#' habits_textual_generated <- nail_textual(
#'   dataset = atomic_habit,
#'   num.var = 1,
#'   num.text = 31,
#'   isolate.groups = TRUE,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' nail_response(habits_textual_generated, print = FALSE)
#' }
"atomic_habit"


#' Atomic habits survey
#'
#' People think they need to make big changes to change
#' the course of their lives. But in James Clear's book,
#' Atomic Habits, they will discover that the smallest of changes,
#' coupled with a good knowledge of psychology and neuroscience,
#' can have a revolutionary effect on their lives and relationships.
#' To understand this concept of atomic habits, we interviewed 167 people
#' and asked them if they were able to never take their car alone again,
#' to buy local products...
#' We also asked them how restrictive they found this and why.
#'
#' @docType data
#'
#' @format
#' * column 1, a combination of being able and feeling restrictive
#' * column 2, justify your answer
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#'library(FactoMineR)
#'library(NaileR)
#'library(dplyr)
#'data(car_alone)
#'sampled_car_alone <- car_alone %>%
#'group_by(car_alone_capable_restrictive) %>%
#'sample_frac(0.5)
#'sampled_car_alone <- as.data.frame(sampled_car_alone)
#'
#'intro_car <- "Knowing the impact on the climate,
#'I have made these choices based on
#'the following benefits and constraints..."
#'intro_car <- gsub('\n', ' ', intro_car) |>
#'stringr::str_squish()
#'res_nail_textual <- nail_textual(sampled_car_alone, num.var = 1,
#'                                 num.text = 2,
#'                                 introduction = intro_car,
#'                                 request = NULL,
#'                                 model = 'llama3', isolate.groups = TRUE,
#'                                 generate = TRUE)
#' res_nail_textual[[1]]$response |> cat()
#' res_nail_textual[[3]]$response |> cat()
#' res_nail_textual[[2]]$response |> cat()
#' res_nail_textual[[4]]$response |> cat()
#' }
"car_alone"

#' Atomic habits survey
#'
#' This object adds a three-level classification to the questionnaire data.
#' The labels identify constructed groups and are not substantive names. The
#' C02 statistical preparation uses the first 20 questionnaire variables and
#' this classification; textual and derived columns remain available in the
#' source object but are not treated as independent CATDES evidence.
#'
#' @docType data
#'
#' @format
#' A data frame with 167 rows and 51 columns:
#' * columns 1-10, do you feel able to...
#' * columns 11-20, from 0 to 5 how restrictive...
#' * columns 21-30, is it restrictive, yes or no...
#' * columns 31-40, justify your answers
#' * columns 41-50, a combination of able and restrictive
#' * column 51, the constructed three-level group identifier 'clust'
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' The reproducible C02 preparation is documented at
#' \url{https://github.com/Sebastien-Le/NaileR/tree/dev-core5-condes-integration-20261015/dev/operational_validation/corpus/C02_atomic_habit}.
#' @examples
#' library(NaileR)
#' data(atomic_habit_clust, package = "NaileR")
#'
#' # These are the 20 variables used by the C02 statistical reference plus
#' # the published constructed-group identifier.
#' atomic_habit_statistical <- atomic_habit_clust[, c(1:20, 51)]
#' intro_atomic <- paste(
#'   "The questionnaire records declared capacity and perceived",
#'   "restrictiveness for everyday changes. The groups are constructed from",
#'   "the response data and are identified by their original labels."
#' )
#' request_atomic <- paste(
#'   "Describe the central configuration of the displayed evidence for each",
#'   "constructed group. Preserve the group identifiers, distinguish reported",
#'   "capacity from perceived constraint, and avoid causal or behavioural claims."
#' )
#' atomic_preview <- nail_catdes(
#'   dataset = atomic_habit_statistical,
#'   num.var = ncol(atomic_habit_statistical),
#'   interpretation_mode = "latent",
#'   introduction = intro_atomic,
#'   request = request_atomic,
#'   isolate.groups = FALSE,
#'   drop.negative = FALSE,
#'   generate = FALSE
#' )
#' atomic_evidence <- nail_evidence(atomic_preview)
#' atomic_prompt <- nail_prompt(atomic_preview, print = FALSE)
#' cat(substr(atomic_prompt, 1, 600), "\n")
#'
#' \dontrun{
#' atomic_generated <- nail_catdes(
#'   dataset = atomic_habit_statistical,
#'   num.var = ncol(atomic_habit_statistical),
#'   interpretation_mode = "latent",
#'   introduction = intro_atomic,
#'   request = request_atomic,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' nail_response(atomic_generated, print = FALSE)
#' }
"atomic_habit_clust"

#' QDA sensory evaluations of strawberries
#'
#' A standardized, English-labelled copy of the local strawberry QDA study.
#' The data describe four strawberry products evaluated by a panel over two
#' observed sessions. The labels are retained from the local standardization;
#' uncertain sensory meanings are documented in the validation materials.
#'
#' @docType data
#' @format A data frame with 96 rows and 13 columns. The first three columns
#' are `Product`, `Panelist`, and `Session`; the remaining columns are ten
#' quantitative sensory descriptors covering appearance, odor, texture, taste,
#' and flavor.
#' @details The source contained `NR`, `CJ`, `ProductName`, ten numeric
#' descriptors, and `Commentaire`. The comment field is not part of this QDA
#' dataset. `Session` records the observed repetition. The local English
#' labels are documented translations, not new measurements. The descriptors
#' are `Appearance_Size`, `Appearance_Color`, `Odor_General`,
#' `Texture_Firmness`, `Texture_Juiciness`, `Texture_Melting`,
#' `Taste_Sweetness`, `Taste_Sourness`, `Flavor_Aroma`, and
#' `Flavor_WildStrawberry`. `Texture_Melting` denotes the melting sensation of
#' strawberry flesh in the mouth; `Flavor_Aroma` denotes overall aromatic
#' intensity perceived in the mouth; and `Flavor_WildStrawberry` denotes the
#' intensity of wild-strawberry-like flavor notes. A score of zero indicates
#' that the sensory attribute is absent or not perceived. The upper scale
#' anchor is not documented.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_01/fraise.Rdata`.
#' @examples
#' data(qda_strawberries)
#' dim(qda_strawberries)
#' head(qda_strawberries[, 1:4])
"qda_strawberries"

#' QDA sensory evaluations of apples
#'
#' A standardized, English-labelled copy of the local apple QDA study. Six
#' apple products were evaluated by 22 panelists over two observed sessions.
#' The data preserve the original observation order and numeric measurements;
#' only the product labels and descriptor names were standardized in this
#' distributed copy.
#'
#' @docType data
#' @format A data frame with 264 rows and 27 columns. The first three columns
#' are `Product`, `Panelist`, and `Session`; the remaining columns are 24
#' quantitative sensory descriptors.
#' @details Leading spaces in the original `Renette` and `Golden` modalities
#' were removed in the standardized copy after a collision check. Aromatic
#' descriptors were evaluated in the mouth. The 24 descriptors are:
#' `Appearance_ColorUniformity`, `Appearance_Glossiness`,
#' `Appearance_Spottedness`, `Appearance_Flatness`, `Surface_Smoothness`,
#' `Appearance_Size`, `Odor_Herbaceous`, `Odor_Stuffy`, `Odor_Citrus`,
#' `Texture_Crispness`, `Texture_Firmness`, `Texture_Mealiness`,
#' `Texture_Juiciness`, `Mouthfeel_Astringency`,
#' `Texture_SkinResistance`, `Texture_SkinThickness`, `Taste_Sweetness`,
#' `Taste_Sourness`, `Taste_Bitterness`, `Aroma_Herbal`, `Aroma_Banana`,
#' `Aroma_Candy`, `Aroma_Lemon`, and `Residual_Astringency`.
#'
#' The validated definitions are: `Texture_SkinResistance`, resistance of the
#' apple skin during chewing; `Texture_SkinThickness`, perceived thickness of
#' the apple skin in the mouth; `Odor_Stuffy`, a stuffy or enclosed-air odor;
#' `Residual_Astringency`, a drying or rough sensation in the mouth;
#' `Aroma_Herbal`, an herbaceous aroma reminiscent of grass;
#' `Aroma_Banana`, a banana-like aroma; `Aroma_Candy`, a candy-like aroma with
#' cooked-sugar, sweet, tangy, and fruity notes; and `Aroma_Lemon`, a
#' lemon-like acidic citrus aroma. These correspond respectively to the
#' original labels `peau_t`, `épaisse_t`, `renfermé_o`, `astringent_r`,
#' `herbacé_a`, `banane_a`, `bonbon_a`, and `citron_a`. The remaining labels
#' retain their standardized names without additional definitions beyond the
#' available source documentation.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_02/apples.Rdata`.
#' @examples
#' data(qda_apples)
#' dim(qda_apples)
#' table(qda_apples$Product)
"qda_apples"

#' QDA sensory evaluations of perfumes
#'
#' A standardized UTF-8 copy of a Latin-1 encoded expert perfume QDA study.
#' Twelve commercial products were evaluated by 12 panelists over two sessions.
#'
#' @docType data
#' @format A data frame with 288 rows and 15 columns. The first three columns
#' are `Product`, `Panelist`, and `Session`; the remaining columns are 12
#' quantitative odor descriptors.
#' @details The source `Rank` column is not included in the QDA descriptors.
#' Product names, including the accented commercial product name in the source,
#' are preserved. The 12 descriptors are `Odor_Spicy`, `Odor_Heady`,
#' `Odor_Fruity`, `Odor_Green`, `Odor_Vanilla`, `Odor_Floral`, `Odor_Woody`,
#' `Odor_Citrus`, `Odor_Marine`, `Odor_Gourmand`, `Odor_Oriental`, and
#' `Odor_Enveloping`. `Odor_Gourmand` denotes a gourmand odor character,
#' evoking sweet, confectionery, or food-like notes. `Odor_Oriental` denotes
#' an oriental/amber fragrance character, preserving the terminology of the
#' original study. `Odor_Enveloping` denotes an enveloping, surrounding
#' quality of the fragrance. A score of zero indicates that the sensory
#' attribute is absent or not perceived. The upper scale anchor is not
#' documented.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_04/perfumes_qda_experts.csv`.
#' @examples
#' data(qda_perfumes)
#' dim(qda_perfumes)
#' unique(qda_perfumes$Product)
"qda_perfumes"

#' QDA sensory evaluations of melons
#'
#' A standardized, English-labelled copy of the local melon QDA study. Six
#' melon products were evaluated by 12 judges. No observed session or
#' repetition field is present, so no `Session` column was created.
#'
#' @docType data
#' @format A data frame with 72 rows and 12 columns. The first two columns are
#' `Product` and `Panelist`; the remaining columns are ten quantitative sensory
#' descriptors covering mouthfeel, odor, and texture.
#' @details The source `Smp.code` column is excluded from the QDA dataset. The
#' standardized product identifiers are `DAI`, `DHL`, `HL`, `KS`, `TAKI`, and
#' `TL3`. The descriptors are `Mouthfeel_Bitterness`,
#' `Mouthfeel_Sourness`, `Mouthfeel_Sweetness`, `Odor_Floral`,
#' `Odor_GreenGrass`, `Odor_RipeBanana`, `Odor_SweetNote`,
#' `Texture_Crispness`, `Texture_Firmness`, and `Texture_Juiciness`.
#' `Odor_SweetNote` denotes a sweet-smelling odor note, distinct from sweet
#' taste. `Texture_Crispness` denotes the crisp or crunchy texture of melon
#' flesh and corresponds to the original French descriptor "croquant". A
#' score of zero indicates that the sensory attribute is absent or not
#' perceived. The upper scale anchor is not documented.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_03/melons.Rdata`.
#' @examples
#' data(qda_melons)
#' dim(qda_melons)
#' table(qda_melons$Product)
"qda_melons"


#' Beard descriptions
#'
#' These data refer to 8 types of beards.
#' Each beard was evaluated by 62 assessors (except beard 8 which only had 60 evaluations).
#'
#' @docType data
#'
#' @format
#' A data frame with 494 rows and 2 columns:
#' * the types of beards;
#' * the words used to describe them.
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' data(beard)
#' beard[1:8,]
#' }
"beard"


#' Beard descriptions
#'
#' These data refer to 8 types of beards.
#' Each beard was evaluated by 62 assessors (except beard 8 which only had 60 evaluations).
#'
#' @docType data
#'
#' @format
#' A contingency table (data frame) with 8 rows and 337 columns:
#' * rows are the types of beards;
#' * columns are the words used at least once to describe them.
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(beard_cont)
#'
#' FactoMineR::descfreq(beard_cont)
#'
#' intro_beard <- 'A survey was conducted about beards
#' and 8 types of beards were described.
#' In the data that follow, beards are named B1 to B8.'
#' intro_beard <- gsub('\n', ' ', intro_beard) |>
#' stringr::str_squish()
#'
#' req_beard <- 'Please give a name to each beard
#' and summarize what makes this beard unique.'
#' req_beard <- gsub('\n', ' ', req_beard) |>
#' stringr::str_squish()
#'
#' res_beard <- nail_descfreq(beard_cont,
#' introduction = intro_beard,
#' request = req_beard)
#' res_beard
#' }
"beard_cont"


#' Beard descriptions
#'
#' These data refer to 8 types of beards. They come from a subset of the original "beard" dataset.
#' Each beard was evaluated by 62 assessors (except beard 8 which only had 60 evaluations).
#'
#' @docType data
#'
#' @format
#' A data frame with 8 rows and 24 columns:
#' * rows are the types of beards;
#' * columns are the assessors' opinions.
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(beard_wide)
#'
#' intro_beard <- "As a barber, you make
#' recommendations based on consumers comments.
#' Examples of consumers descriptions of beards
#' are as follows."
#' intro_beard <- gsub('\n', ' ', intro_beard) |>
#' stringr::str_squish()
#'
#' res <- nail_sort(beard_wide[,1:5], name_size = 3,
#' stimulus_id = "beard", introduction = intro_beard,
#' measure = 'the description was')
#' res$prompt_llm[[1]] |> cat()
#' }
"beard_wide"


#' Local food systems survey
#'
#' These data were collected after a Q-method-like survey on sustainable food systems.
#' Participants rated the acceptability of 45 statements about a sustainable
#' food system and then answered 14 additional opinion statements. The
#' distributed object contains the original participant-level factor responses
#' and four contextual variables. The object `mashs_food_system` represents
#' the same survey in a different preparation: it retains the 59 response
#' variables, `Age`, and a four-group constructed classification. The two
#' objects are complementary teaching resources, not interchangeable exports.
#'
#' @docType data
#'
#' @format
#' A data frame with 573 rows (participants) and 63 columns (questions):
#' * columns 1-45 statements about food systems
#' * columns 46-59 opinions
#' * columns 60-63 contextual variables (`Age`, marital status, city size and
#'   socio-professional category)
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' The reproducible C01 validation record is maintained in the repository at
#' \url{https://github.com/Sebastien-Le/NaileR/tree/dev-core5-condes-integration-20261015/dev/operational_validation/corpus/C01_local_food}.
#' @examples
#' library(FactoMineR)
#' library(NaileR)
#' data(local_food, package = "NaileR")
#'
#' # The C01 preparation uses the first 45 statements as active variables and
#' # columns 46:63 as supplementary/contextual variables. ncp = 100 is kept
#' # here to make the preparation comparable with that validation case.
#' food_mca <- FactoMineR::MCA(
#'   local_food,
#'   quali.sup = 46:63,
#'   ncp = 100,
#'   level.ventil = 0.05,
#'   graph = FALSE
#' )
#' food_hcpc <- FactoMineR::HCPC(food_mca, nb.clust = 3, graph = FALSE)
#' food_profiles <- food_hcpc$data.clust
#'
#' intro_food <- paste(
#'   "This study concerns declared views about sustainable food systems.",
#'   "Participants rated the acceptability of statements about what a food",
#'   "system could be, then answered additional opinion statements.",
#'   "The groups are statistical profiles of these responses, not observed",
#'   "behavioural types or causal explanations."
#' )
#' request_food <- paste(
#'   "Describe the central configuration of evidence for each group.",
#'   "Use the displayed statistical characteristics as the factual basis,",
#'   "distinguish observations from interpretation, and propose a concise",
#'   "descriptive label without ranking the groups."
#' )
#' food_preview <- nail_catdes(
#'   dataset = food_profiles,
#'   num.var = ncol(food_profiles),
#'   introduction = intro_food,
#'   request = request_food,
#'   isolate.groups = TRUE,
#'   drop.negative = TRUE,
#'   generate = FALSE
#' )
#' food_evidence <- nail_evidence(food_preview)
#' food_prompts <- nail_prompt(food_preview, print = FALSE)
#' cat(substr(unname(food_prompts)[[1L]], 1, 600), "\n")
#'
#' # C01 reports and aggregate controls are maintained in the repository
#' # validation corpus. The following optional generation is never run by
#' # package checks.
#' \dontrun{
#' food_generated <- nail_catdes(
#'   dataset = food_profiles,
#'   num.var = ncol(food_profiles),
#'   introduction = intro_food,
#'   request = request_food,
#'   isolate.groups = TRUE,
#'   drop.negative = TRUE,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' nail_response(food_generated, print = FALSE)
#' }
"local_food"


#' Ideal boss survey
#'
#' These data were collected after a Q-method-like survey on participants' perception of an "ideal boss".
#' Participants had to rank how much they agreed with 30 statements about an ideal boss; then, they were asked personal questions.
#'
#' @docType data
#'
#' @format
#' A data frame with 73 rows (participants) and 39 columns (questions):
#' * columns 1-30: statements about the ideal boss
#' * columns 31-39: personal information
#' @source Florian LECLERE and Marianne ANDRE, students at l'Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(FactoMineR)
#' library(NaileR)
#' data(boss)
#' res_mca_boss <- MCA(boss, quali.sup = 31:39,
#' ncp = 30, level.ventil = 0.05, graph = FALSE)
#' res_hcpc_boss <- HCPC(res_mca_boss, nb.clust = 4, graph = FALSE)
#' don_clust_boss <- res_hcpc_boss$data.clust
#'
#' intro_boss <- 'A study on "the ideal boss" was led on 73 participants.
#' The study had 2 parts. In the first part,
#' participants were given statements about the ideal boss
#' (starting with "My ideal boss...").
#' They had to rate, on a scale from 1 to 5,
#' how much they agreed with the statements;
#' 1 being "Strongly disagree", 3 being "neutral"
#' and 5 being "Strongly agree".
#' In the second part, they were asked for personal information:
#' work experience, age, etc.
#' Participants were then split into groups based on their answers.'
#' intro_boss <- gsub('\n', ' ', intro_boss) |>
#' stringr::str_squish()
#'
#' req_boss <- "Please describe, for each group, their ideal boss.
#' Then, give each group a new name, based on your conclusions."
#' req_boss <- gsub('\n', ' ', req_boss) |>
#' stringr::str_squish()
#'
#'
#' res_boss <- nail_catdes(don_clust_boss, num.var = 40,
#' introduction = intro_boss, request = req_boss,
#' isolate.groups = FALSE, drop.negative = TRUE)
#' res_boss |> cat()
#' }
"boss"


#' Agribusiness studies survey
#'
#' These data were collected after a Q-method-like survey on students' expectations of agribusiness studies.
#' Participants had to rank how much they agreed with 38 statements about possible benefits from agribusiness studies; then, they were asked personal questions.
#'
#' @docType data
#'
#' @format
#' A data frame with 53 rows (participants) and 42 columns (questions):
#' * columns 1-38: statements about agribusiness studies
#' * columns 39-42: personal information
#' @source Juliette LE COLLONNIER and Lou ROBERT, students at l'Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(agri_studies)
#'
#' res_mca_agri <- FactoMineR::MCA(agri_studies, quali.sup = 39:42,
#' level.ventil = 0.05, graph = FALSE)
#' agri_work <- res_mca_agri$ind$coord |> as.data.frame()
#' agri_work <- agri_work[,1] |> cbind(agri_studies)
#'
#' intro_agri <- "These data were collected after a survey
#' on students' expectations of agribusiness studies.
#' Participants had to rank how much they agreed with 38 statements
#' about possible benefits from agribusiness studies;
#' then, they were asked personal questions."
#' intro_agri <- gsub('\n', ' ', intro_agri) |>
#' stringr::str_squish()
#'
#' res_agri <- nail_condes(agri_work, num.var = 1,
#' introduction = intro_agri)
#' res_agri
#' }
"agri_studies"


#' Glossophobia survey
#'
#' These data were collected after a Q-method-like survey on participants' feelings about speaking in public.
#' Participants had to rank how much they agreed with 25 descriptions of speaking in public; then, they were asked personal questions.
#'
#' @docType data
#'
#' @format
#' A data frame with 139 rows (participants) and 41 columns (questions):
#' * columns 1-25: descriptions of speaking in public
#' * columns 26-41: personal information
#' @source Elina BIAU and Théo LEDAIN, students at l'Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(glossophobia)
#'
#' res_mca_phobia <- FactoMineR::MCA(glossophobia, quali.sup = 26:41,
#' level.ventil = 0.05, graph = FALSE)
#' phobia_work <- res_mca_phobia$ind$coord |> as.data.frame()
#' phobia_work <- phobia_work[,1] |> cbind(glossophobia)
#'
#' intro_phobia <- "These data were collected after a survey
#' on participants' feelings about speaking in public.
#' Participants had to rank how much they agreed with
#' 25 descriptions of speaking in public;
#' then, they were asked personal questions."
#' intro_phobia <- gsub('\n', ' ', intro_phobia) |>
#' stringr::str_squish()
#'
#' res_phobia <- nail_condes(phobia_work, num.var = 1,
#' introduction = intro_phobia)
#' res_phobia
#' }
"glossophobia"


#' Food waste survey
#'
#' These data were collected after a survey on food waste. They combine
#' questions about perceived impact, disposal practices, reasons, information
#' and contextual variables. The answers are self-reports and must not be read
#' as direct measurements of observed waste.
#'
#' @docType data
#'
#' @format
#' A data frame with 180 rows (participants) and 77 columns (questions).
#'
#' @source Héloïse BILLES and Amélie RATEAU, students at l'Institut Agro Rennes-Angers
#' @examples
#' library(NaileR)
#' library(FactoMineR)
#' data(waste, package = "NaileR")
#'
#' # Item 14 is constant in the distributed table and is removed only for
#' # this historical MCA preparation.
#' waste_active <- waste[, -14, drop = FALSE]
#' waste_mca <- FactoMineR::MCA(
#'   waste_active,
#'   quali.sup = c(1, 2, 50:76),
#'   ncp = 35,
#'   level.ventil = 0.05,
#'   graph = FALSE
#' )
#' waste_hcpc <- FactoMineR::HCPC(waste_mca, nb.clust = 3, graph = FALSE)
#' waste_profiles <- waste_hcpc$data.clust
#'
#' intro_waste <- paste(
#'   "This study describes self-reported views and practices related to food",
#'   "waste, including disposal, information and possible reasons.",
#'   "The groups are statistical profiles of the questionnaire responses;",
#'   "they are not direct measurements of quantities wasted."
#' )
#' request_waste <- paste(
#'   "Summarize the main coherent configuration of evidence for each group.",
#'   "Propose a descriptive label grounded in the displayed characteristics.",
#'   "Do not assign a normative score, infer unobserved behaviour, or claim",
#'   "causal explanations."
#' )
#' waste_preview <- nail_catdes(
#'   dataset = waste_profiles,
#'   num.var = ncol(waste_profiles),
#'   introduction = intro_waste,
#'   request = request_waste,
#'   drop.negative = TRUE,
#'   generate = FALSE
#' )
#' waste_evidence <- nail_evidence(waste_preview)
#' waste_prompt <- nail_prompt(waste_preview, print = FALSE)
#' cat(substr(waste_prompt, 1, 600), "\n")
#'
#' \dontrun{
#' waste_generated <- nail_catdes(
#'   dataset = waste_profiles,
#'   num.var = ncol(waste_profiles),
#'   introduction = intro_waste,
#'   request = request_waste,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' nail_response(waste_generated, print = FALSE)
#' }
"waste"


#' Perception of food quality
#'
#' These data were collected after a study on the perception of food quality.
#' Participants rated nine food-related logos from 0 (not at all) to 10
#' (absolutely) according to how much a product bearing each logo matched
#' their own perception of quality. The scores describe perceived associations,
#' not an objective or normative quality scale.
#'
#' @docType data
#'
#' @format
#' A data frame with 55 rows and 9 columns. Here is the list of logos:
#' * AB: organic;
#' * Label Rouge: superior quality (from the taste, process, packaging...);
#' * FairTrade: decent wages and working conditions for the producers;
#' * Bleu Blanc Coeur: diverse and balanced diet for the livestock;
#' * AOC: controlled designation of origin;
#' * Produit en Bretagne: processed in Brittany;
#' * Viandes de France: livestock bred, grown and slaughtered in France, with respectful living conditions;
#' * Nourri sans OGM: no GMOs in livestock food;
#' * Médailles Agro: a prize won at a yearly contest based on taste.
#' @source Sébastien Lê, applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' library(NaileR)
#' data(quality, package = "NaileR")
#'
#' quality_pca <- FactoMineR::PCA(quality, graph = FALSE)
#' quality_work <- data.frame(
#'   Dim1 = quality_pca$ind$coord[, 1],
#'   quality,
#'   check.names = FALSE
#' )
#' intro_quality <- paste(
#'   "Students rated nine food-related logos from 0 to 10 according to how",
#'   "much each logo matched their perception of food quality.",
#'   "The target below is the first PCA dimension, so it is a constructed",
#'   "continuum rather than an observed quality measurement."
#' )
#' request_quality <- paste(
#'   "Describe the configuration of logo associations along this dimension.",
#'   "Distinguish statistical description from interpretation and do not turn",
#'   "the dimension into a normative ranking of products or people."
#' )
#' quality_preview <- nail_condes(
#'   dataset = quality_work,
#'   num.var = 1,
#'   interpretation_mode = "latent",
#'   target_label = "first PCA dimension",
#'   introduction = intro_quality,
#'   request = request_quality,
#'   generate = FALSE
#' )
#' quality_evidence <- nail_evidence(quality_preview)
#' quality_prompt <- nail_prompt(quality_preview, print = FALSE)
#' cat(substr(quality_prompt, 1, 600), "\n")
#'
#' \dontrun{
#' quality_generated <- nail_condes(
#'   dataset = quality_work,
#'   num.var = 1,
#'   interpretation_mode = "latent",
#'   target_label = "first PCA dimension",
#'   introduction = intro_quality,
#'   request = request_quality,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' nail_response(quality_generated, print = FALSE)
#' }
"quality"


#' Nutri-score survey
#'
#' These data were collected after a survey on the Nutri-Score. The first
#' 16 variables concern perceptions and uses of the label; later variables
#' describe eating practices and contextual information. The answers are
#' self-reports and should not be treated as observed dietary behaviour.
#'
#' @docType data
#'
#' @format
#' A data frame with 112 rows (participants) and 36 columns (questions).
#'
#' @source Anaëlle YANNIC and Jessie PICOT, students at l'Institut Agro Rennes-Angers
#' @examples
#' library(NaileR)
#' library(FactoMineR)
#' data(nutriscore, package = "NaileR")
#'
#' nutri_mca <- FactoMineR::MCA(
#'   nutriscore,
#'   quali.sup = 17:36,
#'   ncp = 15,
#'   level.ventil = 0.05,
#'   graph = FALSE
#' )
#' nutri_hcpc <- FactoMineR::HCPC(nutri_mca, nb.clust = 3, graph = FALSE)
#' nutri_profiles <- nutri_hcpc$data.clust
#' intro_nutri <- paste(
#'   "This survey concerns perceptions and uses of the Nutri-Score label.",
#'   "The first block contains label-related answers and the remaining",
#'   "variables provide eating-practice or contextual information.",
#'   "Groups summarize response configurations and are not dietary diagnoses."
#' )
#' request_nutri <- paste(
#'   "Describe the main coherent configuration of evidence for each group.",
#'   "Propose a concise descriptive label and keep perceptions distinct from",
#'   "reported practices. Do not infer causes or rank participants."
#' )
#' nutri_preview <- nail_catdes(
#'   dataset = nutri_profiles,
#'   num.var = ncol(nutri_profiles),
#'   introduction = intro_nutri,
#'   request = request_nutri,
#'   drop.negative = TRUE,
#'   generate = FALSE
#' )
#' nutri_evidence <- nail_evidence(nutri_preview)
#' nutri_prompt <- nail_prompt(nutri_preview, print = FALSE)
#' cat(substr(nutri_prompt, 1, 600), "\n")
#'
#' \dontrun{
#' nutri_generated <- nail_catdes(
#'   dataset = nutri_profiles,
#'   num.var = ncol(nutri_profiles),
#'   introduction = intro_nutri,
#'   request = request_nutri,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' nail_response(nutri_generated, print = FALSE)
#' }
"nutriscore"


#' Ideal food-system questionnaire from the MASHS Q-sort study
#'
#' These data come from the 2023--2024 MASHS study of opinions about an ideal
#' food system. The study used a Q-sort-like questionnaire protocol. The
#' statistical analysis retained for this object was an MCA followed by HCPC,
#' not a classical Q-method factor extraction.
#'
#' @docType data
#'
#' @format
#' A data frame with 573 rows and 61 columns. Columns 1--59 are categorical
#' questionnaire responses, column 60 is the retained `Age` variable, and the
#' last column, `clust`, is the retained four-level constructed group
#' identifier.
#'
#' @details
#' The source analysis used the first 45 questionnaire variables as active MCA
#' variables and columns 46--60 as supplementary or contextual variables.
#' `Age` is retained because it was part of the frozen source table; the other
#' three contextual variables distributed in `local_food` are omitted here.
#' The group labels remain numeric identifiers and are not substantive names.
#' The four group sizes are 226, 113, 116 and 118. The data describe reported
#' opinions about an ideal food system; they do not measure observed behaviour
#' or causal effects. Unlike `local_food`, this object includes a retained
#' four-group classification, whereas the C01 `local_food` example constructs
#' a three-group HCPC classification for teaching purposes.
#'
#' @source Local MASHS research export, de-identified from
#' `don_clust.rData`. The reconstruction script is documented in
#' `dev/transition_reconstruction/build_mashs_irtsat_data.R`.
#' @examples
#' library(NaileR)
#' data(mashs_food_system, package = "NaileR")
#'
#' mashs_preview <- nail_catdes(
#'   dataset = mashs_food_system,
#'   num.var = ncol(mashs_food_system),
#'   interpretation_mode = "latent",
#'   introduction = paste(
#'     "This survey concerns opinions about an ideal food system.",
#'     "The groups are constructed from questionnaire response patterns",
#'     "using the retained MCA-HCPC analysis."
#'   ),
#'   request = paste(
#'     "Describe the configuration of the selected response evidence for",
#'     "each group. Preserve the group identifiers and distinguish reported",
#'     "opinions from observed practices or causal explanations."
#'   ),
#'   generate = FALSE
#' )
#' mashs_evidence <- nail_evidence(mashs_preview)
#' mashs_prompt <- nail_prompt(mashs_preview, print = FALSE)
#' cat(substr(mashs_prompt, 1, 600), "\n")
"mashs_food_system"


#' IRTSAT 2024--2025 local-food profiles
#'
#' A de-identified frozen export from the 2024--2025 IRTSAT survey on local
#' food practices and representations. It contains an IRT score, categorical
#' descriptors, and the retained four-level profile identifiers.
#'
#' @docType data
#'
#' @format
#' A data frame with 529 rows and 36 columns. `IRT_score` is the numeric
#' target score. Columns 2--35 are categorical descriptors and `profile` is
#' the four-level constructed profile identifier.
#'
#' @details
#' The visible historical script `analyse_irt_multidim.Rmd` uses a three-centre
#' k-means illustration and is not the final four-profile classification.
#' This object preserves the frozen four-profile assignment from the retained
#' IRT workspace. The score and descriptors are aligned by their original row
#' order; no personal identifier is distributed. The distributed table has
#' 529 observations and no missing values. The score is a retained analysis
#' result and is not recomputed by the package. The current profile levels are
#' preserved as identifiers; the four historical names are documented
#' separately and are not used here to assert a verified code-to-name mapping.
#' The 48-item questionnaire export is available separately as
#' `irtsat_items_2024_2025`; it has 541 rows and must not be joined to this
#' table by row order.
#'
#' @source Local IRTSAT research workspace, de-identified from the frozen
#' `dta_gold` and `theta` objects. The reconstruction script is documented in
#' `dev/transition_reconstruction/build_mashs_irtsat_data.R`.
#' @examples
#' library(NaileR)
#' data(irtsat_2024_2025, package = "NaileR")
#'
#' irtsat_catdes <- nail_catdes(
#'   dataset = irtsat_2024_2025,
#'   num.var = ncol(irtsat_2024_2025),
#'   interpretation_mode = "latent",
#'   introduction = paste(
#'     "This survey describes reported relationships with local food.",
#'     "The profile variable is a retained four-group classification linked",
#'     "to an IRT score and categorical descriptors."
#'   ),
#'   request = paste(
#'     "Describe the configuration of evidence associated with each profile.",
#'     "Keep the profile identifiers, distinguish the IRT score from its",
#'     "descriptors, and do not infer behaviour or causality."
#'   ),
#'   generate = FALSE
#' )
#' irtsat_evidence <- nail_evidence(irtsat_catdes)
#' irtsat_prompt <- nail_prompt(irtsat_catdes, print = FALSE)
#' cat(substr(irtsat_prompt, 1, 600), "\n")
#'
#' # CONDES can characterize the score without using the profile assignment
#' # as a circular descriptor.
#' irtsat_condes_data <- irtsat_2024_2025[, -ncol(irtsat_2024_2025)]
#' irtsat_condes <- nail_condes(
#'   dataset = irtsat_condes_data,
#'   num.var = 1,
#'   interpretation_mode = "latent",
#'   generate = FALSE
#' )
#' nail_evidence(irtsat_condes)
"irtsat_2024_2025"


#' IRTSAT 48-item local-food instrument
#'
#' This object contains the 48 Likert assertions used in the IRTSAT
#' questionnaire. The variable names and response levels are provided in
#' English for use in NaileR examples. The original French item wording is
#' preserved in the accompanying dictionary because it is part of the
#' instrument documentation.
#'
#' @docType data
#'
#' @format
#' A data frame with 541 rows and 48 ordered factor columns. The columns are
#' arranged in six blocks of eight items: geographical origin, procurement
#' modes, local territory and actors, environment and ecology, accessibility
#' and social justice, and engagement and civic participation. The response
#' levels are `Strongly disagree`, `Disagree`, `Neither agree nor disagree`,
#' `Agree`, and `Strongly agree`. There are 14 missing item responses.
#'
#' @details
#' This item-level export is intentionally separate from
#' `irtsat_2024_2025`, the frozen 529-row profile table. No validated row key
#' links the two exports, so this object must not be joined to the profile
#' table by row order. Timestamp, region and complementary questionnaire
#' fields are excluded from the distributed object. The original assertions
#' are French questionnaire wording; the English variable names and response
#' levels are a documented presentation layer, not a new instrument.
#'
#' @source
#' IRTSAT `data_541.csv` and `typologie_consommateurs_annexe.docx`. The
#' English variable dictionary is
#' `dev/transition_reconstruction/IRTSAT_48_ITEMS_DICTIONARY.csv`.
#' @examples
#' library(NaileR)
#' data(irtsat_items_2024_2025, package = "NaileR")
#'
#' dim(irtsat_items_2024_2025)
#' table(irtsat_items_2024_2025[[1]], useNA = "ifany")
#' names(irtsat_items_2024_2025)[1:8]
#'
#' # The item table has no classification or score and is therefore inspected
#' # as an instrument; it is not passed to nail_catdes() without an external,
#' # documented grouping variable.
"irtsat_items_2024_2025"
