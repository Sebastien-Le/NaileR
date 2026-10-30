
#' Rorschach inkblot descriptions
#'
#' This data frame contains free-text descriptions of ten Rorschach inkblots
#' collected from three panels. It can be used to study recurring descriptions
#' without treating them as measures of personality or perception ability.
#'
#' @docType data
#'
#' @format
#' A data frame with 600 rows and 5 columns:
#' * `Panel`: panel identifier (`A`, `B`, or `C`);
#' * `Inkblot`: inkblot identifier (10 inkblots);
#' * `Panelist`: panelist identifier (20 panelists per panel);
#' * `Consumer`: panel-by-panelist identifier; and
#' * `Description`: the participant's free-text description.
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' library(NaileR)
#' data(rorschach, package = "NaileR")
#'
#' ### Example 1: perception of the inkblots for one panel ###
#' intro_rorschach <- paste(
#'   "For this study, 20 people briefly described the 10 inkblots",
#'   "in each of three panels. This preview uses panel A."
#' )
#'
#' request_rorschach <- paste(
#'   "Describe recurring perceptions of each inkblot from the displayed",
#'   "responses. Preserve variation in the descriptions and do not infer",
#'   "personality, causes or positive/negative attitudes unless stated."
#' )
#'
#' rorschach_A <- droplevels(rorschach[rorschach$Panel=="A",])
#'
#' res_nail_textual_rorschach <- nail_textual(
#'   rorschach_A,
#'   num.var = 2,
#'   num.text = 5,
#'   introduction = intro_rorschach,
#'   request = request_rorschach,
#'   isolate.groups = FALSE,
#'   generate = FALSE
#' )
#' rorschach_textual_evidence <- nail_evidence(res_nail_textual_rorschach)
#' rorschach_textual_prompt <- nail_prompt(
#'   res_nail_textual_rorschach,
#'   print = FALSE
#' )
#' cat(substr(rorschach_textual_prompt, 1, 600), "\n")
"rorschach"

#' Car-seat fabric comments
#'
#' Consumers evaluated car-seat fabrics and described why they liked or
#' disliked them. The comments can be compared across the binary `Class`
#' variable.
#'
#' @docType data
#'
#' @format
#' A data frame with 567 rows and 4 columns:
#' * `ID_judge`: the judge identifier;
#' * `Fabric`: the evaluated fabric (A to J);
#' * `Description`: the consumer's free-text reason; and
#' * `Class`: `0` for disliked and `1` for liked.
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' data(fabric, package = "NaileR")
#' head(fabric)
#'
#' fabric_A <- droplevels(fabric[fabric$Fabric == "A", ])
#' fabric_preview <- nail_textual(
#'   dataset = fabric_A,
#'   num.var = 4,
#'   num.text = 3,
#'   isolate.groups = FALSE,
#'   generate = FALSE
#' )
#' nail_evidence(fabric_preview)
#' nail_prompt(fabric_preview, print = FALSE)
#'
#' \dontrun{
#' # A real generation requires a configured local or remote provider.
#' library(NaileR)
#' intro_car <- paste(
#'   "Consumers evaluated a car-seat fabric and explained why they liked",
#'   "or disliked it. The two classes record these reported evaluations."
#' )
#' request_car <- paste(
#'   "Compare the comments for the two classes and describe the reasons",
#'   "given for liking or disliking the selected fabric."
#' )
#' fabric_generated <- nail_textual(
#'   dataset = fabric_A, num.var = 4, num.text = 3,
#'   introduction = intro_car, request = request_car,
#'   model = "llama3", isolate.groups = FALSE, generate = TRUE
#' )
#' nail_response(fabric_generated, print = FALSE)
#' }
"fabric"

#' Declared capacity and perceived restrictiveness for everyday changes
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
#' A data frame with 167 rows and 50 columns. The columns are named in the
#' data and are organized as follows:
#' * `*_capable`: ten declared-capacity items;
#' * `From_0_to_5_*_is_restrictive`: ten numeric ratings of perceived
#'   restrictiveness;
#' * `*_restrictive`: ten binary restrictiveness responses;
#' * `*_text`: ten free-text explanations; and
#' * `*_capable_restrictive`: ten derived combinations of the two responses.
#'
#' The item names identify the proposed change, such as `car_alone`,
#' `local_products`, or `vegan`. The historical column `turn off_text` keeps
#' its space because it is part of the distributed data.
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


#' Car-alone and car-sharing responses
#'
#' This smaller object contains the car-alone response and the associated
#' free-text explanation. The combined factor records the declared response
#' about taking a car alone together with the reported restrictiveness of
#' sharing a car.
#'
#' @docType data
#'
#' @format
#' A data frame with 158 rows and 2 columns:
#' * `car_alone_capable_restrictive`: the four-level combined response; and
#' * `car_alone_text`: the participant's free-text explanation.
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' data(car_alone, package = "NaileR")
#' head(car_alone)
#'
#' car_alone_preview <- nail_textual(
#'   dataset = car_alone,
#'   num.var = 1,
#'   num.text = 2,
#'   isolate.groups = TRUE,
#'   generate = FALSE
#' )
#' nail_evidence(car_alone_preview)
#' nail_prompt(car_alone_preview, print = FALSE)
#'
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

#' Atomic Habits survey with constructed groups
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
#' A data frame with 167 rows and 51 columns. It contains the 50 variables
#' described for [atomic_habit] and the additional factor `clust`, a
#' three-level constructed group identifier.
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

#' Sensory ratings of four strawberry products
#'
#' Twelve panelists evaluated four strawberry products in two observed
#' sessions. This standardized English-labelled data frame contains 96 rows
#' and 13 columns. There are no missing values in the distributed data.
#'
#' @docType data
#' @format A data frame with 96 rows and 13 columns. Product, Panelist, and
#' Session identify the product, assessor, and observed session. The remaining
#' ten columns are quantitative descriptors covering appearance, odor, texture,
#' taste, and flavor.
#' @details Each row records one product evaluation by one panelist in one
#' observed session. The source contained `NR`, `CJ`, `ProductName`, ten
#' numeric descriptors, and `Commentaire`; the comment field is not part of
#' this QDA dataset. The English labels are documented translations, not new
#' measurements. The descriptors are `Appearance_Size`, `Appearance_Color`,
#' `Odor_General`, `Texture_Firmness`, `Texture_Juiciness`,
#' `Texture_Melting`, `Taste_Sweetness`, `Taste_Sourness`, `Flavor_Aroma`,
#' and `Flavor_WildStrawberry`.
#'
#' `Texture_Melting` denotes the melting sensation of strawberry flesh.
#' `Flavor_Aroma` denotes overall aromatic intensity perceived in the mouth.
#' `Flavor_WildStrawberry` denotes the intensity of wild-strawberry-like flavor
#' notes. A score of zero indicates that the sensory attribute is absent or
#' not perceived. The upper scale anchor is not documented.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_01/fraise.Rdata`.
#' @examples
#' data(qda_strawberries)
#' dim(qda_strawberries)
#' head(qda_strawberries[, 1:4])
#'
#' strawberry_preview <- nail_qda(
#'   dataset = qda_strawberries,
#'   formul = "~Product+Panelist+Session",
#'   firstvar = 4,
#'   lastvar = 13,
#'   generate = FALSE
#' )
#' nail_evidence(strawberry_preview)
#' nail_prompt(strawberry_preview, print = FALSE)
"qda_strawberries"

#' Sensory ratings of six apple products
#'
#' Twenty-two panelists evaluated six apple products in two observed sessions.
#' This standardized English-labelled data frame contains 264 rows and 27
#' columns. There are no missing values in the distributed data.
#'
#' @docType data
#' @format A data frame with 264 rows and 27 columns. Product, Panelist, and
#' Session identify the product, assessor, and observed session. The remaining
#' 24 columns are quantitative descriptors covering appearance, odor, texture,
#' taste, and aroma.
#' @details Each row records one product evaluation by one panelist in one
#' observed session. Leading spaces in the original Renette and Golden
#' modalities were removed after a collision check. Aromatic descriptors were
#' evaluated in the mouth. The 24 descriptors are:
#' `Appearance_ColorUniformity`, `Appearance_Glossiness`,
#' `Appearance_Spottedness`, `Appearance_Flatness`, `Surface_Smoothness`,
#' `Appearance_Size`, `Odor_Herbaceous`, `Odor_Stuffy`, `Odor_Citrus`,
#' `Texture_Crispness`, `Texture_Firmness`, `Texture_Mealiness`,
#' `Texture_Juiciness`, `Mouthfeel_Astringency`,
#' `Texture_SkinResistance`, `Texture_SkinThickness`, `Taste_Sweetness`,
#' `Taste_Sourness`, `Taste_Bitterness`, `Aroma_Herbal`, `Aroma_Banana`,
#' `Aroma_Candy`, `Aroma_Lemon`, and `Residual_Astringency`.
#'
#' The documented definitions are: `Texture_SkinResistance`, resistance of
#' the apple skin during chewing; `Texture_SkinThickness`, perceived
#' thickness of the apple skin in the mouth; `Odor_Stuffy`, a stuffy or
#' enclosed-air odor; `Residual_Astringency`, a drying or rough sensation in
#' the mouth; `Aroma_Herbal`, an herbaceous aroma reminiscent of grass;
#' `Aroma_Banana`, a banana-like aroma; `Aroma_Candy`, a candy-like aroma
#' with cooked-sugar, sweet, tangy, and fruity notes; and `Aroma_Lemon`, a
#' lemon-like acidic citrus aroma. These correspond respectively to the
#' original labels `peau_t`, `épaisse_t`, `renfermé_o`, `astringent_r`,
#' `herbacé_a`, `banane_a`, `bonbon_a`, and `citron_a`.
#'
#' The remaining labels retain their standardized names without additional
#' definitions in the available source documentation.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_02/apples.Rdata`.
#' @examples
#' data(qda_apples)
#' dim(qda_apples)
#' table(qda_apples$Product)
#'
#' apple_preview <- nail_qda(
#'   dataset = qda_apples,
#'   formul = "~Product+Panelist+Session",
#'   firstvar = 4,
#'   lastvar = 27,
#'   generate = FALSE
#' )
#' nail_evidence(apple_preview)
#' nail_prompt(apple_preview, print = FALSE)
"qda_apples"

#' Sensory ratings of twelve perfumes
#'
#' Twelve panelists evaluated twelve perfume products in two sessions. This
#' standardized UTF-8 data frame contains 288 rows and 15 columns. There are
#' no missing values in the distributed data. Product names, including the
#' accented name `Cinéma`, are preserved.
#'
#' @docType data
#' @format A data frame with 288 rows and 15 columns. Product, Panelist, and
#' Session identify the product, assessor, and session. The remaining 12
#' columns are quantitative odor descriptors.
#' @details Each row records one product evaluation by one panelist in one
#' session. The source Rank column is not included in this QDA dataset. The
#' 12 descriptors are `Odor_Spicy`, `Odor_Heady`, `Odor_Fruity`,
#' `Odor_Green`, `Odor_Vanilla`, `Odor_Floral`, `Odor_Woody`,
#' `Odor_Citrus`, `Odor_Marine`, `Odor_Gourmand`, `Odor_Oriental`,
#' and `Odor_Enveloping`.
#'
#' `Odor_Gourmand` denotes a gourmand odor character, evoking sweet,
#' confectionery, or food-like notes. `Odor_Oriental` denotes an
#' oriental/amber fragrance character, preserving the terminology of the
#' original study. `Odor_Enveloping` denotes an enveloping or surrounding
#' quality of the fragrance. A score of zero indicates that the sensory
#' attribute is absent or not perceived. The upper scale anchor is not
#' documented.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_04/perfumes_qda_experts.csv`.
#' @examples
#' data(qda_perfumes)
#' dim(qda_perfumes)
#' unique(qda_perfumes$Product)
#'
#' perfume_preview <- nail_qda(
#'   dataset = qda_perfumes,
#'   formul = "~Product+Panelist+Session",
#'   firstvar = 4,
#'   lastvar = 15,
#'   product_knowledge = "known",
#'   generate = FALSE
#' )
#' nail_evidence(perfume_preview)
#' nail_prompt(perfume_preview, print = FALSE)
"qda_perfumes"

#' Sensory ratings of six melon products
#'
#' Twelve panelists evaluated six melon products. This standardized
#' English-labelled data frame contains 72 rows and 12 columns. It has no
#' `Session` column and no missing values.
#'
#' @docType data
#' @format A data frame with 72 rows and 12 columns. `Product` and
#' `Panelist` identify the product and assessor. The remaining ten columns
#' are quantitative descriptors covering mouthfeel, odor, and texture.
#' @details Each row records one product evaluation by one panelist. There is
#' no observed session or repetition field. The source `Smp.code` column is
#' excluded from the QDA dataset. The standardized product identifiers are
#' `DAI`, `DHL`, `HL`, `KS`, `TAKI`, and `TL3`. The descriptors are
#' `Mouthfeel_Bitterness`, `Mouthfeel_Sourness`, `Mouthfeel_Sweetness`,
#' `Odor_Floral`, `Odor_GreenGrass`, `Odor_RipeBanana`,
#' `Odor_SweetNote`, `Texture_Crispness`, `Texture_Firmness`, and
#' `Texture_Juiciness`.
#'
#' `Odor_SweetNote` denotes a sweet-smelling odor note, distinct from sweet
#' taste. `Texture_Crispness` denotes the crisp or crunchy texture of melon
#' flesh and corresponds to the original French descriptor "croquant". A
#' score of zero indicates that the sensory attribute is absent or not
#' perceived. The upper scale anchor is not documented. A product with no
#' selected statistical markers should not be described as average.
#' @source Local sensory study; standardized from
#' `local_data/qda/study_03/melons.Rdata`.
#' @examples
#' data(qda_melons)
#' dim(qda_melons)
#' table(qda_melons$Product)
#'
#' melon_preview <- nail_qda(
#'   dataset = qda_melons,
#'   formul = "~Product+Panelist",
#'   firstvar = 3,
#'   lastvar = 12,
#'   product_knowledge = "unknown",
#'   generate = FALSE
#' )
#' nail_evidence(melon_preview)
#' nail_prompt(melon_preview, print = FALSE)
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
#' A contingency table (data frame) with 8 rows and 335 columns:
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


#' SPISE / Distinction 48-item food-transition instrument
#'
#' This de-identified teaching object comes from the SPISE / Distinction
#' 2025--2026 study, which is one study represented by several files and
#' analysis stages. It contains the 48 Likert assertions used in the audited
#' workshop export. It is an instrument table, not an IRT score table and not
#' a classification.
#'
#' @docType data
#'
#' @format
#' A data frame with 181 rows and 48 ordered factor columns. The columns are
#' arranged in six blocks of eight items: geographical origin, procurement
#' modes, local territory and actors, environment and ecology, accessibility
#' and social justice, and engagement and civic participation. The response
#' levels are `Strongly disagree`, `Disagree`, `Neither agree nor disagree`,
#' `Agree`, and `Strongly agree`.
#'
#' @details
#' The source export contains a respondent identifier and additional context
#' and choice variables. Only the 48 item responses are distributed here; the
#' identifier and auxiliary fields are excluded. The 181-row object follows
#' the documented `Bretons_no_NA.xlsx` export and contains no missing item
#' responses. It must not be joined by row order to the IRTSAT objects. No
#' score, latent class or causal interpretation is supplied by this object.
#' The English variable names are a presentation layer based on the source
#' English item labels; the item dictionary records the source names and block
#' assignments.
#'
#' @source
#' SPISE / Distinction `Bretons_no_NA.xlsx`. The reconstruction script is
#' documented in `dev/transition_reconstruction/build_spise_distinction_data.R`.
#' The English item dictionary is
#' `dev/transition_reconstruction/SPISE_DISTINCTION_48_ITEMS_DICTIONARY.csv`.
#' @examples
#' library(NaileR)
#' data(spise_distinction_items_2025_2026, package = "NaileR")
#'
#' dim(spise_distinction_items_2025_2026)
#' names(spise_distinction_items_2025_2026)[1:8]
#' table(spise_distinction_items_2025_2026[[1]], useNA = "ifany")
#'
#' # The object has no group variable. It is therefore inspected as an
#' # instrument; no profile or IRT score is invented for a CATDES example.
"spise_distinction_items_2025_2026"


#' Distinction 2025--2026 complete food-transition survey
#'
#' A de-identified public teaching version of the complete 2025--2026
#' Distinction food, territory and food-choice survey. The object describes
#' reported opinions, selections and one open response field; it is not a
#' measure of observed behaviour and does not support causal conclusions.
#'
#' @docType data
#'
#' @format
#' A data frame with 1,226 rows and 105 scientific columns. The exact postal
#' code and ten technical export fields are excluded. The object contains 48
#' ordered agreement assertions, additional categorical and numeric survey
#' variables, and the character column `quality_food_open`, which contains
#' 1,225 non-missing English translations and one missing response. The
#' response levels of the ordered assertion columns are `Strongly disagree`,
#' `Disagree`, `Moderately agree`, `Agree`, and `Strongly agree`.
#'
#' @details
#' The survey concerns food, territory and distinctions made by respondents
#' when describing food choices. Multi-selection blocks retain the source
#' coding as `Selected` and `Not selected` when a block contains a response;
#' rows with no response to the testing-occasion block remain missing. The
#' observed maximum number of selections is preserved, including up to six
#' selections in the alternative-source-reason and food-choice-priority
#' blocks. Five numeric budget variables retain their prepared values without
#' rounding or imputation.
#'
#' The public object excludes the exact postal-code field and the technical
#' export metadata. The open responses were translated locally with
#' `mistral-small3.2:latest`; eleven hash-verified corrections were applied
#' after review against the private French source, including seven corrected
#' observations in the latest audit. The translation campaign used no
#' external service and is not a substitute for full human linguistic
#' validation. The original French responses and the private translation
#' mapping are not included in the package object.
#'
#' This complete 1,226-row survey belongs to the same broad SPISE / Distinction
#' study family as `spise_distinction_items_2025_2026`, but the two objects
#' represent different preparation stages. They must not be joined by row
#' order. The bilingual variable dictionary and the reproducible preparation
#' script are retained in
#' `dev/transition_reconstruction/DISTINCTION_VARIABLE_DICTIONARY.csv` and
#' `dev/transition_reconstruction/build_distinction_data.R`.
#'
#' @source
#' Local Distinction 2025--2026 questionnaire export. The distributed object
#' is a de-identified, English presentation layer prepared from the complete
#' survey; the original workbook remains outside the package source.
#' @examples
#' library(NaileR)
#' data(distinction, package = "NaileR")
#'
#' # Ask for a descriptive preview of the evidence associated with a survey
#' # variable. No LLM call is made by this example.
#' distinction_catdes <- nail_catdes(
#'   dataset = distinction,
#'   num.var = 1,
#'   interpretation_mode = "standard",
#'   generate = FALSE
#' )
#' distinction_catdes_evidence <- nail_evidence(distinction_catdes)
#' distinction_catdes_prompt <- nail_prompt(distinction_catdes, print = FALSE)
#' cat(substr(distinction_catdes_prompt, 1, 600), "\n")
#'
#' # A numeric survey variable can be characterized with CONDES.
#' distinction_condes <- nail_condes(
#'   dataset = distinction,
#'   num.var = 2,
#'   interpretation_mode = "standard",
#'   generate = FALSE
#' )
#' distinction_condes_evidence <- nail_evidence(distinction_condes)
#'
#' # The open response column can be inspected with TEXTUAL while retaining
#' # the statistical group variable used in the example.
#' distinction_textual <- nail_textual(
#'   dataset = distinction,
#'   num.var = 1,
#'   num.text = 105,
#'   isolate.groups = TRUE,
#'   generate = FALSE
#' )
#' distinction_textual_evidence <- nail_evidence(distinction_textual)
#' distinction_textual_prompt <- nail_prompt(distinction_textual, print = FALSE)
#' @keywords datasets
"distinction"


#' Breton subset of the Distinction food-transition survey
#'
#' A publishable 485-respondent subset of the Distinction food, territory and
#' food-choice survey, restricted to the administrative Brittany departments
#' represented by postal-code prefixes 22, 29, 35 and 56. The object preserves
#' the complete 105-column schema of [distinction], including the 47 assertion
#' variables and the translated open-response column `quality_food_open`.
#' The classification used in the examples is recomputed on this subset and
#' is therefore exploratory: its group identifiers are not the identifiers of
#' the full-sample Distinction classification.
#'
#' The data describe declared positions and open comments about an ideal food
#' system. They do not measure observed behaviour and do not support causal or
#' regional generalisations.
#'
#' @docType data
#'
#' @format
#' A data frame with 485 rows and 105 columns. It has the same column names,
#' order, classes and factor levels as [distinction]. The column
#' `quality_food_open` contains 485 non-missing English translations of the
#' open response field. The 47 active assertion columns are named
#' `assertion_q17_*` and `assertion_q21_*` through `assertion_q25_*`.
#'
#' @details
#' The object is intended for a compact, reproducible ACM--HCPC--CATDES
#' example. The open-response column is supplementary textual evidence; it is
#' not silently included in the CATDES calculation. The two-pass enrichment
#' preview uses `num.textual = 48`, `textual.sample = 0.5` and
#' `textual.seed = 123` after a derived table has been constructed with a
#' `profile` column at position 49.
#'
#' @source
#' Public teaching subset prepared from the Distinction 2025--2026 survey;
#' administrative Brittany selection by postal-code prefixes 22, 29, 35 and
#' 56. The source export and the processing record are not required to load
#' this package dataset.
#' @examples
#' library(FactoMineR)
#' library(NaileR)
#' data(bretons, package = "NaileR")
#'
#' active_bretons <- c(
#'   grep("^assertion_q17_", names(bretons), value = TRUE),
#'   grep("^assertion_q2[1-5]_", names(bretons), value = TRUE)
#' )
#' set.seed(1)
#' bretons_mca <- FactoMineR::MCA(
#'   bretons[active_bretons], ncp = 10, graph = FALSE
#' )
#' bretons_hcpc <- FactoMineR::HCPC(
#'   bretons_mca, nb.clust = 3, graph = FALSE
#' )
#' stopifnot(identical(rownames(bretons), rownames(bretons_hcpc$data.clust)))
#'
#' bretons_prepared <- data.frame(
#'   bretons[active_bretons],
#'   quality_food_open = as.character(bretons$quality_food_open),
#'   profile = factor(bretons_hcpc$data.clust[[ncol(bretons_hcpc$data.clust)]]),
#'   check.names = FALSE
#' )
#' intro_bretons <- paste(
#'   "This exploratory survey examines declared positions about an ideal food",
#'   "system among respondents living in administrative Brittany.",
#'   "The groups were constructed from food-system assertions; the open",
#'   "responses are comments about food and territory, not verified behaviour.",
#'   "The profiles should be described as configurations of declared positions,",
#'   "without causal or regional generalisation."
#' )
#' request_bretons <- paste(
#'   "Describe the three exploratory groups using several CATDES findings",
#'   "together when possible. Keep group identifiers and distinguish",
#'   "statistical observations from cautious hypotheses. Do not infer causes",
#'   "or regional differences beyond this sample."
#' )
#' bretons_preview <- nail_catdes(
#'   dataset = bretons_prepared,
#'   num.var = 49,
#'   num.textual = 48,
#'   textual.sample = 0.5,
#'   textual.seed = 123,
#'   interpretation_mode = "latent",
#'   isolate.groups = FALSE,
#'   drop.negative = FALSE,
#'   introduction = intro_bretons,
#'   request = request_bretons,
#'   generate = FALSE
#' )
#' bretons_evidence <- nail_evidence(bretons_preview)
#' bretons_prompt <- nail_prompt(bretons_preview, print = FALSE)
#' bretons_enrichment <- nail_catdes_enrichment(bretons_preview)
#' head(bretons_enrichment$selected_texts[, c("text_id", "group", "source_row")])
#'
#' \dontrun{
#' bretons_generated <- nail_catdes(
#'   dataset = bretons_prepared,
#'   num.var = 49,
#'   num.textual = 48,
#'   textual.sample = 0.5,
#'   textual.seed = 123,
#'   interpretation_mode = "latent",
#'   isolate.groups = FALSE,
#'   drop.negative = FALSE,
#'   introduction = intro_bretons,
#'   request = request_bretons,
#'   provider = "gemini",
#'   model = "gemini-2.5-flash",
#'   max_output_tokens = 32768L,
#'   max_tries = 1L,
#'   timeout = 120,
#'   generate = TRUE
#' )
#' enrichment_generated <- nail_catdes_enrichment(bretons_generated)
#' enriched_response <- nail_response(bretons_generated, print = FALSE)
#' first_pass_response <- enrichment_generated$first_pass$responses[["portfolio"]]
#' second_pass_response <- enrichment_generated$second_pass$responses[["portfolio"]]
#' }
#' @keywords datasets
"bretons"
