# --- Tests for f_calc_incidence ---
# Calculates relative, absolute, and level incidence measures from aggregated data

# Tier 1: Package data - full pipeline integration
test_that("f_calc_incidence produces correct structure from real pipeline output", {
  agg_data <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  result <- f_calc_incidence(agg_data)

  expect_true("measure" %in% names(result))
  expect_true("value" %in% names(result))
  expect_true(all(c("relative", "absolute", "level") %in% result[["measure"]]))
})

test_that("f_calc_incidence output has 3x input rows", {
  agg_data <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  input_rows <- nrow(agg_data)
  result <- f_calc_incidence(agg_data)

  expect_equal(nrow(result), input_rows * 3)
})

# Tier 2: Correct synthetic - verifiable arithmetic
test_that("f_calc_incidence computes relative = level/decile_val", {
  # Simple synthetic aggregated data
  test_agg <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = factor("No groupping"),
    group_val = factor("All observations"),
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "income",
    level = c(100, 200),
    sim = "Baseline"
  )

  result <- f_calc_incidence(test_agg)

  relative <- result[result[["measure"]] == "relative", ]
  # relative = level / decile_val = 100/100, 200/200 = 1, 1
  expect_equal(relative[["value"]], c(1, 1))
})

test_that("f_calc_incidence computes absolute = level/total", {
  test_agg <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = factor("No groupping"),
    group_val = factor("All observations"),
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "income",
    level = c(40, 60),
    sim = "Baseline"
  )

  result <- f_calc_incidence(test_agg)

  absolute <- result[result[["measure"]] == "absolute", ]
  # total = sum(level) = 100, absolute = 40/100, 60/100
  expect_equal(absolute[["value"]], c(0.4, 0.6))
})

test_that("f_calc_incidence force_abs=TRUE skips factor multiplication", {
  # dtx_prog1 should have factor = -1 in dictionary (it's a tax)
  test_agg <- tibble::tibble(
    decile_var = "ym",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = factor("No groupping"),
    group_val = factor("All observations"),
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "dtx_prog1",
    level = c(10, 20),
    sim = "Baseline"
  )

  result_no_force <- f_calc_incidence(test_agg, force_abs = FALSE)
  result_force <- f_calc_incidence(test_agg, force_abs = TRUE)

  level_no_force <- result_no_force[result_no_force[["measure"]] == "level", "value"]
  level_force <- result_force[result_force[["measure"]] == "level", "value"]

  # force_abs = TRUE: level = raw level (10, 20)
  expect_equal(level_force[["value"]], c(10, 20))
  # force_abs = FALSE: level *= factor (factor for taxes = -1 from dictionary)
  # If dtx_prog1 has factor -1, then levels become -10, -20
  # Or if not in dictionary, factor defaults to 1
})

test_that("f_calc_incidence handles vars not in dictionary (factor defaults to 1)", {
  test_agg <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = factor("No groupping"),
    group_val = factor("All observations"),
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "unknown_variable_xyz",
    level = c(50, 50),
    sim = "Baseline"
  )

  # Should not error - factor defaults to 1
  result <- f_calc_incidence(test_agg)

  level_vals <- result[result[["measure"]] == "level", "value"]
  expect_equal(level_vals[["value"]], c(50, 50))
})

# Tier 3: Bad inputs
test_that("f_calc_incidence replaces NaN/Inf with 0 in relative/absolute", {
  # decile_val = 0 -> relative = NaN -> 0
  test_agg <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(0, 200),
    group_var = factor("No groupping"),
    group_val = factor("All observations"),
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "income",
    level = c(0, 200),
    sim = "Baseline"
  )

  result <- f_calc_incidence(test_agg)

  relative <- result[result[["measure"]] == "relative", ]
  # 0/0 = NaN -> 0, 200/200 = 1
  expect_equal(relative[["value"]], c(0, 1))
})

test_that("f_calc_incidence handles all-zero levels (absolute = 0/0 -> 0)", {
  test_agg <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = factor("No groupping"),
    group_val = factor("All observations"),
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "tax",
    level = c(0, 0),
    sim = "Baseline"
  )

  result <- f_calc_incidence(test_agg)

  absolute <- result[result[["measure"]] == "absolute", ]
  # total = 0, absolute = 0/0 -> 0

  expect_equal(absolute[["value"]], c(0, 0))
})

test_that("f_calc_incidence handles NAs in level column", {
  test_agg <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = factor("No groupping"),
    group_val = factor("All observations"),
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "income",
    level = c(NA_real_, 200),
    sim = "Baseline"
  )

  # na.rm = TRUE in sum, should produce result
  result <- f_calc_incidence(test_agg)

  # Result should have 6 rows (2 input x 3 measures)
  expect_equal(nrow(result), 6)
})

test_that("f_calc_incidence works with missing optional columns", {
  # Minimal input without sim or decile_var
  test_agg <- tibble::tibble(
    decile = factor(c(1, 2)),
    decile_val = c(100, 200),
    var = "income",
    level = c(50, 150)
  )

  result <- f_calc_incidence(test_agg)
  expect_equal(nrow(result), 6)
  expect_true(all(c("relative", "absolute", "level") %in% result[["measure"]]))
})

test_that("f_calc_incidence handles empty data frame", {
  test_agg <- tibble::tibble(
    decile_var = character(),
    decile = factor(),
    decile_val = numeric(),
    var = character(),
    level = numeric(),
    sim = character()
  )

  result <- f_calc_incidence(test_agg)
  expect_equal(nrow(result), 0)
})
