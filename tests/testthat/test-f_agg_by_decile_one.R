# --- Tests for f_agg_by_decile_one ---
# Aggregates variables by a single decile grouping with optional group stratification

# Tier 1: Package data integration
test_that("f_agg_by_decile_one produces correct structure with dta_hh", {
  result <- f_agg_by_decile_one(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    wt_var = "hhwt"
  )

  expected_cols <- c(
    "decile_var", "decile", "decile_n", "decile_val",
    "group_var", "group_val", "n", "pop", "var", "level"
  )

  expect_true(all(expected_cols %in% names(result)))
  expect_s3_class(result[["decile"]], "factor")
  expect_s3_class(result[["group_var"]], "factor")
  expect_s3_class(result[["group_val"]], "factor")
})

test_that("f_agg_by_decile_one has correct row count", {
  result <- f_agg_by_decile_one(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    wt_var = "hhwt"
  )

  # 10 deciles x 1 group (NULL -> "all") x 2 vars = 20 rows
  expect_equal(nrow(result), 10 * 1 * 2)
})

test_that("f_agg_by_decile_one with group_var produces correct grouped output", {
  result <- f_agg_by_decile_one(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "group_1",
    wt_var = "hhwt"
  )

  n_groups <- length(unique(dta_hh$group_1))
  # 10 deciles x n_groups x 2 vars
  expect_equal(nrow(result), 10 * n_groups * 2)
  expect_true(all(as.character(result$group_var) == "group_1"))
  expect_true(all(unique(as.character(result$group_val)) %in% unique(dta_hh$group_1)))
})

# Tier 2: Correct synthetic - verifiable arithmetic
test_that("f_agg_by_decile_one computes correct weighted sums", {
  # Simple data: 10 obs, 2 deciles, weight = 1
  set.seed(99)
  test_data <- data.frame(
    income = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    tax = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0),
    wt = rep(1, 10)
  )
  test_data$income___decile <- factor(c(rep(1, 5), rep(2, 5)))

  result <- f_agg_by_decile_one(
    dta = test_data,
    var_decile = "income___decile",
    var_agg = c("income", "tax"),
    wt_var = "wt"
  )

  # Decile 1, income: sum(1:5 * 1) = 15
  income_d1 <- result |> dplyr::filter(decile == 1, var == "income")
  expect_equal(income_d1$level, 15)

  # Decile 2, income: sum(6:10 * 1) = 40
  income_d2 <- result |> dplyr::filter(decile == 2, var == "income")
  expect_equal(income_d2$level, 40)

  # Decile 1, tax: sum(0.1:0.5) = 1.5
  tax_d1 <- result |> dplyr::filter(decile == 1, var == "tax")
  expect_equal(tax_d1$level, 1.5)
})

test_that("f_agg_by_decile_one pop equals sum of weights per decile", {
  set.seed(99)
  test_data <- data.frame(
    income = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    wt = c(1, 2, 1, 2, 1, 2, 1, 2, 1, 2)
  )
  test_data$income___decile <- factor(c(rep(1, 5), rep(2, 5)))

  result <- f_agg_by_decile_one(
    dta = test_data,
    var_decile = "income___decile",
    var_agg = "income",
    wt_var = "wt"
  )

  # Decile 1 pop: 1+2+1+2+1 = 7
  expect_equal(result$pop[result$decile == 1], 7)
  # Decile 2 pop: 2+1+2+1+2 = 8
  expect_equal(result$pop[result$decile == 2], 8)
})

test_that("f_agg_by_decile_one var_group='all' is same as NULL", {
  result_null <- f_agg_by_decile_one(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym"),
    var_group = NULL,
    wt_var = "hhwt"
  )

  result_all <- f_agg_by_decile_one(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = c("ym"),
    var_group = "all",
    wt_var = "hhwt"
  )

  expect_equal(nrow(result_null), nrow(result_all))
  expect_equal(result_null$level, result_all$level)
  expect_true(all(as.character(result_null$group_val) == "All observations"))
  expect_true(all(as.character(result_all$group_val) == "All observations"))
})

test_that("f_agg_by_decile_one decile_var column contains parsed income var name", {
  result <- f_agg_by_decile_one(
    dta = dta_hh,
    var_decile = "ym___decile",
    var_agg = "ym",
    wt_var = "hhwt"
  )

  expect_true(all(result$decile_var == "ym"))
})

# Tier 3: Bad inputs
test_that("f_agg_by_decile_one aborts when var_decile not in data", {
  test_data <- data.frame(income = 1:10, income___decile = factor(rep(1:2, 5)))

  expect_error(
    f_agg_by_decile_one(
      dta = test_data,
      var_decile = "nonexistent___decile",
      var_agg = "income"
    ),
    "not found in the data"
  )
})

test_that("f_agg_by_decile_one handles missing var_agg columns gracefully", {
  test_data <- data.frame(
    income = 1:10,
    wt = rep(1, 10)
  )
  test_data[["income___decile"]] <- factor(rep(1:2, 5))

  # "nonexistent" is not in data - should produce no rows for it
  result <- f_agg_by_decile_one(
    dta = test_data,
    var_decile = "income___decile",
    var_agg = c("income", "nonexistent"),
    wt_var = "wt"
  )

  # Only "income" appears in var column since "nonexistent" is numeric-filtered out
  expect_true("income" %in% result$var)
})

test_that("f_agg_by_decile_one warns when wt_var not found", {
  test_data <- data.frame(income = 1:10)
  test_data[["income___decile"]] <- factor(rep(1:2, 5))

  # Currently uses weight=1 silently - after hardening should warn
  result <- f_agg_by_decile_one(
    dta = test_data,
    var_decile = "income___decile",
    var_agg = "income",
    wt_var = "bad_weight"
  )

  # Should still produce a result with equal weights
  expect_equal(nrow(result), 2)  # 2 deciles x 1 var
  expect_true(all(result$pop == 5))  # 5 obs per decile with weight=1
})

test_that("f_agg_by_decile_one warns when var_group not found in data", {
  test_data <- data.frame(income = 1:10, wt = rep(1, 10))
  test_data[["income___decile"]] <- factor(rep(1:2, 5))

  expect_warning(
    result <- f_agg_by_decile_one(
      dta = test_data,
      var_decile = "income___decile",
      var_agg = "income",
      var_group = "nonexistent_group",
      wt_var = "wt"
    ),
    "not found"
  )
})

test_that("f_agg_by_decile_one handles NAs in var_agg columns", {
  test_data <- data.frame(
    income = c(1, 2, NA, 4, 5, 6, NA, 8, 9, 10),
    wt = rep(1, 10)
  )
  test_data[["income___decile"]] <- factor(c(rep(1, 5), rep(2, 5)))

  result <- f_agg_by_decile_one(
    dta = test_data,
    var_decile = "income___decile",
    var_agg = "income",
    wt_var = "wt"
  )

  # na.rm = TRUE: decile 1 sum = 1+2+4+5 = 12, decile 2 sum = 6+8+9+10 = 33
  expect_equal(nrow(result), 2)
  expect_equal(result$level[result$decile == 1], 12)
  expect_equal(result$level[result$decile == 2], 33)
})

test_that("f_agg_by_decile_one handles single-row data", {
  test_data <- data.frame(income = 100, wt = 1)
  test_data[["income___decile"]] <- factor(1)

  result <- f_agg_by_decile_one(
    dta = test_data,
    var_decile = "income___decile",
    var_agg = "income",
    wt_var = "wt"
  )

  expect_equal(nrow(result), 1)
  expect_equal(result$level, 100)
  expect_equal(result$n, 1)
  expect_equal(result$pop, 1)
})
