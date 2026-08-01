# coppock_etal_2017/maintained/table_2_outcome_means.R
# Output: output/table_2_outcome_means.csv, output/table_2_outcome_means.tex
# Depends on: original/levendusky_mturk_clean.csv, helpers.R
# Description: Table 2: Wave 2 outcome means by condition, for initial responders and for
#   the double sampled responders recruited from among the initial nonrespondents.
source(here::here("maintained", "helpers.R"))

table_2 <- mturk |>
  filter(Z_Levendusky != "placebo") |>
  group_by(condition = Z_lev) |>
  summarize(
    ir_mean = mean(L_dif_w2[R1 == 1]),
    ir_sd = sd(L_dif_w2[R1 == 1]),
    ir_n = sum(R1),
    ds_mean = mean(L_dif_w2[R2 == 1]),
    ds_sd = sd(L_dif_w2[R2 == 1]),
    ds_n = sum(R2),
    .groups = "drop"
  )

print(table_2)

write_csv(table_2, here::here("maintained", "output", "table_2_outcome_means.csv"))

table_2 |>
  mutate(across(c(ir_mean, ir_sd, ds_mean, ds_sd), \(x) sprintf("%.3f", x))) |>
  kable(
    format = "latex",
    booktabs = TRUE,
    col.names = c("", "Mean", "SD", "N", "Mean", "SD", "N"),
    align = "lrrrrrr",
    caption = "Outcome summaries by condition and response type."
  ) |>
  add_header_above(c(" " = 1, "Initial Responders" = 3,
                     "Double Sampled Responders" = 3)) |>
  write_lines(here::here("maintained", "output", "table_2_outcome_means.tex"))
