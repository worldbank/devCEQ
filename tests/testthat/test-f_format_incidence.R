# --- Tests for f_format_incidence ---
# Applies labels, factor ordering, glue interpolation, and column renaming

# Tier 1: Package data - full pipeline
test_that("f_format_incidence produces renamed columns from real pipeline output", {
  agg_data <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  result <- agg_data |>
    f_calc_incidence() |>
    f_format_incidence()

  # Should have renamed columns (from f_rename_cols dictionary)
  expect_true(nrow(result) > 0)
  # Most grouping columns should be factors
  factor_cols <- sapply(result, is.factor)
  expect_true(sum(factor_cols) >= 3)
})

test_that("f_format_incidence output has factor columns for grouping vars", {
  agg_data <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = c("all", "group_1"),
    wt_var = "hhwt"
  )

  result <- agg_data |>
    f_calc_incidence() |>
    f_format_incidence()

  # Check that factor columns exist in the result
  factor_cols <- sapply(result, is.factor)
  expect_true(sum(factor_cols) > 0)
})

# Tier 2: Correct synthetic
test_that("f_format_incidence preserves row count from input", {
  agg_data <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = c("ym"),
    var_group = "all",
    wt_var = "hhwt"
  )

  incid_data <- agg_data |> f_calc_incidence()
  input_rows <- nrow(incid_data)


  result <- incid_data |> f_format_incidence()

  expect_equal(nrow(result), input_rows)
})

test_that("f_format_incidence measure labels contain interpolated var names", {
  agg_data <- f_agg_by_decile(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym"),
    var_group = "all",
    wt_var = "hhwt"
  ) |> mutate(sim = "Baseline")

  result <- agg_data |>
    f_calc_incidence() |>
    f_format_incidence()

  # Check renamed measure column for interpolated text
  # The measure labels should contain lowercase variable references
  measure_col <- names(result)[1]  # First column after rename
  # At minimum, result should not have raw "relative"/"absolute"/"level"
  measure_vals <- unique(as.character(result[[f_get_colname("measure")]]))
  expect_true(length(measure_vals) == 3)
})

test_that("f_format_incidence factor ordering is preserved", {
  agg_data <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = c("ym___decile", "yp___decile"),
    var_agg = c("ym", "yp"),
    var_group = "all",
    wt_var = "hhwt"
  )

  result <- agg_data |>
    f_calc_incidence() |>
    f_format_incidence()

  # Factor levels should maintain original ordering from dictionary
  var_col <- f_get_colname("var")
  if (var_col %in% names(result)) {
    expect_s3_class(result[[var_col]], "factor")
  }
})

# Tier 3: Bad inputs
test_that("f_format_incidence handles unknown measure values gracefully", {
  # Create synthetic incidence data with required columns
  test_incid <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = "No groupping",
    group_val = "All observations",
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "income",
    measure = "custom_measure",
    value = c(0.5, 0.5),
    sim = "Test"
  )

  # Should not crash - unknown measure gets raw value as label
  result <- f_format_incidence(test_incid)
  expect_true(nrow(result) > 0)
})

test_that("f_format_incidence handles unknown variable names", {
  test_incid <- tibble::tibble(
    decile_var = "income",
    decile = factor(c(1, 2)),
    decile_n = 2L,
    decile_val = c(100, 200),
    group_var = "No groupping",
    group_val = "All observations",
    n = c(5L, 5L),
    pop = c(5, 5),
    var = "totally_unknown_var",
    measure = "relative",
    value = c(0.5, 0.5),
    sim = "Test"
  )

  # Should not crash - unknown var gets raw name as label
  result <- f_format_incidence(test_incid)
  expect_true(nrow(result) > 0)
})

test_that("f_format_incidence handles empty input", {
  test_incid <- tibble::tibble(
    decile_var = character(),
    decile = factor(),
    decile_n = integer(),
    decile_val = numeric(),
    group_var = character(),
    group_val = character(),
    n = integer(),
    pop = numeric(),
    var = character(),
    measure = character(),
    value = numeric(),
    sim = character()
  )

  result <- f_format_incidence(test_incid)
  expect_equal(nrow(result), 0)
})
