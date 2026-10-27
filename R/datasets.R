
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
#' A data frame with 167 rows and 50 columns:
#' * columns 1-10, do you feel able to...
#' * columns 11-20, from 0 to 5 how restrictive...
#' * columns 21-30, is it restrictive, yes or no...
#' * columns 31-40, justify your answers
#' * columns 41-50, a combination of able and restrictive
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#'library(FactoMineR)
#'library(NaileR)
#'data(atomic_habit)
#'
#'res_mfa <- MFA(atomic_habit[,1:30],
#'               group = c(10,10,10),
#'               type = c("n","s","n"),
#'               num.group.sup = 3,
#'               name.group = c("capable","restrictive", "restrictive binary"),
#'               graph = FALSE)
#'
#'plot.MFA(res_mfa, choix = "ind", invisible = c("quali","quali.sup"),
#'         lab.ind = FALSE,
#'         title = "MFA based on being capable and restrictiveness data")
#'
#'res_hcpc <- HCPC(res_mfa, nb.clust = 3, graph = FALSE)
#'plot.HCPC(res_hcpc, choice = "map",
#'          draw.tree = FALSE,
#'          ind.names = FALSE,
#'          title = "Atomic habits - typology")
#'summary(res_hcpc$data.clust)
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
#' A data frame with 167 rows and 51 columns:
#' * columns 1-10, do you feel able to...
#' * columns 11-20, from 0 to 5 how restrictive...
#' * columns 21-30, is it restrictive, yes or no...
#' * columns 31-40, justify your answers
#' * columns 41-50, a combination of able and restrictive
#' * column 51, cluster variable based on MFA (20 first variables)
#'
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#'library(FactoMineR)
#'library(NaileR)
#'data(atomic_habit_clust)
#'
#'catdes(atomic_habit_clust, num.var = 51)
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
#' labels are documented translations, not new measurements.
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
#' are preserved. The
#' meanings of `Odor_Greedy`, `Odor_Oriental`, and `Odor_Wrapping`, as well as
#' the scale anchors, require confirmation from the original codebook.
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
#' `TL3`. Some source labels remain provisional where the codebook does not
#' resolve their exact sensory scope.
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
#' Participants had to rank how acceptable they found 45 statements about a sustainable food system; then, they were asked if they agreed with 14 other statements.
#'
#' @docType data
#'
#' @format
#' A data frame with 573 rows (participants) and 63 columns (questions):
#' * columns 1-45 statements about food systems
#' * columns 46-59 opinions
#' * columns 60-63 personal information
#' @source Applied mathematics department, Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(FactoMineR)
#' library(NaileR)
#' data(local_food)
#'
#' res_mca_food <- MCA(local_food, quali.sup = 46:63,
#' ncp = 100, level.ventil = 0.05, graph = FALSE)
#' res_hcpc_food <- HCPC(res_mca_food, nb.clust = 3, graph = FALSE)
#' don_clust_food <- res_hcpc_food$data.clust
#'
#' intro_food <- 'A study on sustainable food systems
#' was led on several French participants.
#' This study had 2 parts. In the first part,
#' participants had to rate how acceptable
#' "a food system that..." (e.g, "a food system that
#' only uses renewable energy") was to them.
#' In the second part, they had to say
#' if they agreed or disagreed with some statements.'
#' intro_food <- gsub('\n', ' ', intro_food) |>
#' stringr::str_squish()
#'
#' req_food <- 'I will give you the answers from one group.
#' Please explain who the individuals of this group are,
#' what their beliefs are.
#' Then, give this group a new name,
#' and explain why you chose this name.
#' Do not use 1st person ("I", "my"...) in your answer.'
#' req_food <- gsub('\n', ' ', req_food) |>
#' stringr::str_squish()
#'
#' res_food <- nail_catdes(don_clust_food, num.var = 64,
#' introduction = intro_food,
#' request = req_food,
#' isolate.groups = TRUE, drop.negative = TRUE)
#' res_food[[1]] |> cat()
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
#' These data were collected after a survey on food waste, with participants describing their habits.
#'
#' @docType data
#'
#' @format
#' A data frame with 180 rows (participants) and 77 columns (questions).
#'
#' @source Héloïse BILLES and Amélie RATEAU, students at l'Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' library(FactoMineR)
#' data(waste)
#' waste <- waste[-14]
#'
#' res_mca_waste <- MCA(waste, quali.sup = c(1,2,50:76),
#' ncp = 35, level.ventil = 0.05, graph = FALSE)
#' res_hcpc_waste <- HCPC(res_mca_waste, nb.clust = 3, graph = FALSE)
#' don_clust_waste <- res_hcpc_waste$data.clust
#'
#' intro_waste <- 'These data were collected
#' after a survey on food waste,
#' with participants describing their habits.'
#' intro_waste <- gsub('\n', ' ', intro_waste) |>
#' stringr::str_squish()
#'
#' req_waste <- 'Please summarize the characteristics of each group.
#' Then, give each group a new name, based on your conclusions.
#' Finally, give each group a grade between 0 and 10,
#' based on how wasteful they are with food:
#' 0 being "not at all", 10 being "absolutely".'
#' req_waste <- gsub('\n', ' ', req_waste) |>
#' stringr::str_squish()
#'
#' res_waste <- nail_catdes(don_clust_waste,
#' num.var = ncol(don_clust_waste),
#' introduction = intro_waste, request = req_waste,
#' drop.negative = TRUE)
#' res_waste |> cat()
#' }
"waste"


#' Perception of food quality
#'
#' These data were collected after a study on the perception of food quality.
#' Participants were given 9 French logos; they had to rate, on a scale from 0 (not at all) to 10 (absolutely), how much a product bearing them aligned with their own perception of quality.
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
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(quality)
#'
#' colnames(quality) <- c("Agriculture biologique",
#' "Label Rouge",
#' "FairTrade",
#' "Bleu Blanc Coeur",
#' "Appelation d'origine contrôlée",
#' "Produit en Bretagne",
#' "Viandes de France",
#' "Nourri sans OGM",
#' "Médailles Agro")
#'
#' res_pca_quality <- FactoMineR::PCA(quality, graph = FALSE)
#' quali_work <- res_pca_quality$ind$coord |> as.data.frame()
#' quali_work <- quali_work[,1] |> cbind(quality)
#'
#' intro_quali <- "These data were collected after a study
#' on the perception of food quality.
#' Participants were given 9 French logos;
#' they had to rate, on a scale from 0 (not at all)
#' to 10 (absolutely), how much a product bearing them
#' aligned with their own perception of quality."
#' intro_quali <- gsub('\n', ' ', intro_quali) |>
#' stringr::str_squish()
#'
#' res_quality <- nail_condes(quali_work, num.var = 1,
#' quanti.cat = c('Higher quality', 'Lower quality', 'Neutral'),
#' introduction = intro_quali, generate = FALSE)
#'
#' ppt <- gsub('characteristics', 'opinions', res_quality)
#'
#' res_quality <- ollamar::generate('llama3', ppt, output = 'df')
#' res_quality$response |> cat()
#' }
"quality"


#' Nutri-score survey
#'
#' These data were collected after a survey on the nutri-score. Participants were asked various questions about their views on the nutri-score, and about their eating habits.
#'
#' @docType data
#'
#' @format
#' A data frame with 112 rows (participants) and 36 columns (questions).
#'
#' @source Anaëlle YANNIC and Jessie PICOT, students at l'Institut Agro Rennes-Angers
#' @examples
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' library(FactoMineR)
#'
#' data(nutriscore)
#'
#' res_mca_nutriscore <- MCA(nutriscore, quali.sup = 17:36,
#' ncp = 15, level.ventil = 0.05, graph = FALSE)
#'
#' res_hcpc_nutriscore <- HCPC(res_mca_nutriscore, nb.clust = 3,
#' graph = FALSE)
#' don_clust_nutriscore <- res_hcpc_nutriscore$data.clust
#'
#' intro_nutri <- 'These data were collected after a survey
#' on the nutri-score. Participants were asked
#' various questions about their views on the nutri-score,
#' and about their eating habits.
#' Participants were split into groups according to their answers.'
#' intro_nutri <- gsub('\n', ' ', intro_nutri) |>
#' stringr::str_squish()
#'
#' req_nutri <- 'Please summarize the characteristics
#' of each group. Then, give each group a new name,
#' based on your conclusions.'
#' req_nutri <- gsub('\n', ' ', req_nutri)|>
#' stringr::str_squish()
#'
#' res_nutriscore <- nail_catdes(don_clust_nutriscore, num.var = 37,
#' introduction = intro_nutri, request = req_nutri,
#' drop.negative = TRUE)
#' res_nutriscore |> cat()
#' }
"nutriscore"
