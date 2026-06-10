# --- Tests for f_agg_by_decile_by_sim ---
# Applies f_agg_by_decile() to each simulation and combines with sim column

# Tier 1: Package data
test_that("f_agg_by_decile_by_sim produces sim column with both policy names", {
  result <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  expect_true("sim" %in% names(result))
  sim_vals <- unique(result[["sim"]])
  expect_equal(length(sim_vals), 2)
  expect_true("Baseline" %in% sim_vals)
  expect_true("Sim 1" %in% sim_vals)
})

test_that("f_agg_by_decile_by_sim row count is 2x single sim", {
  result_full <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  result_one <- f_agg_by_decile(
    dta = dta_sim$policy0$policy_sim_raw,
    var_decile = "ym___decile",
    var_agg = c("ym", "dtx_prog1"),
    var_group = "all",
    wt_var = "hhwt"
  )

  # 2 simulations x single sim rows
  expect_equal(nrow(result_full), 2 * nrow(result_one))
})

# Tier 2: Correct synthetic
test_that("f_agg_by_decile_by_sim works with single simulation", {
  single_sim <- list(
    policy0 = list(
      policy_sim_raw = dta_hh,
      policy_name = "Only policy"
    )
  )

  result <- f_agg_by_decile_by_sim(
    dta_sim = single_sim,
    var_decile = "ym___decile",
    var_agg = "ym",
    var_group = "all",
    wt_var = "hhwt"
  )

  expect_equal(length(unique(result[["sim"]])), 1)
  expect_equal(unique(result[["sim"]]), "Only policy")
})

test_that("f_agg_by_decile_by_sim output matches f_agg_by_decile + sim column", {
  result_by_sim <- f_agg_by_decile_by_sim(
    dta_sim = dta_sim,
    var_decile = "ym___decile",
    var_agg = "ym",
    var_group = "all",
    wt_var = "hhwt"
  )

  result_direct <- f_agg_by_decile(
    dta = dta_sim$policy0$policy_sim_raw,
    var_decile = "ym___decile",
    var_agg = "ym",
    var_group = "all",
    wt_var = "hhwt"
  )

  # Filter by_sim result to baseline only
  baseline <- result_by_sim[result_by_sim[["sim"]] == "Baseline", ]
  expect_equal(baseline[["level"]], result_direct[["level"]])
})

test_that("f_agg_by_decile_by_sim sim column values match policy_name", {
  custom_sim <- list(
    s1 = list(policy_sim_raw = dta_hh, policy_name = "Policy Alpha"),
    s2 = list(policy_sim_raw = dta_hh, policy_name = "Policy Beta")
  )

  result <- f_agg_by_decile_by_sim(
    dta_sim = custom_sim,
    var_decile = "ym___decile",
    var_agg = "ym",
    var_group = "all",
    wt_var = "hhwt"
  )

  expect_true("Policy Alpha" %in% result[["sim"]])
  expect_true("Policy Beta" %in% result[["sim"]])
})

# Tier 3: Bad inputs
test_that("f_agg_by_decile_by_sim returns empty tibble for empty list", {
  result <- f_agg_by_decile_by_sim(
    dta_sim = list(),
    var_decile = "ym___decile",
    var_agg = "ym"
  )

  expect_equal(nrow(result), 0)
})

test_that("f_agg_by_decile_by_sim handles NULL policy_name with warning", {
  null_name_sim <- list(
    s1 = list(policy_sim_raw = dta_hh, policy_name = NULL)
  )

  expect_warning(
    result <- f_agg_by_decile_by_sim(
      dta_sim = null_name_sim,
      var_decile = "ym___decile",
      var_agg = "ym",
      var_group = "all",
      wt_var = "hhwt"
    ),
    "no.*policy_name|Policy"
  )

  # sim column should exist with fallback name
  expect_true("sim" %in% names(result))
  expect_equal(unique(result[["sim"]]), "Policy s1")
})

test_that("f_agg_by_decile_by_sim propagates error from missing decile var", {
  bad_sim <- list(
    s1 = list(policy_sim_raw = data.frame(x = 1:5), policy_name = "Bad")
  )

  expect_error(
    f_agg_by_decile_by_sim(
      dta_sim = bad_sim,
      var_decile = "ym___decile",
      var_agg = "x"
    ),
    "None of|not found"
  )
})
