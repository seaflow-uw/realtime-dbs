#!/usr/bin/env Rscript

parser <- optparse::OptionParser(
  usage = "usage: validate-dbs.R [db-file ...]",
  description = "Validate minimal Popcycle parameter database files"
)
parser <- optparse::add_option(parser, "--renv",
  type = "character", default = "", metavar = "dir",
  help = "Optional renv directory to use. Requires the renv package."
)

p <- optparse::parse_args2(parser)

if (p$options$renv != "") {
  proj_dir <- renv::activate(p$options$renv)
  message("activated renv directory ", proj_dir)
}

message("using popcycle version ", packageVersion("popcycle"))

library(dplyr)
library(glue)

validate_db <- function(dbpath) {
  message("validating ", dbpath)
  validate_file_name(dbpath)
  validate_filter_plan(dbpath)
  validate_gating_plan(dbpath)
  validate_empty_tables(dbpath)
  validate_filter_and_classify(dbpath)
}

validate_file_name <- function(dbpath) {
  dbname <- basename(dbpath)
  name_and_extension <- unlist(stringr::str_split(dbname, "\\."))
  if (length(name_and_extension) != 2 || name_and_extension[2] != "db") {
    stop(glue("invalid extension in file name: {dbpath}"))
  }
  cruise_serial <- unlist(stringr::str_split(name_and_extension[1], "_"))
  if (length(cruise_serial) < 2 || is.na(as.integer(cruise_serial[length(cruise_serial)]))) {
    stop(glue("invalid cruise and/or serial in file name: {dbpath}"))
  }
}

validate_filter_plan <- function(dbpath) {
  fp <- popcycle::get_filter_plan_table(dbpath)
  if (nrow(fp) == 0) {
    stop(glue("filter_plan table is empty: {dbpath}"))
  }
}

validate_gating_plan <- function(dbpath) {
  gp <- popcycle::get_gating_plan_table(dbpath)
  if (nrow(gp) == 0) {
    stop(glue("filter_plan table is empty: {dbpath}"))
  }
}

#' Test each filter and gating parameter in plan tables at least once.
#' This will not test all possible combinations.
validate_filter_and_classify <- function(dbpath) {
  filter_plan_n <- nrow(popcycle::get_filter_plan_table(dbpath))
  gating_plan_n <- nrow(popcycle::get_gating_plan_table(dbpath))

  for (i in seq(filter_plan_n)) {
    validate_filter_and_classify_one_pair(dbpath, filter_plan_row = i, gating_plan_row = 1)
  }
  if (gating_plan_n > 1) {
    for (i in seq(gating_plan_n)) {
      validate_filter_and_classify_one_pair(dbpath, filter_plan_row = 1, gating_plan_row = i)
    }
  }
}

validate_filter_and_classify_one_pair <- function(dbpath, filter_plan_row = 1, gating_plan_row = 1) {
  message(glue("testing params for filter_plan {filter_plan_row} and gating_plan row {gating_plan_row}"))
  newdbpath <- tempfile(glue("{basename(dbpath)}.validate_filter_and_classify_{filter_plan_row}_{gating_plan_row}"), fileext = ".db")
  file.copy(dbpath, newdbpath)

  fp <- popcycle::get_filter_plan_table(newdbpath)
  fp <- fp %>% mutate(start_date = lubridate::ymd_hms("2014-07-04T00:00:00+00:00"))
  popcycle::reset_filter_plan_table(newdbpath)
  popcycle::save_filter_plan(newdbpath, fp[filter_plan_row, ])

  gp <- popcycle::get_gating_plan_table(newdbpath)
  gp <- gp %>% mutate(start_date = lubridate::ymd_hms("2014-07-04T00:00:00+00:00"))
  popcycle::reset_gating_plan_table(newdbpath)
  popcycle::save_gating_plan(newdbpath, gp[gating_plan_row, ])

  popcycle:::copy_tables("popcycle/tests/testdata/testcruise_bare_db", newdbpath, c("sfl"))

  evt_files <- popcycle::get_evt_files("popcycle/tests/testdata/evt")
  opp_dir <- tempfile(glue("{basename(dbpath)}_opp_{filter_plan_row}_{gating_plan_row}"))
  vct_dir <- tempfile(glue("{basename(dbpath)}_vct_{filter_plan_row}_{gating_plan_row}"))
  message(glue("dbpath={newdbpath}"))
  message(glue("opp_dir={opp_dir}"))
  message(glue("vct_dir={vct_dir}"))
  message("")
  popcycle::filter_evt_files(newdbpath, "popcycle/tests/testdata/evt", evt_files$file_id, opp_dir)
  popcycle::classify_opp_files(newdbpath, opp_dir, NULL, vct_dir)
}

validate_empty_tables <- function(dbpath) {
  if (nrow(popcycle::get_sfl_table(dbpath)) > 0) {
    stop(glue("sfl table is not empty: {dbpath}"))
  }
  if (nrow(popcycle::get_opp_table(dbpath)) > 0) {
    stop(glue("opp table is not empty: {dbpath}"))
  }
  if (nrow(popcycle::get_vct_table(dbpath)) > 0) {
    stop(glue("vct table is not empty: {dbpath}"))
  }
  if (nrow(popcycle::get_outlier_table(dbpath)) > 0) {
    stop(glue("outlier table is not empty: {dbpath}"))
  }
}

x <- lapply(p$args, validate_db)  # discard NULL results
message("All tests passed")
