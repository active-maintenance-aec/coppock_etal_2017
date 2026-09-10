# coppock_etal_2017/install_attrition.R
# Output: none (installs the attrition package if it is absent)
# Depends on: original/attrition_0.0.0.9000.tar.gz, fetched by download_original.R
# Description: The method this paper proposes is implemented in the attrition package,
#   which has never been on CRAN. The deposit bundles the source tarball of the version
#   the authors used, and download_original.R verifies its checksum, so installing from
#   that tarball is the one route to the package that does not depend on a GitHub
#   repository staying where it is. If attrition is already installed this does nothing.
#
#   The deposited 0.0.0.9000 is what the scripts in original/ are written against and it
#   still runs them. The maintained rewrite is written against the current package, which
#   as of 1.0.0 returns its six quantities under broom's names (estimate_lower,
#   estimate_upper, std.error_lower, std.error_upper, conf.low, conf.high) and reports
#   the uncertainty as a standard error where earlier versions reported a variance. A
#   result from an older attrition carries none of those names, so the rewrite would fill
#   its tables with NA rather than fail. The version gate below turns that into a halt.

library(here)

here::i_am("install_attrition.R")

if (requireNamespace("attrition", quietly = TRUE)) {
  print(paste("attrition", packageVersion("attrition"), "already installed."))
} else {
  install.packages(
    here::here("original", "attrition_0.0.0.9000.tar.gz"),
    repos = NULL,
    type = "source"
  )
}

# Version gate ----
# Checked by name rather than by version number, because the requirement is about the
# return vocabulary rather than about a release: any build that returns these names will
# do, and a version comparison would have to be revised every time the package moves.
required_names <- c("estimate_lower", "estimate_upper",
                    "std.error_lower", "std.error_upper", "conf.low", "conf.high")
probe <- attrition::estimator_ev(
  Y = c(1, 2, NA, 4), Z = c(0, 0, 1, 1), R = c(1, 1, 0, 1),
  minY = 0, maxY = 6, data = data.frame(Y = c(1, 2, NA, 4),
                                        Z = c(0, 0, 1, 1),
                                        R = c(1, 1, 0, 1))
)
if (!all(required_names %in% names(probe))) {
  stop(
    "The maintained rewrite needs attrition 1.0.0 or later, and the installed version is ",
    packageVersion("attrition"), ", whose estimators return ",
    paste(names(probe), collapse = ", "), ".\n",
    "  Install the current package with ",
    "remotes::install_github(\"acoppock/attrition\"), or run the scripts in original/, ",
    "which are written against the deposited 0.0.0.9000 and still work with it.",
    call. = FALSE
  )
}
