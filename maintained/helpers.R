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

# Anchors a script run on its own rather than through run_all.R, which is what the
# reproduction instructions tell a reader they may do.
here::i_am("maintained/helpers.R")

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
# Both published tables print these six quantities under these names, in this order.
bound_labels <- c(
  "95% CI Lower Bound",
  "95% CI Upper Bound",
  "Worst-Case Bound: Low Estimate",
  "Worst-Case Bound: High Estimate",
  "Variance of Low Estimate",
  "Variance of High Estimate"
)

# One published table column, from one estimator result ----
# The estimators return the same six quantities under broom's names, in a different
# order from the one the tables print, and report the uncertainty as a standard error
# where the tables print a variance. Both are handled here: the rows are selected by
# name rather than by position, and the last two are squared back to variances so the
# cells mean what their labels say. Taking as.numeric() of the result would now fill
# every row with the wrong quantity and print two standard errors under "Variance of".
published_bound_column <- function(x) {
  c(unname(x["conf.low"]),
    unname(x["conf.high"]),
    unname(x["estimate_lower"]),
    unname(x["estimate_upper"]),
    unname(x["std.error_lower"])^2,
    unname(x["std.error_upper"])^2)
}

# Blank a figure PDF's embedded timestamps ----
# R's pdf() device stamps /CreationDate and /ModDate with the wall clock, so an
# otherwise deterministic pipeline writes a different file on every run. The epoch
# string is the same width as what it replaces, which keeps the cross-reference byte
# offsets valid, and a file with no timestamp is left alone.
blank_pdf_timestamps <- function(path) {
  epoch <- charToRaw("D:19700101000000")
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  if (length(hits) == 0) return(invisible(path))
  for (h in hits) raw_pdf[h:(h + length(epoch) - 1L)] <- epoch
  writeBin(raw_pdf, path)
  invisible(path)
}
