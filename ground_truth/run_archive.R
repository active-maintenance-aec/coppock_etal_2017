# coppock_etal_2017/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first), original_manifest.csv
# Description: Runs every deposited script, each in a clean R session, from a scratch
#   copy of original/ and against the two package tarballs the deposit bundles, and
#   records how each one ends and which files the run writes.
#
#   The deposit is three analysis scripts, one data file, two package tarballs, and a
#   README. It ships no derived object, so a copy stripped to data plus code is the copy
#   as shipped and a second pass would test nothing. The stripped pass is therefore
#   recorded as not run, with the reason, rather than reported as a pass; the extension
#   check below is what licenses that.
#
#   The archive is run against the deposited attrition 0.0.0.9000 and commarobust 0.1.0,
#   installed into a library under tempdir() so the packages the maintained rewrite uses
#   are untouched. stargazer, which the appendix script loads and the deposit does not
#   bundle, comes from CRAN into the same library.
#
#   This script is not part of run_all.R: it installs packages and reaches CRAN. The
#   archive values the ground truth reads are in archive_values.csv, which this script
#   does not write.
library(here)
library(tidyverse)
library(processx)

here::i_am("ground_truth/run_archive.R")

manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

analysis_scripts <- c("experimental_analysis_main_text.R", "experimental_analysis_appendix.R",
                      "simulation_analysis.R")
stopifnot(setequal(manifest$file[str_ends(manifest$file, "\\.R")], analysis_scripts))

# The null case, asserted ----
# Every deposited file other than the scripts is raw data, a package source tarball, or
# the README. A shipped intermediate would carry one of the extensions below.
derived_extensions <- c("rds", "rdata", "rda", "dta", "tex", "pdf", "png", "RData")
stopifnot(!any(tools::file_ext(manifest$file) %in% derived_extensions))

# Packages the deposit is written against ----
archive_lib <- file.path(tempdir(), "archive_lib")
dir.create(archive_lib, showWarnings = FALSE)
install.packages(
  here::here("original", c("attrition_0.0.0.9000.tar.gz", "commarobust_0.1.0.tar.gz")),
  lib = archive_lib, repos = NULL, type = "source"
)
install.packages("stargazer", lib = archive_lib, repos = "https://cloud.r-project.org")

# The as-shipped pass ----
# Each script runs in its own clean session (--vanilla), from the scratch copy as working
# directory, which is where the deposit's README tells the reader to set it.
scratch <- file.path(tempdir(), "as_shipped")
dir.create(scratch, showWarnings = FALSE)
file.copy(here::here("original", manifest$file), scratch, overwrite = TRUE)
copied_at <- file.mtime(file.path(scratch, manifest$file))
Sys.sleep(1)

timeout_seconds <- 600
script_env <- c("current", R_LIBS = str_c(c(archive_lib, .libPaths()), collapse = ":"))

run_script <- function(script) {
  result <- processx::run(
    "Rscript", c("--vanilla", script),
    wd = scratch, env = script_env, timeout = timeout_seconds,
    error_on_status = FALSE
  )
  # A killed script's dying words are not the reason it stopped, so the timeout is tested
  # before the error text is read.
  first_error <- str_subset(str_split_1(result$stderr, "\n"), "^Error")[1]
  tibble(
    script = script,
    exit_status = result$status,
    outcome = case_when(
      result$timeout ~ "timeout",
      result$status == 0 ~ "clean",
      .default = "error"
    ),
    stopped_at = case_when(
      result$timeout ~ str_glue("Killed at the {timeout_seconds} second limit"),
      result$status == 0 ~ NA_character_,
      .default = str_squish(first_error)
    )
  )
}

as_shipped <- map(analysis_scripts, run_script) |> list_rbind()

# What the pass wrote ----
# A deposited file whose modification time moved was written over, and its contents are
# compared against the checksum Dataverse serves. A file the deposit does not hold was
# added by the run.
after <- tibble(file = list.files(scratch, all.files = TRUE, no.. = TRUE)) |>
  mutate(path = file.path(scratch, file))

overwritten <- manifest |>
  mutate(path = file.path(scratch, file),
         written = file.mtime(path) > copied_at) |>
  filter(written) |>
  transmute(pass = "as_shipped", file, effect = "overwritten",
            matches_deposit = unname(tools::md5sum(path)) == md5_served)

added <- after |>
  filter(!file %in% manifest$file) |>
  transmute(pass = "as_shipped", file, effect = "added", matches_deposit = NA)

overwrites <- bind_rows(overwritten, added) |> arrange(effect, file)

# The two archive tables, in the canonical long form ----
stripped_reason <- str_c(
  "Not run: the deposit ships no derived object, so the copy stripped to data plus code ",
  "is the copy as shipped"
)

run_status <- bind_rows(
  as_shipped |> mutate(pass = "as_shipped"),
  tibble(pass = "stripped", script = analysis_scripts, exit_status = NA_integer_,
         outcome = "not_run", stopped_at = stripped_reason)
) |>
  mutate(role = "analysis") |>
  select(pass, script, role, exit_status, outcome, stopped_at)

stopifnot(nrow(run_status) == 2 * length(analysis_scripts),
          all(run_status$outcome %in% c("clean", "error", "timeout", "not_run")))

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))
print(run_status, width = 200)
print(overwrites)

# original/ is untouched ----
# The run happened in a copy, and this says so rather than assuming it.
stopifnot(all(unname(tools::md5sum(here::here("original", manifest$file))) ==
                manifest$md5_served))
