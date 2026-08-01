# coppock_etal_2017/maintained/helpers.R
# Shared packages, data and row labels sourced by every script in maintained/.

library(here)
library(tidyverse)
library(estimatr)
library(modelsummary)
library(knitr)
library(kableExtra)
library(gridExtra)
library(attrition)

# modelsummary defaults to the tabularray LaTeX factory and to siunitx number macros, so
# its output would need two packages the other tables here do not use. These options put
# it on the same kableExtra and booktabs footing as the hand-built tables.
options(
  modelsummary_format_numeric_latex = "plain",
  modelsummary_factory_latex = "kableExtra"
)

# Analysis data ----
# The deposited experimental data, fetched and checksum-verified by download_original.R.
# 995 subjects in the Moderate arm, 985 in the Polarized arm and 975 in the Placebo arm,
# with Wave 1 and Wave 2 measures of Perceived Polarization (L_dif, L_dif_w2) and
# Extremity (L_ex, L_ex_w2). Z1 codes Polarized against Moderate, Z2 Polarized against
# Placebo and Z3 Moderate against Placebo, each NA for the arm it excludes.
mturk <- read_csv(here::here("original", "levendusky_mturk_clean.csv"),
                  show_col_types = FALSE)

# Row labels shared by Table 3 and Appendix Table 2 ----
# estimator_ev() and estimator_ds() both return these six quantities in this order, and
# both published tables print them under these names.
bound_labels <- c(
  "95% CI Lower Bound",
  "95% CI Upper Bound",
  "Worst-Case Bound: Low Estimate",
  "Worst-Case Bound: High Estimate",
  "Variance of Low Estimate",
  "Variance of High Estimate"
)
