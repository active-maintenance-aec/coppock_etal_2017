# coppock_etal_2017/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_etal_2017_ground_truth.csv
# Depends on: ground_truth/published_claims.csv, ground_truth/archive_values.csv,
#   maintained/output/, maintained/in_text_claims.R
# Description: Builds the ground truth. Every published value comes from
#   published_claims.csv, which is the hand extraction of the article and the only place a
#   published number is typed. Every rewrite value is read out of maintained/output/ by the
#   code below; none is transcribed. The verdicts are computed here rather than asserted.
#   The script ends with the coverage gate: it runs maintained/in_text_claims.R as a
#   program, counts the claims it prints against the extraction rows that require one, and
#   compares the two instruments value by value.
library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

# The extraction. value_paper is read as character so that the digits the article prints
# survive: parsed as a double, 0.5290 becomes 0.529 and the comparison loses the precision
# it is supposed to test.
claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                   col_types = cols(value_paper = col_character(),
                                    digits = col_integer(),
                                    needs_block = col_logical()))

# The deposited archive's own values, measured by running its three scripts on current R.
# Two entries are empty because experimental_analysis_main_text.R stops at a stale object
# name before reaching them. A portable extractor that reruns the deposit is not yet
# written, so this file is an input rather than a generated intermediate; every other
# column below is generated.
archive <- read_csv(here::here("ground_truth", "archive_values.csv"),
                    col_types = cols(claim_id = col_character(), value_script = col_double()))

table_1 <- out("table_1_attrition.csv")
table_2 <- out("table_2_outcome_means.csv")
table_3 <- out("table_3_bounds_main.csv")
table_a1 <- out("table_a1_mipo_effects.csv")
table_a1_gof <- out("table_a1_mipo_effects_gof.csv")
table_a2 <- out("table_a2_pairwise_bounds.csv")
figure_1 <- out("figure_1_simulation.csv")
figure_2 <- out("figure_2_sensitivity.csv")

# render: a number at a stated number of decimals, as the page would print it. A value that
# rounds to zero from below comes out of sprintf as "-0", which reads as a different number
# from the "0" the article carries, so the sign is dropped when nothing but zeros remain.
render <- function(x, digits) {
  printed <- sprintf(paste0("%.", digits, "f"), x)
  if_else(str_detect(printed, "^-0\\.?0*$"), str_remove(printed, "^-"), printed)
}

bound_suffix <- c(
  "95% CI Lower Bound" = "ci_lower",
  "95% CI Upper Bound" = "ci_upper",
  "Worst-Case Bound: Low Estimate" = "wcb_low",
  "Worst-Case Bound: High Estimate" = "wcb_high",
  "Variance of Low Estimate" = "var_low",
  "Variance of High Estimate" = "var_high"
)

# Published table cells ----

t1_values <- table_1 |>
  pivot_longer(-condition, names_to = "quantity", values_to = "value_rewrite") |>
  mutate(claim_id = str_c("t1_", str_to_lower(condition), "_", quantity)) |>
  select(claim_id, value_rewrite)

t2_values <- table_2 |>
  pivot_longer(-condition, names_to = "quantity", values_to = "value_rewrite") |>
  mutate(claim_id = str_c("t2_", str_to_lower(condition), "_", quantity)) |>
  select(claim_id, value_rewrite)

t3_values <- table_3 |>
  pivot_longer(-quantity, names_to = "column", values_to = "value_rewrite") |>
  mutate(claim_id = str_c("t3_", column, "_", bound_suffix[quantity])) |>
  select(claim_id, value_rewrite)

model_key <- c(
  "Perceived Polarization, Wave 1" = "pp_wave1",
  "Perceived Polarization, Wave 2" = "pp_wave2",
  "Extremity, Wave 1" = "ex_wave1",
  "Extremity, Wave 2" = "ex_wave2"
)
term_key <- c("(Intercept)" = "constant", "Z_levPlacebo" = "placebo",
              "Z_levPolarized" = "polarized")

ta1_values <- table_a1 |>
  select(model, term, coef = estimate, se = std.error) |>
  pivot_longer(c(coef, se), names_to = "quantity", values_to = "value_rewrite") |>
  mutate(claim_id = str_c("ta1_", term_key[term], "_", model_key[model], "_", quantity)) |>
  select(claim_id, value_rewrite)

ta1_gof_values <- table_a1_gof |>
  select(model, n = nobs, r2 = r.squared) |>
  pivot_longer(c(n, r2), names_to = "quantity", values_to = "value_rewrite") |>
  mutate(claim_id = str_c("ta1_all_", model_key[model], "_", quantity)) |>
  select(claim_id, value_rewrite)

pairwise_key <- c(
  pol_mod_pp = "pol_vs_mod_pp", pol_mod_ex = "pol_vs_mod_ex",
  pol_placebo_pp = "pol_vs_placebo_pp", pol_placebo_ex = "pol_vs_placebo_ex",
  mod_placebo_pp = "mod_vs_placebo_pp", mod_placebo_ex = "mod_vs_placebo_ex"
)

ta2_values <- table_a2 |>
  pivot_longer(-quantity, names_to = "column", values_to = "value_rewrite") |>
  mutate(claim_id = str_c("ta2_", pairwise_key[column], "_", bound_suffix[quantity])) |>
  select(claim_id, value_rewrite)

# Prose numbers ----
# Section 4.2 quotes Table 3 at two decimal places, states the naive estimate from
# Appendix Table 1, and derives two interval widths and the reduction between them.

bound_of <- function(d, row_label, column) {
  hits <- d[[column]][d$quantity == row_label]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

coef_of <- function(model_name, term_name, quantity) {
  hits <- table_a1[[quantity]][table_a1$model == model_name & table_a1$term == term_name]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

width_no_ds <- bound_of(table_3, "95% CI Upper Bound", "no_ds") -
  bound_of(table_3, "95% CI Lower Bound", "no_ds")
width_ds_ps <- bound_of(table_3, "95% CI Upper Bound", "ds_ps") -
  bound_of(table_3, "95% CI Lower Bound", "ds_ps")

delta_star <- figure_2$delta[figure_2$change_any]
stopifnot(length(delta_star) == 1)

total_row <- table_1 |> filter(condition == "Total")
arm_rows <- table_1 |> filter(condition != "Total")

prose_values <- tribble(
  ~claim_id, ~value_rewrite,
  "txt_naive_ate_coef", coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "estimate"),
  "txt_naive_ate_se", coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "std.error"),
  "txt_naive_ate_pval", coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "p.value"),
  "txt_no_ds_wcb_low", bound_of(table_3, "Worst-Case Bound: Low Estimate", "no_ds"),
  "txt_no_ds_wcb_high", bound_of(table_3, "Worst-Case Bound: High Estimate", "no_ds"),
  "txt_no_ds_ci_lower", bound_of(table_3, "95% CI Lower Bound", "no_ds"),
  "txt_no_ds_ci_upper", bound_of(table_3, "95% CI Upper Bound", "no_ds"),
  "txt_ds_wcb_low", bound_of(table_3, "Worst-Case Bound: Low Estimate", "ds"),
  "txt_ds_wcb_high", bound_of(table_3, "Worst-Case Bound: High Estimate", "ds"),
  "txt_ds_ps_wcb_low", bound_of(table_3, "Worst-Case Bound: Low Estimate", "ds_ps"),
  "txt_ds_ps_wcb_high", bound_of(table_3, "Worst-Case Bound: High Estimate", "ds_ps"),
  "txt_ds_ps_ci_lower", bound_of(table_3, "95% CI Lower Bound", "ds_ps"),
  "txt_ds_ps_ci_upper", bound_of(table_3, "95% CI Upper Bound", "ds_ps"),
  "txt_ci_width_no_ds", width_no_ds,
  "txt_ci_width_ds_ps", width_ds_ps,
  "txt_reduction_pct", (width_no_ds - width_ds_ps) / width_no_ds,
  "txt_delta_star", delta_star,
  "fig2_delta_star", delta_star,
  "app_n_subjects", total_row$n_initial,
  "app_n_responded", total_row$responded,
  "app_n_invited_per_arm", unique(arm_rows$invited),
  "app_n_invited", total_row$invited,
  "app_n_completed", total_row$responded_to_invitation,
  "appx_wave1_effect", coef_of("Perceived Polarization, Wave 1", "Z_levPolarized", "estimate"),
  "appx_wave2_effect", coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "estimate")
)

# Simulation design parameters the grid can answer ----
# Section 3 and Appendix Section 1 state the parameters of the simulation. The grid records
# most of them, so they are read back rather than asserted. The outcome means and variances
# are inputs to attrition:::ds_manski_cis_2s() that no output file carries; they are
# verified at the point of use in figure_1_simulation.R and carry no row here.

panel_sizes <- sort(unique(figure_1$n1))
main_panel <- figure_1 |> filter(n1 == panel_sizes[1])
scenarios <- sort(unique(figure_1$p1))
point_identified <- figure_1 |> filter(p2 == 1)

design_values <- tribble(
  ~claim_id, ~value_rewrite,
  "sim_n_total", 2 * panel_sizes[1],
  "sim_p1_min", min(figure_1$p1),
  "sim_p1_max", max(figure_1$p1),
  "sim_n_followup", unique(main_panel$n2),
  "sim_p2_min", min(figure_1$p2),
  "sim_p2_max", max(figure_1$p2),
  "sim_true_ate", unique(c(point_identified$estimate_lower, point_identified$estimate_upper)),
  "sim_n_scenarios", length(scenarios),
  "sim_p1_scenario_low", scenarios[1],
  "sim_p1_scenario_mid", scenarios[2],
  "sim_p1_scenario_high", scenarios[3],
  "appx_two_scenarios", length(panel_sizes),
  "appx_n_small", 2 * panel_sizes[1],
  "appx_n_large", 2 * panel_sizes[2],
  "appx_size_factor", panel_sizes[2] / panel_sizes[1],
  "appx_n2_small", unique(figure_1$n2[figure_1$n1 == panel_sizes[1]]),
  "appx_n2_large", unique(figure_1$n2[figure_1$n1 == panel_sizes[2]]),
  "appx_pairwise_columns", ncol(table_a2) - 1
)

# The two imputation limits Section 4.2 states are recoverable from the tables they
# produced: with the response rates of Table 1 and the initial-responder means of Table 2,
# the worst-case low and high estimates of Table 3 are two linear equations in them.
response_rate <- function(arm) {
  row <- table_1 |> filter(condition == arm)
  row$responded / row$n_initial
}
r_pol <- response_rate("Polarized")
r_mod <- response_rate("Moderate")
observed_difference <- r_pol * table_2$ir_mean[table_2$condition == "Polarized"] -
  r_mod * table_2$ir_mean[table_2$condition == "Moderate"]
imputation_limits <- solve(
  matrix(c(1 - r_pol, -(1 - r_mod), -(1 - r_mod), 1 - r_pol), nrow = 2, byrow = TRUE),
  c(bound_of(table_3, "Worst-Case Bound: Low Estimate", "no_ds") - observed_difference,
    bound_of(table_3, "Worst-Case Bound: High Estimate", "no_ds") - observed_difference)
)

design_values <- bind_rows(design_values, tribble(
  ~claim_id, ~value_rewrite,
  "app_outcome_min", imputation_limits[1],
  "app_outcome_max", imputation_limits[2]
))

# Descriptive claims ----
# A claim about shape, sign or count has no printed value, so its verdict is a truth value
# rather than a comparison. It is carried in holds, and match_rewrite stays NA.

sample_gaps <- table_2 |> mutate(scaled = abs(ds_mean - ir_mean) / ir_sd)
no_double_sampling <- main_panel |> filter(p2 == 0) |> mutate(implied = 2 * (1 - p1))
region_by_p1 <- main_panel |>
  select(p1, p2, bound_width) |>
  pivot_wider(names_from = p1, values_from = bound_width, names_prefix = "p1_")
shrinks <- main_panel |>
  arrange(p1, p2) |>
  group_by(p1) |>
  summarize(monotone = all(diff(bound_width) < 1e-9),
            ends_at_zero = last(bound_width) < 1e-9,
            .groups = "drop")
by_panel <- figure_1 |>
  select(n1, p1, p2, ci_width, bound_width) |>
  pivot_wider(names_from = n1, values_from = c(ci_width, bound_width))
extremity <- table_a1 |> filter(str_starts(model, "Extremity"), term != "(Intercept)")
no_ds_low <- bound_of(table_3, "Worst-Case Bound: Low Estimate", "no_ds")
no_ds_high <- bound_of(table_3, "Worst-Case Bound: High Estimate", "no_ds")
ds_low <- bound_of(table_3, "Worst-Case Bound: Low Estimate", "ds")
ds_high <- bound_of(table_3, "Worst-Case Bound: High Estimate", "ds")
wave1_effect <- coef_of("Perceived Polarization, Wave 1", "Z_levPolarized", "estimate")
wave2_effect <- coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "estimate")

descriptive_values <- tribble(
  ~claim_id, ~holds,
  "sim_point_identified", all(point_identified$bound_width < 1e-9),
  "sim_p2_zero_is_wcb",
    all(abs(no_double_sampling$bound_width - no_double_sampling$implied) < 1e-9),
  "sim_region_smaller_in_p1",
    all(region_by_p1$p1_0.25 > region_by_p1$p1_0.5 - 1e-9) &&
      all(region_by_p1$p1_0.5 > region_by_p1$p1_0.75 - 1e-9),
  "sim_width_shrinks_to_zero", all(shrinks$monotone) && all(shrinks$ends_at_zero),
  "appx_ci_shrinks_region_does_not",
    all(by_panel[[str_c("ci_width_", panel_sizes[2])]] <
          by_panel[[str_c("ci_width_", panel_sizes[1])]] + 1e-9) &&
      all(abs(by_panel[[str_c("bound_width_", panel_sizes[2])]] -
                by_panel[[str_c("bound_width_", panel_sizes[1])]]) < 1e-9),
  "app_samples_similar", all(sample_gaps$scaled < 0.5),
  "app_wcb_uninformative", no_ds_low < 0 && no_ds_high > 0,
  "app_ds_narrows",
    (ds_high - ds_low) < (no_ds_high - no_ds_low) &&
      (bound_of(table_3, "95% CI Upper Bound", "ds") -
         bound_of(table_3, "95% CI Lower Bound", "ds")) < width_no_ds,
  "app_naive_sig_10",
    coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "p.value") < 0.10,
  "app_no_delta_star_05",
    coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "conf.low") < 0 &&
      coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "conf.high") > 0,
  "appx_wave1_effect_strong",
    coef_of("Perceived Polarization, Wave 1", "Z_levPolarized", "p.value") < 0.01,
  "appx_effect_diminished", wave2_effect < wave1_effect / 2,
  "appx_extremity_negligible",
    all(abs(extremity$estimate) < extremity$std.error) && all(extremity$p.value > 0.10)
) |>
  mutate(holds = as.integer(holds))

rewrite_values <- bind_rows(t1_values, t2_values, t3_values, ta1_values, ta1_gof_values,
                            ta2_values, prose_values, design_values)
stopifnot(!any(duplicated(rewrite_values$claim_id)))
stopifnot(!any(duplicated(descriptive_values$claim_id)))

# Assembly ----
# Every extraction row that requires a claim block gets a ground-truth row, and nothing
# else does: a claim the pipeline cannot reach has no counterpart to compare against and
# would arrive here only as a published number typed into a file that is not allowed to
# hold one.

required <- claims |> filter(needs_block)

gt <- required |>
  left_join(rewrite_values, by = "claim_id") |>
  left_join(descriptive_values, by = "claim_id") |>
  left_join(archive, by = "claim_id") |>
  mutate(
    paper_id = "coppock_etal_2017",
    table_figure = location,
    extraction_string = value_paper,
    paper_number = parse_double(str_remove_all(value_paper, ",")),
    # A descriptive row carries no printed value and so no precision; sprintf still needs
    # a number, and nothing below reads the result on such a row.
    dg = replace_na(digits, 0L),
    printed_rewrite = if_else(is.na(value_rewrite), NA_character_,
                              render(value_rewrite, dg)),
    printed_script = if_else(is.na(value_script), NA_character_,
                             render(value_script, dg)),
    # The published string is rendered back from its own number at the digit count the
    # extraction records, so the committed file stores what the page prints rather than
    # what a double happens to deparse to.
    value_paper = if_else(is.na(paper_number), NA_character_,
                          render(paper_number, dg)),
    match = case_when(
      is.na(printed_script) | is.na(value_paper) ~ NA_integer_,
      printed_script == value_paper ~ 1L,
      TRUE ~ 0L
    ),
    match_rewrite = case_when(
      is.na(printed_rewrite) | is.na(value_paper) ~ NA_integer_,
      printed_rewrite == value_paper ~ 1L,
      TRUE ~ 0L
    )
  )

# The rendered published string must equal the string the extraction stores. Re-rendering
# alone cannot catch a digits entry that is right about the value and wrong about the
# precision: with 4 changed to 3 it would quietly rewrite the appendix R-squared of 0.0004
# as 0.000 on both sides of every comparison and nothing else would notice.
stopifnot(all(is.na(gt$value_paper) | gt$value_paper == gt$extraction_string))

# The two claims the archive stops before reaching are a failure of the deposit, not an
# absence of evidence: the script crashes at a stale object name four lines after building
# the object it means. That is a verdict, so it is recorded as one.
unreachable <- c("txt_reduction_pct", "txt_delta_star", "fig2_delta_star")

gt <- gt |>
  mutate(
    match = if_else(claim_id %in% unreachable, 0L, match),
    defect_locus = case_when(
      claim_id %in% unreachable ~ "archive",
      match == 0 | match_rewrite == 0 | holds == 0 ~ "unresolved",
      TRUE ~ NA_character_
    ),
    notes = case_when(
      claim_id %in% unreachable ~
        "experimental_analysis_main_text.R stops at 'mturk_results' before computing this; the rewrite substitutes the object the archive means and reproduces the published value",
      claim_type == "descriptive" ~
        "Descriptive claim: no printed value, verdict in holds",
      is.na(value_script) ~
        "No archive counterpart measured for this quantity",
      TRUE ~ NA_character_
    )
  )

# THE LOCUS RULE, three states. An adverse row, meaning either verdict is 0 or holds is 0,
# must carry a defect_locus. A clean match must not. A row with no verdict may.
adverse <- with(gt, (!is.na(match) & match == 0) |
                  (!is.na(match_rewrite) & match_rewrite == 0) |
                  (!is.na(holds) & holds == 0))
clean <- with(gt, (!is.na(match) & match == 1) &
                (!is.na(match_rewrite) & match_rewrite == 1) &
                (is.na(holds) | holds == 1))
stopifnot(all(!is.na(gt$defect_locus[adverse])))
stopifnot(all(is.na(gt$defect_locus[clean])))

# A published value with no rewrite counterpart is a mistyped label, not a finding, so it
# stops the build rather than becoming an unverifiable row.
stopifnot(all(gt$claim_type == "descriptive" | !is.na(gt$value_rewrite)))
stopifnot(all(gt$claim_type != "descriptive" | !is.na(gt$holds)))

gt <- gt |>
  select(paper_id, claim_id, table_figure, claim, claim_type, value_script, value_paper,
         match, value_rewrite, match_rewrite, holds, defect_locus, notes) |>
  arrange(table_figure, claim_id, .locale = "en")

write_csv(gt, here::here("ground_truth", "coppock_etal_2017_ground_truth.csv"), na = "")

# Coverage gate ----
# in_text_claims.R is run as a program, not read as text: a block that errors or prints
# nothing satisfies a textual check completely. It is sourced into its own environment,
# because both files necessarily read the same outputs and name objects for what they hold,
# so a bare source() would replace this script's own claims, out() and table_3 with the
# claims file's and leave the gate checking the wrong objects.
claims_log <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env())
)

parsed <- str_match(claims_log, "^CLAIM (\\S+) = (\\S+) \\|\\| (.*)$")
printed <- tibble(claim_id = parsed[, 2], printed_value = parsed[, 3]) |>
  filter(!is.na(claim_id))

declared <- claims$claim_id[claims$needs_block]
stopifnot(
  !any(duplicated(printed$claim_id)),
  nrow(printed) == length(declared),
  length(setdiff(declared, printed$claim_id)) == 0,
  length(setdiff(printed$claim_id, declared)) == 0
)

# The two instruments, compared value by value. They reach each number by separate paths
# from the same committed output, so a disagreement is a finding about one of them.
cross_check <- printed |>
  inner_join(select(gt, claim_id, value_rewrite, holds, claim_type), by = "claim_id") |>
  left_join(select(claims, claim_id, digits), by = "claim_id") |>
  mutate(
    dg = replace_na(digits, 0L),
    gt_printed = case_when(
      claim_type == "descriptive" ~ as.character(holds),
      is.na(value_rewrite) ~ "NA",
      TRUE ~ render(value_rewrite, dg)
    ),
    agrees = printed_value == gt_printed
  )

if (any(!cross_check$agrees)) print(filter(cross_check, !agrees), n = Inf, width = 200)
stopifnot(nrow(cross_check) == nrow(gt), all(cross_check$agrees))

print(gt, n = nrow(gt), width = 200)
print(tibble(
  quantity = c("extraction rows", "extraction rows needing a block", "ground truth rows",
               "archive comparable", "archive matching",
               "rewrite comparable", "rewrite matching", "rewrite differing",
               "descriptive claims", "descriptive claims holding",
               "claims printed by in_text_claims.R",
               "claims compared across the two instruments"),
  value = c(nrow(claims), length(declared), nrow(gt),
            sum(!is.na(gt$match)), sum(gt$match == 1, na.rm = TRUE),
            sum(!is.na(gt$match_rewrite)), sum(gt$match_rewrite == 1, na.rm = TRUE),
            sum(gt$match_rewrite == 0, na.rm = TRUE),
            sum(!is.na(gt$holds)), sum(gt$holds == 1, na.rm = TRUE),
            nrow(printed), nrow(cross_check))
))
