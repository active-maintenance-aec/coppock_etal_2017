# coppock_etal_2017/maintained/figure_1_simulation.R
# Output: output/figure_1_simulation.pdf, output/figure_1_simulation.png,
#   output/figure_a1_simulation.pdf, output/figure_a1_simulation.png,
#   output/figure_1_simulation.csv
# Depends on: helpers.R
# Description: Figure 1 and Appendix Figure 1: identification region and expected 95%
#   confidence interval for the ATE as a function of the follow-up response rate.
#   Both figures come from one simulation grid and differ only in which sample sizes they
#   show, so they are produced together rather than by two scripts.
source(here::here("maintained", "helpers.R"))

# Simulation grid ----
# The outcome is on a 0 to 1 scale with means of 0.5 and standard deviations of 0.5 in
# every cell, so the true ATE is zero throughout and the intervals are driven entirely by
# the response rates. p1 is the initial response rate and p2 the follow-up response rate,
# both held equal across arms. The two sample sizes are 400 and 40,000 per arm, giving the
# N1 = 800 panel the main text shows and the N1 = 80,000 panel added in the appendix.
sim_grid <- expand_grid(
  tibble(n1 = c(400, 40000), n2 = c(50, 5000)),
  p1 = c(0.25, 0.50, 0.75),
  p2 = seq(0, 1, length.out = 1000)
)

# ds_manski_cis_2s() is internal to attrition and is the function the paper's own
# simulation script calls. Its c1a_t, c1r_t, c2a_t and c2r_t arguments are unused cost
# parameters; the archive passes four undefined objects into them, which survives only
# because R never evaluates an argument the body does not touch. They are omitted here.
simulate_cis <- function(n1, n2, p1, p2) {
  out <- attrition:::ds_manski_cis_2s(
    n1_t = n1, n2_t = n2, n1_c = n1, n2_c = n2,
    p1_t = p1, p2_t = p2, p1_c = p1, p2_c = p2,
    s1_t = 0.5, s1_c = 0.5, s2_nm_t = 0.5, s2_nm_c = 0.5,
    y1m_t = 0.5, y1m_c = 0.5, y2m_nm_t = 0.5, y2m_nm_c = 0.5,
    minY = 0, maxY = 1, alpha = 0.05
  )
  as_tibble_row(out)
}

sim_results <- sim_grid |>
  mutate(pmap(list(n1, n2, p1, p2), simulate_cis) |> list_rbind()) |>
  mutate(
    ci_width = ci_upper - ci_lower,
    bound_width = upp_est - low_est,
    n_label = paste0("N[1] == ", 2 * n1)
  )

write_csv(sim_results, here::here("maintained", "output", "figure_1_simulation.csv"))

# Left panel: the intervals themselves ----
intervals <- sim_results |>
  pivot_longer(c(ci_lower, ci_upper, low_est, upp_est),
               names_to = "series", values_to = "value") |>
  mutate(type = if_else(series %in% c("ci_lower", "ci_upper"),
                        "95% Confidence Interval", "Identification Region"))

interval_labels <- tibble(
  p2 = c(0.05, 0.0375, 0.05),
  value = c(-0.65, -0.4, -0.15),
  p1 = c(0.25, 0.50, 0.75),
  label = paste0("p[1] == ", c("0.25", "0.50", "0.75"))
)

g_intervals <- ggplot(
  filter(intervals, n1 == 400),
  aes(x = p2, y = value, group = interaction(series, p1),
      linetype = type, color = as.factor(p1))
) +
  geom_line() +
  geom_text(data = interval_labels,
            aes(label = label, group = NULL, linetype = NULL),
            parse = TRUE) +
  coord_cartesian(xlim = c(0, 1), ylim = c(-1, 1)) +
  scale_linetype_manual(values = c("dashed", "solid")) +
  scale_color_grey(start = 0.4, end = 0, guide = "none") +
  labs(
    x = expression(paste("Follow-up Sample Response Rate (", p[2], ")")),
    y = "Identification Region and Expected 95% Confidence Interval",
    title = expression(paste("Intervals for ATE vs ", p[2])),
    linetype = NULL
  ) +
  theme_bw() +
  theme(legend.position = "bottom", legend.key.width = unit(3, "lines"))

# Right panel: the widths of those intervals ----
widths <- sim_results |>
  pivot_longer(c(ci_width, bound_width), names_to = "series", values_to = "width") |>
  mutate(type = if_else(series == "ci_width",
                        "95% Confidence Interval", "Identification Region"))

width_labels <- tibble(
  p2 = c(0.05, 0.0375, 0.05),
  width = c(1.60, 1.1, 0.6),
  p1 = c(0.25, 0.50, 0.75),
  label = paste0("p[1] == ", c("0.25", "0.5", "0.75"))
)

g_widths <- ggplot(
  filter(widths, n1 == 400),
  aes(x = p2, y = width, group = interaction(series, p1),
      linetype = type, color = as.factor(p1))
) +
  geom_line() +
  geom_text(data = width_labels,
            aes(label = label, group = NULL, linetype = NULL),
            parse = TRUE, nudge_y = 0.1) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 2)) +
  scale_linetype_manual(values = c("dashed", "solid")) +
  scale_color_grey(start = 0.4, end = 0, guide = "none") +
  labs(
    x = expression(paste("Follow-up Sample Response Rate (", p[2], ")")),
    y = "Width of Identification Region and Expected 95% Confidence Interval",
    title = expression(paste("Width of Intervals for ATE vs ", p[2])),
    linetype = NULL
  ) +
  theme_bw() +
  theme(legend.position = "bottom", legend.key.width = unit(3, "lines"))

# Side-by-side panels ----
# Figure 1 shows N1 = 800 alone; Appendix Figure 1 facets both sample sizes.
# arrangeGrob replaces the archive's hand-rolled multiplot(), and turning a ggplot into a
# grob needs an open graphics device to measure text, which under Rscript would otherwise
# leave a stray Rplots.pdf in the working directory.
facet_by_n <- list(
  facet_wrap(~n_label, nrow = 2, labeller = label_parsed),
  theme(strip.background = element_blank())
)

pdf(NULL)
figure_1 <- arrangeGrob(g_intervals, g_widths, ncol = 2)
figure_a1 <- arrangeGrob(
  g_intervals + intervals + facet_by_n,
  g_widths + widths + facet_by_n,
  ncol = 2
)
dev.off()

ggsave(here::here("maintained", "output", "figure_1_simulation.pdf"),
       figure_1, width = 11, height = 6.5)
ggsave(here::here("maintained", "output", "figure_1_simulation.png"),
       figure_1, width = 11, height = 6.5, dpi = 300)

ggsave(here::here("maintained", "output", "figure_a1_simulation.pdf"),
       figure_a1, width = 12, height = 10)
ggsave(here::here("maintained", "output", "figure_a1_simulation.png"),
       figure_a1, width = 12, height = 10, dpi = 300)
