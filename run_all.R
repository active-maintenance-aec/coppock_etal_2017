# coppock_etal_2017/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive, install
# the attrition package the method lives in, then every published table and figure, then
# the numbers the text states in prose.
# Every script is self-contained and can also be run on its own, except
# text_section_4_claims.R, which reads output the table and figure scripts write.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))
source(here::here("install_attrition.R"))

# Tables ----
source(here::here("maintained", "table_1_attrition.R"))
source(here::here("maintained", "table_2_outcome_means.R"))
source(here::here("maintained", "table_3_bounds_main.R"))
source(here::here("maintained", "table_a1_mipo_effects.R"))
source(here::here("maintained", "table_a2_pairwise_bounds.R"))

# Figures ----
# figure_1_simulation.R evaluates the bounds at 6,000 points on the simulation grid and
# is the slow step, around twenty seconds.
source(here::here("maintained", "figure_1_simulation.R"))
source(here::here("maintained", "figure_2_sensitivity.R"))

# In-text numbers ----
# Reads the table and figure output above, so it runs last.
source(here::here("maintained", "text_section_4_claims.R"))

# Figure timestamps ----
# R's pdf() device stamps a wall-clock /CreationDate and /ModDate into every figure it
# writes, and those two fields are the only reason two runs of this pipeline produce
# differing files. Blanking them lets the determinism check cover every file the
# pipeline writes rather than all but the figures.
source(here::here("maintained", "helpers.R"))
walk(
  list.files(here::here("maintained", "output"), pattern = "\\.pdf$", full.names = TRUE),
  blank_pdf_timestamps
)

# Ground truth and the coverage gate ----
# build_ground_truth.R rebuilds the comparison against the published article and ends by
# running in_text_claims.R as a program, under capture.output and in its own environment,
# to check that every claim the extraction says needs a block has one and that the two
# instruments agree value by value.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims, printed for a reader ----
# The same file again, this time so its output lands in the log where a human can read it
# beside the article.
source(here::here("maintained", "in_text_claims.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
