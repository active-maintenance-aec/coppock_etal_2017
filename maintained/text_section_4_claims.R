# coppock_etal_2017/maintained/text_section_4_claims.R
# Output: output/text_section_4_claims.csv
# Depends on: table_3_bounds_main.R output, table_a1_mipo_effects.R output,
#   figure_2_sensitivity.R output, helpers.R
# Description: The numbers Sections 4.2 and 4.3 state in prose rather than in a table:
#   the naive effect estimate, the bounds and intervals quoted at two decimal places, the
#   confidence interval widths and the reduction between them, and delta star.
source(here::here("maintained", "helpers.R"))

bounds <- read_csv(here::here("maintained", "output", "table_3_bounds_main.csv"),
                   show_col_types = FALSE)
mipo <- read_csv(here::here("maintained", "output", "table_a1_mipo_effects.csv"),
                 show_col_types = FALSE)
sensitivity <- read_csv(here::here("maintained", "output", "figure_2_sensitivity.csv"),
                        show_col_types = FALSE)

# The naive estimate the paper reports is the Polarized coefficient in the Wave 2
# Perceived Polarization regression among initial responders, which is Appendix Table 1's
# second column.
naive <- mipo |>
  filter(model == "Perceived Polarization, Wave 2", term == "Z_levPolarized")

value_of <- function(row_label, column) {
  bounds[[column]][bounds$quantity == row_label]
}

ci_width_no_ds <- value_of("95% CI Upper Bound", "no_ds") -
  value_of("95% CI Lower Bound", "no_ds")
ci_width_ds_ps <- value_of("95% CI Upper Bound", "ds_ps") -
  value_of("95% CI Lower Bound", "ds_ps")

claims <- tribble(
  ~claim, ~value,
  "Naive ATE on Perceived Polarization, Wave 2", naive$estimate,
  "Naive ATE standard error", naive$std.error,
  "Naive ATE two-sided p-value", naive$p.value,
  "Worst-case bound without double sampling, low", value_of("Worst-Case Bound: Low Estimate", "no_ds"),
  "Worst-case bound without double sampling, high", value_of("Worst-Case Bound: High Estimate", "no_ds"),
  "95% CI without double sampling, lower", value_of("95% CI Lower Bound", "no_ds"),
  "95% CI without double sampling, upper", value_of("95% CI Upper Bound", "no_ds"),
  "Double sampling identification region, low", value_of("Worst-Case Bound: Low Estimate", "ds"),
  "Double sampling identification region, high", value_of("Worst-Case Bound: High Estimate", "ds"),
  "Poststratified identification region, low", value_of("Worst-Case Bound: Low Estimate", "ds_ps"),
  "Poststratified identification region, high", value_of("Worst-Case Bound: High Estimate", "ds_ps"),
  "Poststratified 95% CI, lower", value_of("95% CI Lower Bound", "ds_ps"),
  "Poststratified 95% CI, upper", value_of("95% CI Upper Bound", "ds_ps"),
  "95% CI width without double sampling", ci_width_no_ds,
  "95% CI width with double sampling and poststratification", ci_width_ds_ps,
  "Proportional reduction in 95% CI width", (ci_width_no_ds - ci_width_ds_ps) / ci_width_no_ds,
  "Sensitivity parameter delta star", sensitivity$p[sensitivity$change_any]
)

print(claims, n = nrow(claims))

write_csv(claims, here::here("maintained", "output", "text_section_4_claims.csv"))
