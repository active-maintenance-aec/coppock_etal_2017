# coppock_etal_2017/maintained/table_3_bounds_main.R
# Output: output/table_3_bounds_main.csv, output/table_3_bounds_main.tex
# Depends on: original/levendusky_mturk_clean.csv, helpers.R
# Description: Table 3: worst-case bounds on the Polarized versus Moderate ATE on
#   Perceived Polarization, without double sampling, with it, and with poststratification.
source(here::here("maintained", "helpers.R"))

# Z1 is non-missing only for the Moderate and Polarized arms, so this drops Placebo.
pol_vs_mod <- mturk |> filter(!is.na(Z1))

# Worst-case bounds from the initial sample alone ----
no_ds <- estimator_ev(
  Y = L_dif_w2, Z = Z1, R = R1,
  minY = 0, maxY = 6, alpha = 0.05,
  data = pol_vs_mod
)

# Worst-case bounds under double sampling ----
ds <- estimator_ds(
  Y = L_dif_w2, Z = Z1, R1 = R1, Attempt = Attempt, R2 = R2,
  minY = 0, maxY = 6, alpha = 0.05,
  data = pol_vs_mod
)

# Double sampling with poststratification on three-category party identification ----
ds_ps <- estimator_ds(
  Y = L_dif_w2, Z = Z1, R1 = R1, Attempt = Attempt, R2 = R2,
  strata = pid_3_recoded,
  minY = 0, maxY = 6, alpha = 0.05,
  data = pol_vs_mod
)

table_3 <- tibble(
  quantity = bound_labels,
  no_ds = as.numeric(no_ds),
  ds = as.numeric(ds),
  ds_ps = as.numeric(ds_ps)
)

print(table_3)

write_csv(table_3, here::here("maintained", "output", "table_3_bounds_main.csv"))

table_3 |>
  mutate(across(c(no_ds, ds, ds_ps), \(x) sprintf("%.4f", x))) |>
  kable(
    format = "latex",
    booktabs = TRUE,
    col.names = c("", "Worst-Case Bounds", "WCB + Double Sampling",
                  "WCB + DS + Poststratification"),
    align = "lrrr",
    caption = "Replication study results, DV: Perceived Polarization."
  ) |>
  write_lines(here::here("maintained", "output", "table_3_bounds_main.tex"))
