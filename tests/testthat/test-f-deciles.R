# --- Tests for f_calc_deciles ---
# Covers: happy path with package data, correct synthetic, edge cases

# Tier 1: Package data integration
test_that("f_calc_deciles works on dta_hh with real income vars", {
  result <- f_calc_deciles(
    dta = dta_hh,
    dec_var = c("ym", "yn"),
    wt_var = "hhwt",
    n_dec = 10
  )

  expect_true("ym___decile" %in% names(result))
  expect_true("yn___decile" %in% names(result))
  expect_s3_class(result[["ym___decile"]], "factor")
  expect_equal(nlevels(result[["ym___decile"]]), 10)
  expect_equal(nrow(result), nrow(dta_hh))
})

# Tier 2: Correct synthetic data
test_that("f_calc_deciles creates decile columns with correct naming", {
  set.seed(42)
  test_data <- data.frame(
    income = runif(100, 1000, 10000),
    weight = runif(100, 0.5, 2)
  )

  result <- f_calc_deciles(
    dta = test_data,
    dec_var = "income",
    wt_var = "weight",
    n_dec = 10
  )

  expect_true("income___decile" %in% names(result))
  expect_s3_class(result[["income___decile"]], "factor")
  expect_equal(nlevels(result[["income___decile"]]), 10)
  expect_true(all(c("income", "weight") %in% names(result)))
  expect_false("wt_temp__" %in% names(result))
})

test_that("f_calc_deciles works with multiple variables", {
  set.seed(42)
  test_data <- data.frame(
    income1 = runif(100, 1000, 10000),
    income2 = runif(100, 2000, 8000),
    weight = rep(1, 100)
  )

  result <- f_calc_deciles(
    dta = test_data,
    dec_var = c("income1", "income2"),
    wt_var = "weight",
    n_dec = 5
  )

  expect_true("income1___decile" %in% names(result))
  expect_true("income2___decile" %in% names(result))
  expect_equal(nlevels(result[["income1___decile"]]), 5)
  expect_equal(nlevels(result[["income2___decile"]]), 5)
})

test_that("f_calc_deciles uses equal weights when wt_var is NULL", {
  set.seed(42)
  test_data <- data.frame(income = runif(100, 1000, 10000))

  result <- f_calc_deciles(
    dta = test_data,
    dec_var = "income",
    wt_var = NULL,
    n_dec = 10
  )

  expect_true("income___decile" %in% names(result))
  expect_false("wt_temp__" %in% names(result))
})

test_that("f_calc_deciles works with different n_dec values", {
  set.seed(42)
  test_data <- data.frame(income = runif(100, 1000, 10000))

  result_4 <- f_calc_deciles(test_data, dec_var = "income", n_dec = 4)
  result_5 <- f_calc_deciles(test_data, dec_var = "income", n_dec = 5)

  expect_true("income___decile" %in% names(result_4))
  expect_equal(nlevels(result_4[["income___decile"]]), 4)
  expect_true("income___decile" %in% names(result_5))
  expect_equal(nlevels(result_5[["income___decile"]]), 5)
})

test_that("f_calc_deciles preserves tibble class", {
  test_tibble <- tibble::tibble(income = runif(100, 1000, 10000))

  result <- f_calc_deciles(test_tibble, dec_var = "income", n_dec = 10)
  expect_s3_class(result, "tbl_df")
})

# Tier 3: Bad inputs / edge cases
test_that("f_calc_deciles warns and returns unchanged for NULL dec_var", {
  test_data <- data.frame(income = runif(50, 100, 500))

  expect_warning(
    result <- f_calc_deciles(test_data, dec_var = NULL, n_dec = 10),
    "must be a non-empty character vector"
  )
  expect_identical(result, test_data)
})

test_that("f_calc_deciles warns and returns unchanged for empty dec_var", {
  test_data <- data.frame(income = runif(50, 100, 500))

  expect_warning(
    result <- f_calc_deciles(test_data, dec_var = character(0), n_dec = 10),
    "must be a non-empty character vector"
  )
  expect_identical(result, test_data)
})

test_that("f_calc_deciles aborts when ALL dec_var columns missing", {
  test_data <- data.frame(income = runif(50, 100, 500))

  expect_error(
    f_calc_deciles(test_data, dec_var = c("var1", "var2"), n_dec = 10),
    "None of"
  )
})

test_that("f_calc_deciles warns and processes available when SOME dec_var missing", {
  set.seed(42)
  test_data <- data.frame(income = runif(50, 100, 500))

  expect_warning(
    result <- f_calc_deciles(test_data, dec_var = c("income", "nonexistent"), n_dec = 5),
    "Skipping missing variables"
  )
  expect_true("income___decile" %in% names(result))
  expect_false("nonexistent___decile" %in% names(result))
})

test_that("f_calc_deciles warns when wt_var not found in data", {
  set.seed(42)
  test_data <- data.frame(income = runif(50, 100, 500))

  expect_warning(
    result <- f_calc_deciles(test_data, dec_var = "income", wt_var = "bad_weight", n_dec = 5),
    "not present|not found|[Ww]eight"
  )
  expect_true("income___decile" %in% names(result))
})

test_that("f_calc_deciles handles NAs in income variable", {
  set.seed(42)
  test_data <- data.frame(
    income = c(runif(90, 100, 500), rep(NA, 10)),
    weight = rep(1, 100)
  )

  # Should not error - NAs get handled

  result <- f_calc_deciles(test_data, dec_var = "income", wt_var = "weight", n_dec = 5)
  expect_true("income___decile" %in% names(result))
  expect_equal(nrow(result), 100)
})

test_that("f_calc_deciles handles n_dec larger than nrow", {
  set.seed(42)
  test_data <- data.frame(income = runif(5, 100, 500))

  # Should not error - produces result even if some deciles are empty

  result <- f_calc_deciles(test_data, dec_var = "income", n_dec = 20)
  expect_true("income___decile" %in% names(result))
  expect_equal(nrow(result), 5)
})

test_that("f_calc_deciles warns for zero/negative weights", {
  set.seed(42)
  test_data <- data.frame(
    income = runif(50, 100, 500),
    weight = c(rep(1, 45), rep(0, 3), rep(-1, 2))
  )

  expect_warning(
    result <- f_calc_deciles(test_data, dec_var = "income", wt_var = "weight", n_dec = 5),
    "[Ww]eight|zero|negative"
  )
  expect_true("income___decile" %in% names(result))
})
