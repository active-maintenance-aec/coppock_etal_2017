# coppock_etal_2017/maintained/in_text_claims.R
# Output: printed CLAIM lines only; no files
# Depends on: maintained/output/, ground_truth/published_claims.csv
# Description: One block per published claim, each carrying the article's own sentence and
#   then recomputing the number from the pipeline's committed output. This is the second
#   instrument. It never reads ground_truth/coppock_etal_2017_ground_truth.csv, it never
#   refits a model, and it reaches every quantity by its own path, so where it and the
#   ground truth disagree one of them is wrong. In particular the prose numbers of
#   Section 4.2 are derived here from table_3_bounds_main.csv and table_a1_mipo_effects.csv
#   rather than read out of text_section_4_claims.csv, which is the file the ground truth
#   reads, so the two derivations are genuinely separate.
#
#   Every block prints a line of the form
#
#       CLAIM <claim_id> = <value> || <label>
#
#   which ground_truth/check_claims.R parses to check coverage against
#   ground_truth/published_claims.csv. The value is printed at the number of decimals that
#   file records for the claim, so it can be laid against the page without a second
#   rounding. A descriptive claim, which states a shape rather than a number, prints 1 when
#   it holds and 0 when it does not.
#
#   Quotes are the sentences the article prints. The published PDF has no text layer for
#   its mathematical symbols, so the quotes below write delta star as "delta*" and the
#   minus sign as "-".
source(here::here("maintained", "helpers.R"))
library(excheckr)

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))

# The scoring machinery comes from excheckr, which carries the verdict ladder, the
# typography parser and the printed form this file used to define for itself. What is
# passed here is what the package cannot know: the extraction, the column its prose
# descriptions live in, and the shape of the printed line. format = "id" is the
# CLAIM <id> = <value> || [verdict] <label> line ground_truth/build_ground_truth.R
# parses, and it must stay exactly that.
#
# The precision is no longer named twice. It used to be read out of the extraction's
# digits column on the stated grounds that value_paper could not be trusted to carry it;
# measured on 2026-08-20, claim_digits() reproduces all 199 of this file's declared
# digits from the typography of value_paper alone, so the column was recording what the
# article's own statement already said. This article prints neighbouring cells at three
# and four decimals and one appendix R-squared at three beside its neighbour at four,
# which is the case reading the typography gets right and a rule from the value cannot.
#
# There is no errata note for this paper, so no claim here can reach corrected, STALE or
# DRIFT, and the gate that needs the spine reports itself skipped.
claim_start(published = published, format = "id", label_column = "claim")

table_1 <- out("table_1_attrition.csv")
table_2 <- out("table_2_outcome_means.csv")
table_3 <- out("table_3_bounds_main.csv")
table_a1 <- out("table_a1_mipo_effects.csv")
table_a1_gof <- out("table_a1_mipo_effects_gof.csv")
table_a2 <- out("table_a2_pairwise_bounds.csv")
figure_1 <- out("figure_1_simulation.csv")
figure_2 <- out("figure_2_sensitivity.csv")

# bound_of: one cell of a bounds table, identified by its printed row label and its column.
bound_of <- function(d, row_label, column) {
  hits <- d[[column]][d$quantity == row_label]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

# coef_of: one coefficient or standard error from the appendix regression table.
coef_of <- function(model_name, term_name, quantity) {
  hits <- table_a1[[quantity]][table_a1$model == model_name & table_a1$term == term_name]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

# Section 3: Simulation Study ----

# "The parameters are as follows: 800 units are split evenly between treatment and
# control."
main_panel <- figure_1 |> filter(n1 == min(n1))
claim("sim_n_total", 2 * unique(main_panel$n1))

# "We vary the proportion p 1 that responds in the initial sample in each group from 0.25
# to 0.75."
claim("sim_p1_min", min(figure_1$p1))
claim("sim_p1_max", max(figure_1$p1))

# "We sample exactly 50 of the missing control units and 50 of the missing treatment units
# in the follow-up sample; we vary the proportion p 2 that responds in the follow-up sample
# from 0 to 1."
claim("sim_n_followup", unique(main_panel$n2))
claim("sim_p2_min", min(figure_1$p2))
claim("sim_p2_max", max(figure_1$p2))

# "In our simulation, the true ATE is equal to 0."
# At a follow-up response rate of 1 nothing is imputed, so the identification region
# collapses onto the true effect and the grid states it rather than assuming it.
point_identified <- figure_1 |> filter(p2 == 1)
claim("sim_true_ate", unique(c(point_identified$estimate_lower, point_identified$estimate_upper)))

# "We consider three scenarios, corresponding to an initial sample response rate of 0.25,
# 0.50, or 0.75."
scenarios <- sort(unique(figure_1$p1))
claim("sim_n_scenarios", length(scenarios))
claim("sim_p1_scenario_low", scenarios[1])
claim("sim_p1_scenario_mid", scenarios[2])
claim("sim_p1_scenario_high", scenarios[3])

# "When p 2 is equal to 1 - all subjects respond in the follow-up sample - the ATE is point
# identified."
claim("sim_point_identified", as.integer(all(point_identified$bound_width < 1e-9)), digits = 0)

# "When p 2 is equal to zero, the intervals are the same as the worst-case intervals that
# would be obtained in the absence of double sampling."
# Without double sampling the worst-case region for an outcome bounded in [0, 1] is a
# missingness rate wide in each arm, so its width is 2(1 - p1).
no_double_sampling <- main_panel |>
  filter(p2 == 0) |>
  mutate(implied = 2 * (1 - p1))
claim("sim_p2_zero_is_wcb",
      as.integer(all(abs(no_double_sampling$bound_width - no_double_sampling$implied) < 1e-9)), digits = 0)

# "As the initial sample response rate increases, the identification region gets smaller."
region_by_p1 <- main_panel |>
  select(p1, p2, bound_width) |>
  pivot_wider(names_from = p1, values_from = bound_width, names_prefix = "p1_")
claim("sim_region_smaller_in_p1",
      as.integer(all(region_by_p1$p1_0.25 > region_by_p1$p1_0.5 - 1e-9) &&
                 all(region_by_p1$p1_0.5 > region_by_p1$p1_0.75 - 1e-9)), digits = 0)

# "The width of this region shrinks to 0 as the follow-up sample response rate increases."
shrinks <- main_panel |>
  arrange(p1, p2) |>
  group_by(p1) |>
  summarize(monotone = all(diff(bound_width) < 1e-9),
            ends_at_zero = last(bound_width) < 1e-9,
            .groups = "drop")
claim("sim_width_shrinks_to_zero",
      as.integer(all(shrinks$monotone) && all(shrinks$ends_at_zero)), digits = 0)

# Section 4.1: Attrition and double sampling ----

# "Our experiment comprises 1,980 subjects, of which 1,444 had nonmissing responses in the
# initial sample."
total_row <- table_1 |> filter(condition == "Total")
claim("app_n_subjects", total_row$n_initial)
claim("app_n_responded", total_row$responded)

# "We assigned exactly 50 nonrespondents at random from each treatment group to the
# follow-up sample. ... Of these 100 subjects, 72 completed the Wave 2 survey."
arms <- table_1 |> filter(condition != "Total")
claim("app_n_invited_per_arm", unique(arms$invited))
claim("app_n_invited", total_row$invited)
claim("app_n_completed", total_row$responded_to_invitation)

# Section 4.2: Results ----

# "A naive analysis (using the difference-in-means estimator only among those who responded
# in the first round) would conclude that the effect of the polarized condition was to
# raise average outcomes by 0.126 (SE: 0.066, two-sided p-value: 0.057)."
claim("txt_naive_ate_coef",
      coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "estimate"))
claim("txt_naive_ate_se",
      coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "std.error"))
claim("txt_naive_ate_pval",
      coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "p.value"))

# "Table 2 also shows that the average outcomes in the initial and follow-up samples do not
# differ dramatically."
# The largest gap between an initial-responder mean and its double-sampled counterpart is
# well inside one standard deviation of the initial sample.
sample_gaps <- table_2 |>
  mutate(gap = abs(ds_mean - ir_mean), scaled = gap / ir_sd)
claim("app_samples_similar", as.integer(all(sample_gaps$scaled < 0.5)), digits = 0)

# "To estimate a lower bound on the ATE using responses only from Wave 2 without any double
# sampling, we replace missing outcomes in the Polarized group with the lowest possible
# values (0) and missing outcomes in the Moderate group with the highest possible values
# (6)."
# The two imputation limits are recoverable from the tables they produced: with response
# rates from Table 1 and initial-responder means from Table 2, the worst-case low and high
# estimates in Table 3 are two linear equations in the two limits.
response_rate <- function(arm) {
  row <- table_1 |> filter(condition == arm)
  row$responded / row$n_initial
}
mean_of <- function(arm) table_2$ir_mean[table_2$condition == arm]

r_pol <- response_rate("Polarized")
r_mod <- response_rate("Moderate")
observed_difference <- r_pol * mean_of("Polarized") - r_mod * mean_of("Moderate")
imputation_weights <- matrix(
  c(1 - r_pol, -(1 - r_mod),
    -(1 - r_mod), 1 - r_pol),
  nrow = 2, byrow = TRUE
)
imputation_limits <- solve(
  imputation_weights,
  c(bound_of(table_3, "Worst-Case Bound: Low Estimate", "no_ds") - observed_difference,
    bound_of(table_3, "Worst-Case Bound: High Estimate", "no_ds") - observed_difference)
)
claim("app_outcome_min", imputation_limits[1])
claim("app_outcome_max", imputation_limits[2])

# "The bounds, as expected, are so wide as to be of little probative value. The estimated
# bounds are (-1.54, 1.71) and the associated 95% confidence interval equals (-1.67, 1.84)."
claim("txt_no_ds_wcb_low", bound_of(table_3, "Worst-Case Bound: Low Estimate", "no_ds"))
claim("txt_no_ds_wcb_high", bound_of(table_3, "Worst-Case Bound: High Estimate", "no_ds"))
claim("txt_no_ds_ci_lower", bound_of(table_3, "95% CI Lower Bound", "no_ds"))
claim("txt_no_ds_ci_upper", bound_of(table_3, "95% CI Upper Bound", "no_ds"))

# A region that spans zero and covers more than half the outcome scale's plausible effect
# range says nothing about the sign of the effect.
no_ds_low <- bound_of(table_3, "Worst-Case Bound: Low Estimate", "no_ds")
no_ds_high <- bound_of(table_3, "Worst-Case Bound: High Estimate", "no_ds")
ds_low <- bound_of(table_3, "Worst-Case Bound: Low Estimate", "ds")
ds_high <- bound_of(table_3, "Worst-Case Bound: High Estimate", "ds")
claim("app_wcb_uninformative", as.integer(no_ds_low < 0 && no_ds_high > 0), digits = 0)

# "Our proposed method, double sampling combined with worst-case bounds, leads to dramatic
# reductions in the widths of the worst-case bounds and the associated 95% confidence
# intervals."
claim("app_ds_narrows",
      as.integer((ds_high - ds_low) < (no_ds_high - no_ds_low) &&
                 (bound_of(table_3, "95% CI Upper Bound", "ds") -
                    bound_of(table_3, "95% CI Lower Bound", "ds")) <
                   (bound_of(table_3, "95% CI Upper Bound", "no_ds") -
                      bound_of(table_3, "95% CI Lower Bound", "no_ds"))), digits = 0)

# "The double sampling identification region for the ATE is estimated to be (-0.34, 0.57).
# Adjusting for party identification by poststratification yields estimated bounds of
# (-0.34, 0.53) with an associated 95% confidence interval equal to (-0.53, 0.70)."
claim("txt_ds_wcb_low", ds_low)
claim("txt_ds_wcb_high", ds_high)
claim("txt_ds_ps_wcb_low", bound_of(table_3, "Worst-Case Bound: Low Estimate", "ds_ps"))
claim("txt_ds_ps_wcb_high", bound_of(table_3, "Worst-Case Bound: High Estimate", "ds_ps"))
claim("txt_ds_ps_ci_lower", bound_of(table_3, "95% CI Lower Bound", "ds_ps"))
claim("txt_ds_ps_ci_upper", bound_of(table_3, "95% CI Upper Bound", "ds_ps"))

# "Whereas the width of the 95% confidence interval using only the initial sample equals
# 3.50, double sampling with poststratification reduces it to 1.23, for a 65 percent
# reduction in confidence interval width."
width_no_ds <- bound_of(table_3, "95% CI Upper Bound", "no_ds") -
  bound_of(table_3, "95% CI Lower Bound", "no_ds")
width_ds_ps <- bound_of(table_3, "95% CI Upper Bound", "ds_ps") -
  bound_of(table_3, "95% CI Lower Bound", "ds_ps")
claim("txt_ci_width_no_ds", width_no_ds)
claim("txt_ci_width_ds_ps", width_ds_ps)
claim("txt_reduction_pct", (width_no_ds - width_ds_ps) / width_no_ds)

# Section 4.3: Sensitivity ----

# "As shown in Figure 2, we obtain a delta* of 0.07, implying that the statistically
# significant (at the 10% level) naive estimate is very sensitive to even small violations
# of ignorability."
delta_star <- figure_2$delta[figure_2$change_any]
stopifnot(length(delta_star) == 1)
claim("txt_delta_star", delta_star)
claim("fig2_delta_star", delta_star)
claim("app_naive_sig_10",
      as.integer(coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "p.value") < 0.10), digits = 0)

# "If we conduct our sensitivity analysis at the 5% level of statistical significance,
# delta* does not exist, because the 95% confidence interval around the naive estimate
# contains zero."
naive_low <- coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "conf.low")
naive_high <- coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "conf.high")
claim("app_no_delta_star_05", as.integer(naive_low < 0 && naive_high > 0), digits = 0)

# Appendix Section 1: Simulation Study at a larger sample size ----

# "We consider two scenarios: the first uses a total of 800 subjects and is identical to the
# scenario presented in the main text. The second increases the sample size 100-fold to
# 80,000 subjects. Instead of sampling 50 of the missing in each arm in the follow-up
# sample, we sample 5,000 of the missing."
panel_sizes <- sort(unique(figure_1$n1))
claim("appx_two_scenarios", length(panel_sizes))
claim("appx_n_small", 2 * panel_sizes[1])
claim("appx_n_large", 2 * panel_sizes[2])
claim("appx_size_factor", panel_sizes[2] / panel_sizes[1])
claim("appx_n2_small", unique(figure_1$n2[figure_1$n1 == panel_sizes[1]]))
claim("appx_n2_large", unique(figure_1$n2[figure_1$n1 == panel_sizes[2]]))

# "The implications are clear: the 95% confidence intervals shrink with increased sample
# size, but the identification region does not."
by_panel <- figure_1 |>
  select(n1, p1, p2, ci_width, bound_width) |>
  pivot_wider(names_from = n1, values_from = c(ci_width, bound_width))
ci_small <- by_panel[[str_c("ci_width_", panel_sizes[1])]]
ci_large <- by_panel[[str_c("ci_width_", panel_sizes[2])]]
region_small <- by_panel[[str_c("bound_width_", panel_sizes[1])]]
region_large <- by_panel[[str_c("bound_width_", panel_sizes[2])]]
claim("appx_ci_shrinks_region_does_not",
      as.integer(all(ci_large < ci_small + 1e-9) &&
                 all(abs(region_large - region_small) < 1e-9)), digits = 0)

# Appendix Section 2: Analysis Assuming MIPO ----

# "We observe strong average effect of the Polarized treatment on Perceived Polarization in
# Wave 1 (0.468 points). This effect is much diminished by Wave 2, descending to 0.126 over
# the course of 10 days."
wave1_effect <- coef_of("Perceived Polarization, Wave 1", "Z_levPolarized", "estimate")
wave2_effect <- coef_of("Perceived Polarization, Wave 2", "Z_levPolarized", "estimate")
claim("appx_wave1_effect", wave1_effect)
claim("appx_wave2_effect", wave2_effect)
claim("appx_wave1_effect_strong",
      as.integer(coef_of("Perceived Polarization, Wave 1", "Z_levPolarized", "p.value") < 0.01), digits = 0)
claim("appx_effect_diminished", as.integer(wave2_effect < wave1_effect / 2), digits = 0)

# "The treatment appears to have had negligible average effects on Extremity across both
# waves of measurement."
extremity <- table_a1 |>
  filter(str_starts(model, "Extremity"), term != "(Intercept)")
claim("appx_extremity_negligible",
      as.integer(all(abs(extremity$estimate) < extremity$std.error) &&
                 all(extremity$p.value > 0.10)), digits = 0)

# Appendix Section 3: Worst-case Bounds for All Pairwise Comparisons ----

# "In our preanalysis plan (available on egap.org), we indicated that we would present
# worst-case bounds for all pairwise comparisons for both dependent variables."
claim("appx_pairwise_columns", ncol(table_a2) - 1)

# Table 1: Attrition by treatment condition ----
# covers: t1_*
# One line per published cell. Fifteen cells, all counts.
walk2(
  rep(table_1$condition, each = 5),
  rep(c("n_initial", "responded", "did_not_respond", "invited", "responded_to_invitation"),
      times = nrow(table_1)),
  \(arm, quantity) claim(
    str_c("t1_", str_to_lower(arm), "_", quantity),
    table_1[[quantity]][table_1$condition == arm]
  )
)

# Table 2: Outcome summaries by condition and response type ----
# covers: t2_*
walk2(
  rep(table_2$condition, each = 6),
  rep(c("ir_mean", "ir_sd", "ir_n", "ds_mean", "ds_sd", "ds_n"), times = nrow(table_2)),
  \(arm, quantity) claim(
    str_c("t2_", str_to_lower(arm), "_", quantity),
    table_2[[quantity]][table_2$condition == arm]
  )
)

# Table 3: Replication study results ----
# covers: t3_*
bound_suffix <- c(
  "95% CI Lower Bound" = "ci_lower",
  "95% CI Upper Bound" = "ci_upper",
  "Worst-Case Bound: Low Estimate" = "wcb_low",
  "Worst-Case Bound: High Estimate" = "wcb_high",
  "Variance of Low Estimate" = "var_low",
  "Variance of High Estimate" = "var_high"
)
walk(c("no_ds", "ds", "ds_ps"), \(column) {
  walk(table_3$quantity, \(row_label) {
    claim(str_c("t3_", column, "_", bound_suffix[[row_label]]),
          bound_of(table_3, row_label, column))
  })
})

# Appendix Table 1: Immediate and Over Time Effects of Treatment ----
# covers: ta1_*
model_key <- c(
  "Perceived Polarization, Wave 1" = "pp_wave1",
  "Perceived Polarization, Wave 2" = "pp_wave2",
  "Extremity, Wave 1" = "ex_wave1",
  "Extremity, Wave 2" = "ex_wave2"
)
term_key <- c("(Intercept)" = "constant", "Z_levPlacebo" = "placebo",
              "Z_levPolarized" = "polarized")
walk(names(model_key), \(model_name) {
  walk(names(term_key), \(term_name) {
    stem <- str_c("ta1_", term_key[[term_name]], "_", model_key[[model_name]])
    claim(str_c(stem, "_coef"), coef_of(model_name, term_name, "estimate"))
    claim(str_c(stem, "_se"), coef_of(model_name, term_name, "std.error"))
  })
})
walk(names(model_key), \(model_name) {
  row <- table_a1_gof |> filter(model == model_name)
  stopifnot(nrow(row) == 1)
  claim(str_c("ta1_all_", model_key[[model_name]], "_n"), row$nobs)
  claim(str_c("ta1_all_", model_key[[model_name]], "_r2"), row$r.squared)
})

# Appendix Table 2: Double Sampling Bounds for Pairwise Comparisons ----
# covers: ta2_*
pairwise_key <- c(
  pol_mod_pp = "pol_vs_mod_pp", pol_mod_ex = "pol_vs_mod_ex",
  pol_placebo_pp = "pol_vs_placebo_pp", pol_placebo_ex = "pol_vs_placebo_ex",
  mod_placebo_pp = "mod_vs_placebo_pp", mod_placebo_ex = "mod_vs_placebo_ex"
)
walk(names(pairwise_key), \(column) {
  walk(table_a2$quantity, \(row_label) {
    claim(str_c("ta2_", pairwise_key[[column]], "_", bound_suffix[[row_label]]),
          bound_of(table_a2, row_label, column))
  })
})

# Gates ----
# The verdicts above are assertions only if something reads them. assert_claims() is
# what reads them: no claim ended on a failing verdict, every claim a quantity erratum
# names was printed and printed as corrected, the claims printed are exactly those the
# extraction declares need a block, and the verdict counts partition the claims. This
# paper has no errata note, so the second reports itself skipped rather than passing
# quietly.
assert_claims()

# The exemptions are counted, never merely allowed. A claim scored [shape] is one this
# file declines to assert, and a file that let that set grow in silence would report the
# same clean run whether it checked every claim or none.
invisible(claim_summary())
