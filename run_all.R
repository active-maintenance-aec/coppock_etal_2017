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
