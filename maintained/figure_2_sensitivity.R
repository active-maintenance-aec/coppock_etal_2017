# coppock_etal_2017/maintained/figure_2_sensitivity.R
# Output: output/figure_2_sensitivity.pdf, output/figure_2_sensitivity.png,
#   output/figure_2_sensitivity.csv
# Depends on: original/levendusky_mturk_clean.csv, helpers.R
# Description: Figure 2: sensitivity of the Polarized versus Moderate bounds to violations
#   of ignorability among the follow-up nonrespondents, indexed by the mixing parameter
#   delta, together with the delta star at which the 90% interval first covers zero.
source(here::here("maintained", "helpers.R"))

pol_vs_mod <- mturk |> filter(!is.na(Z1))

# delta = 0 is the naive estimate that assumes ignorability among follow-up
# nonrespondents; delta = 1 is the worst-case bound. sensitivity_ds() evaluates 100
# equally spaced values in between at the 10% significance level, as the paper does.
sensitivity <- sensitivity_ds(
  Y = L_dif_w2, Z = Z1, R1 = R1, R2 = R2, Attempt = Attempt,
  minY = 0, maxY = 6, alpha = 0.10,
  data = pol_vs_mod
)

sims <- as_tibble(sensitivity$sims_df)
print(sims)

write_csv(sims, here::here("maintained", "output", "figure_2_sensitivity.csv"))

# The figure is rebuilt here from sims rather than taken from the ggplot object
# sensitivity_ds() returns, so that everything drawn is produced by this repository.
# delta* comes off the returned list, which reports the smallest crossing as a single
# number and NA when the interval covers zero throughout.
delta_star <- sensitivity$delta_star

endpoints <- tibble(
  delta = c(0, 1, 1),
  value = c(
    sims$estimate_lower[sims$delta == 0],
    sims$estimate_lower[sims$delta == 1],
    sims$estimate_upper[sims$delta == 1]
  ),
  label = c("Naive Estimate", "Worst Case Lower Bound", "Worst Case Upper Bound"),
  hjust = c(-0.3, 1.1, 1.1),
  vjust = c(NA, 1, -1)
)

delta_star_point <- tibble(
  delta = delta_star,
  value = 0,
  label = paste0("delta^'*' == ", sprintf("%.2f", delta_star))
)

g <- ggplot(sims, aes(x = delta)) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.2) +
  geom_line(aes(y = estimate_lower), alpha = 0.5) +
  geom_line(aes(y = estimate_upper), alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(data = endpoints, aes(y = value)) +
  geom_text(data = endpoints,
            aes(y = value, label = label, hjust = hjust, vjust = vjust)) +
  geom_point(data = delta_star_point, aes(y = value)) +
  geom_text(data = delta_star_point, aes(y = value, label = label),
            parse = TRUE, vjust = 1.3) +
  labs(
    x = expression(paste("Sensitivity Parameter ", delta, " (0 = Ignorability)")),
    y = "Identification Regions and 90% Confidence Intervals"
  ) +
  theme_bw()

ggsave(here::here("maintained", "output", "figure_2_sensitivity.pdf"),
       g, width = 7, height = 5)
ggsave(here::here("maintained", "output", "figure_2_sensitivity.png"),
       g, width = 7, height = 5, dpi = 300)
