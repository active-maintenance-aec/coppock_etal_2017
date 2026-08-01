# coppock_etal_2017/maintained/table_1_attrition.R
# Output: output/table_1_attrition.csv, output/table_1_attrition.tex
# Depends on: original/levendusky_mturk_clean.csv, helpers.R
# Description: Table 1: attrition by treatment condition, initial and follow-up samples.
source(here::here("maintained", "helpers.R"))

# The main text compares the Polarized and Moderate arms; the Placebo arm enters only in
# Appendix Table 2, so Table 1 counts the two arms the main text analyzes.
analysis <- mturk |> filter(Z_Levendusky != "placebo")

by_arm <- analysis |>
  group_by(condition = Z_lev) |>
  summarize(
    n_initial = n(),
    responded = sum(R1),
    did_not_respond = sum(1 - R1),
    invited = sum(Attempt),
    responded_to_invitation = sum(R2),
    .groups = "drop"
  )

total <- analysis |>
  summarize(
    condition = "Total",
    n_initial = n(),
    responded = sum(R1),
    did_not_respond = sum(1 - R1),
    invited = sum(Attempt),
    responded_to_invitation = sum(R2)
  )

table_1 <- bind_rows(by_arm, total)
print(table_1)

write_csv(table_1, here::here("maintained", "output", "table_1_attrition.csv"))

table_1 |>
  kable(
    format = "latex",
    booktabs = TRUE,
    col.names = c("", "N", "Responded", "Did Not Respond", "Invited",
                  "Responded to Invitation"),
    caption = "Attrition by treatment condition."
  ) |>
  add_header_above(c(" " = 1, "Initial Sample" = 3, "Follow-up Sample" = 2)) |>
  write_lines(here::here("maintained", "output", "table_1_attrition.tex"))
