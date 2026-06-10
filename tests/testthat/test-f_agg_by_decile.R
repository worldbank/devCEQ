# --- Tests for f_agg_by_decile ---
# Loops over multiple decile variables and group variables,
# calling f_agg_by_decile_one() for each combination

# Tier 1: Package data
test_that("f_agg_by_decile produces correct row count with multiple decile vars and groups", {
  result <- f_agg_by_decile(
    dta = dta_hh,
    var_decile = c("ym___decile", "yp___decile", "yg___decile"),
    var_agg = c("ym", "yp", "yg", "dtx_prog1", "dtx_prog2"),
    var_group = c("all", "group_2", "group_1"),
    wt_var = "hhwt"
  )

  n_deciles <- 10
  n_decile_vars <- 3
  n_groups_all <- 1
  n_groups_g2 <- length(unique(dta_hh$group_2))
  n_groups_g1 <- length(unique(dta_hh$group_1))
  n_agg_vars <- 5
  expected_rows <- n_decile_vars * (n_groups_all + n_groups_g2 + n_groups_g1) * n_deciles * n_agg_vars

  expect_equal(nrow(result), expected_rows)
})

test_that("f_agg_by_decile output columns match expected schema", {
  result <- f_agg_by_decile(
    dta = dta_hh,
    var_decile = c("ym___decile", "yp___decile"),
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  expected_cols <- c(
    "decile_var", "decile", "decile_n", "decile_val",
    "group_var", "group_val", "n", "pop", "var", "level"
  )
  expect_true(all(expected_cols %in% names(result)))
})

# Tier 2: Correct synthetic
test_that("f_agg_by_decile with single var_decile equals f_agg_by_decile_one", {
  result_multi <- f_agg_by_decile(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  result_one <- f_agg_by_decile_one(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  expect_equal(nrow(result_multi), nrow(result_one))
  expect_equal(result_multi$level, result_one$level)
})

test_that("f_agg_by_decile multiple var_group produces all group combinations", {
  result <- f_agg_by_decile(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = "ym",
    var_group = c("all", "group_1"),
    wt_var = "hhwt"
  )

  group_vars_in_result <- unique(as.character(result$group_var))
  expect_true("No groupping" %in% group_vars_in_result)
  expect_true("group_1" %in% group_vars_in_result)
})

test_that("f_agg_by_decile is deterministic", {
  args <- list(
    dta = dta_hh,
    var_decile = c("ym___decile", "yp___decile"),
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  result1 <- do.call(f_agg_by_decile, args)
  result2 <- do.call(f_agg_by_decile, args)
  expect_identical(result1, result2)
})

# Tier 3: Bad inputs
test_that("f_agg_by_decile aborts when ALL var_decile missing", {
  test_data <- data.frame(income = 1:10)
  test_data[["income___decile"]] <- factor(rep(1:2, 5))

  expect_error(
    f_agg_by_decile(
      dta = test_data,
      var_decile = c("missing1___decile", "missing2___decile"),
      var_agg = "income"
    ),
    "None of"
  )
})

test_that("f_agg_by_decile warns and skips when SOME var_decile missing", {
  test_data <- data.frame(income = 1:10, wt = rep(1, 10))
  test_data[["income___decile"]] <- factor(rep(1:2, 5))

  expect_warning(
    result <- f_agg_by_decile(
      dta = test_data,
      var_decile = c("income___decile", "missing___decile"),
      var_agg = "income",
      wt_var = "wt"
    ),
    "not found"
  )

  # Only processes the existing one
  expect_true(all(result[["decile_var"]] == "income"))
})

test_that("f_agg_by_decile warns when var_group is not character", {
  expect_warning(
    result <- f_agg_by_decile(
      dta = dta_hh,
      var_decile = "ym___decile",
      var_agg = "ym",
      var_group = 123,
      wt_var = "hhwt"
    ),
    "character vector"
  )

  # Falls back to NULL -> "No groupping"
  expect_true(all(as.character(result[["group_var"]]) == "No groupping"))
})

test_that("f_agg_by_decile handles nonexistent group var with warning", {
  expect_warning(
    result <- f_agg_by_decile(
      dta = dta_hh,
      var_decile = "ym___decile",
      var_agg = "ym",
      var_group = "nonexistent_group",
      wt_var = "hhwt"
    ),
    "not found"
  )

  # Falls back to "No groupping"
  expect_true(all(as.character(result[["group_var"]]) == "No groupping"))
})
