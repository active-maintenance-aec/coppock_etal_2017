# coppock_etal_2017/maintained/table_a1_mipo_effects.R
# Output: output/table_a1_mipo_effects.csv, output/table_a1_mipo_effects_gof.csv,
#   output/table_a1_mipo_effects.tex
# Depends on: original/levendusky_mturk_clean.csv, helpers.R
# Description: Appendix Table 1: immediate and over-time treatment effects on Perceived
#   Polarization and Extremity, estimated among initial Wave 2 responders under the
#   assumption that missingness is independent of potential outcomes.
source(here::here("maintained", "helpers.R"))

# All three arms, restricted to subjects who responded in the initial Wave 2 sample.
# Z_lev is Moderate, Placebo, Polarized in alphabetical order, so Moderate is the
# reference category, which is what the published table reports.
responders <- mturk |> filter(R1 == 1)

fit_pp_wave_1 <- lm_robust(L_dif ~ Z_lev, data = responders, se_type = "HC2")
fit_pp_wave_2 <- lm_robust(L_dif_w2 ~ Z_lev, data = responders, se_type = "HC2")
fit_ex_wave_1 <- lm_robust(L_ex ~ Z_lev, data = responders, se_type = "HC2")
fit_ex_wave_2 <- lm_robust(L_ex_w2 ~ Z_lev, data = responders, se_type = "HC2")

models <- list(
  "Perceived Polarization, Wave 1" = fit_pp_wave_1,
  "Perceived Polarization, Wave 2" = fit_pp_wave_2,
  "Extremity, Wave 1" = fit_ex_wave_1,
  "Extremity, Wave 2" = fit_ex_wave_2
)

coefficients <- imap(models, \(fit, label) tidy(fit) |> mutate(model = label)) |>
  list_rbind() |>
  select(model, term, estimate, std.error, statistic, p.value, conf.low, conf.high)

fit_stats <- imap(models, \(fit, label) glance(fit) |> mutate(model = label)) |>
  list_rbind() |>
  select(model, nobs, r.squared, adj.r.squared)

print(coefficients)
print(fit_stats)

write_csv(coefficients,
          here::here("maintained", "output", "table_a1_mipo_effects.csv"))
write_csv(fit_stats,
          here::here("maintained", "output", "table_a1_mipo_effects_gof.csv"))

# The published table stars coefficients at 0.1, 0.05 and 0.01, and prints no stars on
# the constant because commarobust::makerobustpslist() overwrote the intercept p-value
# with 1 before handing the models to stargazer. The rewrite reports the intercept's
# actual p-value, so the constant carries stars here that the published table omits.
modelsummary(
  models,
  output = here::here("maintained", "output", "table_a1_mipo_effects.tex"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "Z_levPlacebo" = "Treatment: Placebo",
    "Z_levPolarized" = "Treatment: Polarized",
    "(Intercept)" = "Constant"
  ),
  gof_map = list(
    list(raw = "nobs", clean = "N", fmt = 0),
    list(raw = "r.squared", clean = "R2", fmt = \(x) sprintf("%.4f", x))
  ),
  title = "Immediate and Over Time Effects of Treatment",
  notes = c(
    "All models are estimated among those who respond in the initial Wave 2 sample.",
    "HC2 robust standard errors are in parentheses."
  )
)
