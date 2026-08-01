# coppock_etal_2017/maintained/table_a2_pairwise_bounds.R
# Output: output/table_a2_pairwise_bounds.csv, output/table_a2_pairwise_bounds.tex
# Depends on: original/levendusky_mturk_clean.csv, helpers.R
# Description: Appendix Table 2: double sampling worst-case bounds for all three pairwise
#   treatment comparisons on both dependent variables, as promised in the preanalysis plan.
source(here::here("maintained", "helpers.R"))

pol_vs_mod <- mturk |> filter(!is.na(Z1))
pol_vs_placebo <- mturk |> filter(!is.na(Z2))
mod_vs_placebo <- mturk |> filter(!is.na(Z3))

# Perceived Polarization ----
pol_mod_pp <- estimator_ds(Y = L_dif_w2, Z = Z1, R1 = R1, Attempt = Attempt, R2 = R2,
                           minY = 0, maxY = 6, alpha = 0.05, data = pol_vs_mod)
pol_placebo_pp <- estimator_ds(Y = L_dif_w2, Z = Z2, R1 = R1, Attempt = Attempt, R2 = R2,
                               minY = 0, maxY = 6, alpha = 0.05, data = pol_vs_placebo)
mod_placebo_pp <- estimator_ds(Y = L_dif_w2, Z = Z3, R1 = R1, Attempt = Attempt, R2 = R2,
                               minY = 0, maxY = 6, alpha = 0.05, data = mod_vs_placebo)

# Extremity ----
pol_mod_ex <- estimator_ds(Y = L_ex_w2, Z = Z1, R1 = R1, Attempt = Attempt, R2 = R2,
                           minY = 0, maxY = 6, alpha = 0.05, data = pol_vs_mod)
pol_placebo_ex <- estimator_ds(Y = L_ex_w2, Z = Z2, R1 = R1, Attempt = Attempt, R2 = R2,
                               minY = 0, maxY = 6, alpha = 0.05, data = pol_vs_placebo)
mod_placebo_ex <- estimator_ds(Y = L_ex_w2, Z = Z3, R1 = R1, Attempt = Attempt, R2 = R2,
                               minY = 0, maxY = 6, alpha = 0.05, data = mod_vs_placebo)

table_a2 <- tibble(
  quantity = bound_labels,
  pol_mod_pp = as.numeric(pol_mod_pp),
  pol_mod_ex = as.numeric(pol_mod_ex),
  pol_placebo_pp = as.numeric(pol_placebo_pp),
  pol_placebo_ex = as.numeric(pol_placebo_ex),
  mod_placebo_pp = as.numeric(mod_placebo_pp),
  mod_placebo_ex = as.numeric(mod_placebo_ex)
)

print(table_a2)

write_csv(table_a2, here::here("maintained", "output", "table_a2_pairwise_bounds.csv"))

table_a2 |>
  mutate(across(-quantity, \(x) sprintf("%.4f", x))) |>
  kable(
    format = "latex",
    booktabs = TRUE,
    col.names = c("", rep(c("DV: PP", "DV: EX"), 3)),
    align = "lrrrrrr",
    caption = "Double sampling bounds for pairwise comparisons."
  ) |>
  add_header_above(c(" " = 1, "Polarized vs. Moderate" = 2,
                     "Polarized vs. Placebo" = 2, "Moderate vs. Placebo" = 2)) |>
  write_lines(here::here("maintained", "output", "table_a2_pairwise_bounds.tex"))
