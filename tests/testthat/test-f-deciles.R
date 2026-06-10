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

# --- fixed_dec_var tests ---

# Helper: build a small dataset with pre-computed baseline deciles
make_fixed_dec_data <- function(n = 100, seed = 42) {
  set.seed(seed)
  dta <- data.frame(
    income = runif(n, 1000, 10000),
    weight = runif(n, 0.5, 2)
  )
  f_calc_deciles(dta, dec_var = "income", wt_var = "weight", n_dec = 5)
}

test_that("fixed_dec_var preserves existing decile column exactly", {
  dta <- make_fixed_dec_data()
  original_deciles <- dta[["income___decile"]]

  # Modify income slightly (simulating a reform)
  dta_reform <- dta
  dta_reform$income <- dta$income * 1.1

  result <- f_calc_deciles(
    dta_reform,
    dec_var = "income",
    wt_var = "weight",
    n_dec = 5,
    fixed_dec_var = "income"
  )

  expect_identical(result[["income___decile"]], original_deciles)
})

test_that("fixed_dec_var preserves baseline rank even when reform shifts income", {
  dta_baseline <- make_fixed_dec_data()

  # Reform: invert incomes — poorest becomes richest
  dta_reform <- dta_baseline
  dta_reform$income <- max(dta_baseline$income) - dta_baseline$income + 1

  # Without fixed: recomputed deciles differ from baseline
  result_free <- f_calc_deciles(dta_reform, dec_var = "income", wt_var = "weight", n_dec = 5)
  # With fixed: baseline deciles are preserved
  result_fixed <- f_calc_deciles(
    dta_reform,
    dec_var = "income",
    wt_var = "weight",
    n_dec = 5,
    fixed_dec_var = "income"
  )

  expect_false(identical(result_free[["income___decile"]], dta_baseline[["income___decile"]]))
  expect_identical(result_fixed[["income___decile"]], dta_baseline[["income___decile"]])
})

test_that("fixed_dec_var and dec_var can coexist: fixed preserved, other recomputed", {
  set.seed(42)
  dta <- data.frame(
    income1 = runif(100, 1000, 10000),
    income2 = runif(100, 500, 5000),
    weight   = rep(1, 100)
  )
  # Pre-compute baseline decile for income1 only
  dta <- f_calc_deciles(dta, dec_var = "income1", wt_var = "weight", n_dec = 5)
  baseline_dec1 <- dta[["income1___decile"]]

  # Modify income1, keep income2 as-is
  dta$income1 <- dta$income1 * 2

  result <- f_calc_deciles(
    dta,
    dec_var = c("income1", "income2"),
    wt_var = "weight",
    n_dec = 5,
    fixed_dec_var = "income1"
  )

  expect_identical(result[["income1___decile"]], baseline_dec1)
  expect_true("income2___decile" %in% names(result))
  expect_s3_class(result[["income2___decile"]], "factor")
})

test_that("fixed_dec_var errors clearly when column not in data", {
  dta <- data.frame(income = runif(50, 100, 500), weight = rep(1, 50))

  expect_error(
    f_calc_deciles(dta, dec_var = "income", wt_var = "weight", n_dec = 5,
                   fixed_dec_var = "income"),
    "income___decile"
  )
})

test_that("fixed_dec_var accepts suffix form ym___decile as well as base ym", {
  dta <- make_fixed_dec_data()
  original_deciles <- dta[["income___decile"]]
  dta$income <- dta$income * 1.1  # reform

  result <- f_calc_deciles(
    dta,
    dec_var = "income",
    wt_var = "weight",
    n_dec = 5,
    fixed_dec_var = "income___decile"  # suffix form
  )

  expect_identical(result[["income___decile"]], original_deciles)
})

test_that("fixed_dec_var coerces non-factor column to factor with warning", {
  dta <- make_fixed_dec_data()
  # Convert the decile column to integer (not a factor)
  dta$income___decile <- as.integer(dta$income___decile)
  dta$income <- dta$income * 1.1

  expect_warning(
    result <- f_calc_deciles(
      dta,
      dec_var = "income",
      wt_var = "weight",
      n_dec = 5,
      fixed_dec_var = "income"
    ),
    "[Ff]actor|[Cc]oerce"
  )
  expect_s3_class(result[["income___decile"]], "factor")
})

test_that("fixed_dec_var in both dec_var and fixed_dec_var: fixed wins with inform", {
  dta <- make_fixed_dec_data()
  original_deciles <- dta[["income___decile"]]
  dta$income <- dta$income * 2

  expect_message(
    result <- f_calc_deciles(
      dta,
      dec_var = "income",
      wt_var = "weight",
      n_dec = 5,
      fixed_dec_var = "income"
    ),
    "[Ff]ixed|not be recomputed"
  )
  expect_identical(result[["income___decile"]], original_deciles)
})

test_that("fixed_dec_var = NULL (default) recomputes as before", {
  dta <- make_fixed_dec_data()
  # Invert income so ranks flip: formerly poorest become richest
  dta_inverted <- dta
  dta_inverted$income <- max(dta$income) - dta$income + 1

  result_default  <- f_calc_deciles(dta_inverted, dec_var = "income", wt_var = "weight", n_dec = 5)
  result_explicit <- f_calc_deciles(dta_inverted, dec_var = "income", wt_var = "weight", n_dec = 5,
                                    fixed_dec_var = NULL)

  # Both recompute and agree with each other
  expect_identical(result_default[["income___decile"]], result_explicit[["income___decile"]])
  # Both differ from original baseline (ranks flipped)
  expect_false(identical(result_default[["income___decile"]], dta[["income___decile"]]))
})

test_that("f_calc_deciles_by_sim propagates fixed_dec_var across all simulations", {
  set.seed(99)
  n <- 200

  # Build a simple baseline with deciles pre-computed
  baseline_raw <- data.frame(
    income = runif(n, 1000, 10000),
    weight = rep(1, n)
  ) |> f_calc_deciles(dec_var = "income", wt_var = "weight", n_dec = 5)
  baseline_dec <- baseline_raw[["income___decile"]]

  # Reform: invert incomes so ranks would flip if recomputed
  reform_raw <- baseline_raw  # already has income___decile from baseline
  reform_raw$income <- max(baseline_raw$income) - baseline_raw$income + 1

  sim_list <- list(
    policy0 = list(policy_sim_raw = baseline_raw, policy_name = "Baseline"),
    policy1 = list(policy_sim_raw = reform_raw,   policy_name = "Reform")
  )

  result <- f_calc_deciles_by_sim(
    dta_sim = sim_list,
    dec_var = "income",
    wt_var = "weight",
    n_dec = 5,
    fixed_dec_var = "income"
  )

  dec_baseline <- result[[1]][["policy_sim_raw"]][["income___decile"]]
  dec_reform   <- result[[2]][["policy_sim_raw"]][["income___decile"]]

  # Fixed: decile assignments identical across policies (baseline ranks preserved)
  expect_identical(dec_baseline, dec_reform)
  expect_identical(dec_baseline, baseline_dec)

  # Contrast: without fixed, reform deciles would differ
  result_free <- f_calc_deciles_by_sim(
    dta_sim = list(
      policy1 = list(policy_sim_raw = reform_raw |> select(-income___decile),
                     policy_name = "Reform free")
    ),
    dec_var = "income",
    wt_var = "weight",
    n_dec = 5
  )
  expect_false(identical(
    result_free[[1]][["policy_sim_raw"]][["income___decile"]],
    baseline_dec
  ))
})
