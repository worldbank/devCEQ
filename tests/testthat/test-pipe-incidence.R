# --- Integration tests for full incidence pipeline ---
# Tests the complete chain: calc_deciles -> agg_by_decile -> calc_incidence -> format_incidence

# Production combo 1: Full app parameters
test_that("full pipeline with all income vars, multiple groups, n_dec=10, force_abs=TRUE", {
  result <- dta_sim |>
    f_calc_deciles_by_sim(
      dec_var = c("ym", "yp", "yg", "yd", "yc", "yf"),
      wt_var = "hhwt",
      n_dec = 10
    ) |>
    f_agg_by_decile_by_sim(
      var_decile = c("ym___decile", "yp___decile", "yg___decile"),
      var_agg = c("ym", "yp", "dtx_prog1", "dtx_prog2"),
      var_group = c("all", "group_1", "group_2"),
      wt_var = "hhwt"
    ) |>
    f_calc_incidence(force_abs = TRUE) |>
    f_format_incidence()

  expect_true(nrow(result) > 0)
  # Should have factor columns
  expect_true(any(sapply(result, is.factor)))
  # Should have numeric value column (renamed from 'value' to 'Value')
  value_col <- f_get_colname("value")
  expect_true(value_col %in% names(result))
})

# Production combo 2: Reduced params
test_that("full pipeline with 2 dec_vars, 2 agg_vars, 2 groups, n_dec=5", {
  result <- dta_sim |>
    f_calc_deciles_by_sim(
      dec_var = c("ym", "yp"),
      wt_var = "hhwt",
      n_dec = 5
    ) |>
    f_agg_by_decile_by_sim(
      var_decile = c("ym___decile", "yp___decile"),
      var_agg = c("ym", "dtx_prog1"),
      var_group = c("all", "group_1"),
      wt_var = "hhwt"
    ) |>
    f_calc_incidence(force_abs = TRUE) |>
    f_format_incidence()

  expect_true(nrow(result) > 0)
  # Row count check: 2 sims x 2 dec_vars x (1 + 2 groups) x 5 deciles x 2 vars x 3 measures
  expected <- 2 * 2 * 3 * 5 * 2 * 3
  expect_equal(nrow(result), expected)
})

# Production combo 3: Minimal - single dec_var, force_abs=FALSE
test_that("full pipeline minimal: single dec_var, n_dec=3, force_abs=FALSE", {
  result <- dta_sim |>
    f_calc_deciles_by_sim(dec_var = "ym", wt_var = "hhwt", n_dec = 3) |>
    f_agg_by_decile_by_sim(
      var_decile = "ym___decile",
      var_agg = c("ym", "dtx_prog1"),
      var_group = "all",
      wt_var = "hhwt"
    ) |>
    f_calc_incidence(force_abs = FALSE) |>
    f_format_incidence()

  expect_true(nrow(result) > 0)
  # 2 sims x 1 dec_var x 1 group x 3 deciles x 2 vars x 3 measures = 36
  expect_equal(nrow(result), 36)
})

# Production combo 4: Single simulation
test_that("full pipeline works with single simulation", {
  single_sim <- list(
    policy0 = list(policy_sim_raw = dta_hh, policy_name = "Baseline")
  )

  result <- single_sim |>
    f_calc_deciles_by_sim(dec_var = "ym", wt_var = "hhwt", n_dec = 5) |>
    f_agg_by_decile_by_sim(
      var_decile = "ym___decile",
      var_agg = "ym",
      var_group = "all",
      wt_var = "hhwt"
    ) |>
    f_calc_incidence(force_abs = TRUE) |>
    f_format_incidence()

  expect_true(nrow(result) > 0)
  # 1 sim x 1 dec_var x 1 group x 5 deciles x 1 var x 3 measures = 15
  expect_equal(nrow(result), 15)
})

# Production combo 5: Large n_dec
test_that("full pipeline with n_dec=20 on 1000 rows", {
  result <- dta_sim |>
    f_calc_deciles_by_sim(dec_var = "ym", wt_var = "hhwt", n_dec = 20) |>
    f_agg_by_decile_by_sim(
      var_decile = "ym___decile",
      var_agg = "ym",
      var_group = "all",
      wt_var = "hhwt"
    ) |>
    f_calc_incidence(force_abs = TRUE) |>
    f_format_incidence()

  expect_true(nrow(result) > 0)
  # 2 sims x 1 dec_var x 1 group x 20 deciles x 1 var x 3 measures = 120
  expect_equal(nrow(result), 120)
})

# Handoff contract: decile output feeds aggregation
test_that("decile output column names match ___decile convention for aggregation", {
  dec_result <- dta_sim |>
    f_calc_deciles_by_sim(dec_var = c("ym", "yp"), wt_var = "hhwt", n_dec = 5)

  # Check that decile columns exist in each sim
  expect_true("ym___decile" %in% names(dec_result$policy0$policy_sim_raw))
  expect_true("yp___decile" %in% names(dec_result$policy0$policy_sim_raw))
})

# Handoff contract: aggregation output feeds incidence
test_that("aggregation output has decile_val column for incidence", {
  agg_result <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = "ym",
    var_group = "all",
    wt_var = "hhwt"
  )

  expect_true("decile_val" %in% names(agg_result))
  expect_true(is.numeric(agg_result[["decile_val"]]))
})

# Handoff contract: incidence output feeds format
test_that("incidence output has measure/var/decile_var columns for formatting", {
  agg_result <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = "ym",
    var_group = "all",
    wt_var = "hhwt"
  )

  incid_result <- f_calc_incidence(agg_result)

  expect_true("measure" %in% names(incid_result))
  expect_true("var" %in% names(incid_result))
  expect_true("decile_var" %in% names(incid_result))
})

# Failure propagation: invalid dec_var warns but pipeline continues
test_that("pipeline warns and continues when one dec_var is invalid", {
  expect_warning(
    result <- dta_sim |>
      f_calc_deciles_by_sim(
        dec_var = c("ym", "totally_fake"),
        wt_var = "hhwt",
        n_dec = 5
      ) |>
      f_agg_by_decile_by_sim(
        var_decile = "ym___decile",
        var_agg = "ym",
        var_group = "all",
        wt_var = "hhwt"
      ) |>
      f_calc_incidence(force_abs = TRUE) |>
      f_format_incidence(),
    "Skipping|not found"
  )

  expect_true(nrow(result) > 0)
})

# Failure propagation: nonexistent group warns, pipeline completes
test_that("pipeline warns for nonexistent group but completes", {
  expect_warning(
    result <- dta_sim |>
      f_calc_deciles_by_sim(dec_var = "ym", wt_var = "hhwt", n_dec = 5) |>
      f_agg_by_decile_by_sim(
        var_decile = "ym___decile",
        var_agg = "ym",
        var_group = "nonexistent_group",
        wt_var = "hhwt"
      ) |>
      f_calc_incidence(force_abs = TRUE) |>
      f_format_incidence(),
    "not found"
  )

  expect_true(nrow(result) > 0)
})

# n_dec = 1: meaningless but shouldn't crash
test_that("pipeline handles n_dec=1 without crashing", {
  result <- dta_sim |>
    f_calc_deciles_by_sim(dec_var = "ym", wt_var = "hhwt", n_dec = 1) |>
    f_agg_by_decile_by_sim(
      var_decile = "ym___decile",
      var_agg = "ym",
      var_group = "all",
      wt_var = "hhwt"
    ) |>
    f_calc_incidence(force_abs = TRUE) |>
    f_format_incidence()

  expect_true(nrow(result) > 0)
})

# Formatted output feeds f_plot_gg (smoke test)
test_that("formatted pipeline output can be plotted with f_plot_gg", {
  formatted <- dta_sim |>
    f_calc_deciles_by_sim(dec_var = "ym", wt_var = "hhwt", n_dec = 5) |>
    f_agg_by_decile_by_sim(
      var_decile = "ym___decile",
      var_agg = c("ym", "dtx_prog1"),
      var_group = "all",
      wt_var = "hhwt"
    ) |>
    f_calc_incidence(force_abs = TRUE) |>
    f_format_incidence()

  # Filter to one measure for plotting
  measure_vals <- unique(as.character(formatted[[f_get_colname("measure")]]))
  plot_data <- formatted |>
    f_filter_var_generic(measure_vals[1], "measure")

  # Should produce a ggplot without error
  p <- f_plot_gg(
    dta = plot_data,
    x_var = "decile",
    y_var = "value",
    color_var = "var",
    facet_var = "sim",
    type = "bar"
  )

  expect_s3_class(p, "ggplot")
})
