library(dplyr)
library(glue)

validate_db <- function(dbpath) {
  message("validating ", dbpath)
  validate_file_name(dbpath)
  validate_filter_plan(dbpath)
  validate_gating_plan(dbpath)
  validate_empty_tables(dbpath)
  validate_filter_and_classify(dbpath)
  return(invisible(NULL))
}

validate_file_name <- function(dbpath) {
  dbname <- basename(dbpath)
  name_and_extension <- unlist(stringr::str_split(dbname, "\\."))
  if (length(name_and_extension) != 2 || name_and_extension[2] != "db") {
    stop(glue("invalid extension in file name: {dbpath}"))
  }
  cruise_serial <- unlist(stringr::str_split(name_and_extension[1], "_"))
  if (length(cruise_serial) != 2 || is.na(as.integer(cruise_serial[2]))) {
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

validate_filter_and_classify <- function(dbpath) {
  newdbpath <- glue("{dbpath}.validate_filter_and_classify")
  file.copy(dbpath, glue("{dbpath}.validate_filter_and_classify"))

  fp <- popcycle::get_filter_plan_table(newdbpath)
  fp <- fp %>% mutate(start_date = lubridate::ymd_hms("2014-07-04T00:00:00+00:00"))
  popcycle::reset_filter_plan_table(newdbpath)
  popcycle::save_filter_plan(newdbpath, fp[1, ])

  gp <- popcycle::get_gating_plan_table(newdbpath)
  gp <- gp %>% mutate(start_date = lubridate::ymd_hms("2014-07-04T00:00:00+00:00"))
  popcycle::reset_gating_plan_table(newdbpath)
  popcycle::save_gating_plan(newdbpath, gp[1, ])

  popcycle:::copy_tables("/popcycle/tests/testdata/testcruise_bare.db", newdbpath, c("sfl"))

  evt_files <- popcycle::get_evt_files("/popcycle/tests/testdata/evt")
  opp_dir <- glue("{basename(dbpath)}_opp")
  vct_dir <- glue("{basename(dbpath)}_vct")
  popcycle::filter_evt_files(newdbpath, "/popcycle/tests/testdata/evt", evt_files$file_id, opp_dir)
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

lapply(commandArgs(trailingOnly=TRUE), validate_db)
message("All tests passed")
