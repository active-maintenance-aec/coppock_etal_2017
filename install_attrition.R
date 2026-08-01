# coppock_etal_2017/install_attrition.R
# Output: none (installs the attrition package if it is absent)
# Depends on: original/attrition_0.0.0.9000.tar.gz, fetched by download_original.R
# Description: The method this paper proposes is implemented in the attrition package,
#   which has never been on CRAN. The deposit bundles the source tarball of the version
#   the authors used, and download_original.R verifies its checksum, so installing from
#   that tarball is the one route to the package that does not depend on a GitHub
#   repository staying where it is. If attrition is already installed this does nothing.
#
#   The current GitHub version calls itself 0.1.0 and returns numerically identical
#   estimates to the deposited 0.0.0.9000 for every quantity in this repository, checked
#   to twelve significant figures. Either version reproduces the published numbers.

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
