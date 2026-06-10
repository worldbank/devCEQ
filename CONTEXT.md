# devCEQ — Domain Context

## What this package does

`devCEQ` is a World Bank R package that provides standardised
infrastructure for building country-specific **fiscal microsimulation
Shiny apps** for the Poverty and Equity Policy Lab. Country teams plug
in their own microdata and simulation logic; the package provides the
full UI shell, input wiring, simulation orchestration, and results
display.

Built on [golem](https://thinkr-open.github.io/golem/). Deployed apps
exist for Cameroon, Senegal, Côte d’Ivoire, Benin, Indonesia, and
others.

------------------------------------------------------------------------

## Module structure

### Entry points

| File | Role |
|----|----|
| `R/CEQ_run.R` | Top-level function `CEQ_run()` — the single call a country app makes to launch the app |
| `R/CEQ_server.R` | Main Shiny server; wires all modules together |
| `R/CEQ_ui.R` | Main Shiny UI; composes the app shell |
| `R/app_config.R` | golem app configuration |
| `R/zzz.R` | Package startup hooks |

### Active modules — inputs pipeline

| File | Key functions | Notes |
|----|----|----|
| `R/mod_inputs_logic.R` | `mod_inputs_server`, `mod_inputs_ui_wrapper`, `mod_dyn_inp_srv`, `mod_build_inp_srv`, `mod_render_inp_tabs_srv` | Orchestrates all input-side logic; called directly from `CEQ_server.R` |
| `R/mod_inputs_btns.R` | `mod_inputs_btns_server`, `mod_inputs_btns_ui` | Policy-count buttons; called from `mod_inputs_logic.R` |
| `R/mod_inp_n_choices.R` | `mod_inp_n_choices_server`, `mod_inp_n_choices_ui` | Number-of-policies selector; called from `mod_inputs_btns.R` |
| `R/mod_inputs_tabs.R` | `mod_render_inp_tabs_srv`, `mod_inp_tabs_ui`, `mod_inp_tab_switches_ui` | Tabbed input UI; called from `mod_inputs_logic.R` |

### Active modules — simulation

| File | Key functions | Notes |
|----|----|----|
| `R/mod_generic_run_sim.R` | `mod_generic_run_sim_server`, `make_run_sim_server` | Runs the microsimulation; injected into `CEQ_server.R` via `fn_sim_srvr` parameter |
| `R/mod_generic_run_postsim.R` | `mod_generic_run_postsim_server` | Post-simulation processing; injected via `fn_postsim_srvr` |

### Active modules — results display (`m_*` newer pattern)

| File | Key functions | Notes |
|----|----|----|
| `R/m_inputs.R` | `m_inputs_ui` | Input section UI; used in `CEQ_ui.R` via `ceq_ui_new` |
| `R/m_incid.R` | `m_incid_ui`, `m_incid_srv` | Main results/incidences module; injected as `fn_res_disp_srvr` |
| `R/m_pov.R` | `m_pov_srv`, `m_povgini_ui`, `m_povgini_srv` | Poverty and Gini results; called from `m_incid.R` |
| `R/m_outputs.R` | `m_output_ui`, `m_output_srv`, `m_one_output_srv` | Generic output panels; called from `m_incid.R` |
| `R/m_figure.R` | `m_figure_ui`, `m_figure_server` | Figure display; called from `m_incid.R` |
| `R/m_helpers.R` | `f_title_ui`, `f_numericInput_ui`, `f_selegenInput_ui` | Shared UI utility helpers |

### Active modules — misc

| File | Key functions | Notes |
|----|----|----|
| `R/mod_info_page.R` | `mod_info_page_server` | Info/about page; called from `CEQ_server.R` |
| `R/mod_browser_button.R` | `mod_browser_button_server`, `mod_browser_button_ui` | Dev debug browser button |
| `R/mod_dev_results.R` | `mod_dev_res_server`, `mod_dev_res_ui` | Dev-mode results tab |
| `R/mod_save_gg_2.R` | `save_ggplot_server2` | ggplot download; called from `mod_gini_poverty.R` and `mod_incidences.R` |

### Example-only modules (not part of main app flow)

| File | Key functions | Notes |
|----|----|----|
| `R/mod_gini_poverty.R` | `mod_gini_ui`, `mod_gini_pov_gen_server` | Only used in `inst/examples/ceq_example_simple/` |
| `R/mod_incidences.R` | `mod_incidences_ui`, `mod_incidences_server` | Old version; only used in examples |

### Dev/test-only files

| File | Notes |
|----|----|
| `R/mod-res-test.R` | Results layout dev/test module; hyphenated name is non-standard |
| `R/test_input_sim.R` | Test runner; not exported in NAMESPACE |
| `R/m_diagnostics.R` | Diagnostic output with internal test/demo functions |
| `R/m_download.R` | Download module with internal demo functions; not confirmed wired into main app |

### Candidates for deletion

| File | Notes |
|----|----|
| `R/fct_z_delete.R` | 100% commented-out deprecated functions; nothing live |
| `R/mod_ceq_progress.R` | Defines `mod_ceq_progress()` but `CEQ_server.R` uses `fct_make_ceq_progress()` directly — function is never called |

------------------------------------------------------------------------

## Module call hierarchy

    CEQ_server.R
     ├── mod_info_page_server
     ├── mod_inputs_server  (mod_inputs_logic.R)
     │    ├── mod_inputs_btns_server
     │    │    └── mod_inp_n_choices_server
     │    └── mod_render_inp_tabs_srv  (mod_inputs_tabs.R)
     ├── mod_generic_run_sim_server      [injected via fn_sim_srvr]
     ├── mod_generic_run_postsim_server  [injected via fn_postsim_srvr]
     ├── [fn_res_disp_srvr]  → m_incid_srv
     │    ├── m_pov_srv / m_povgini_srv
     │    ├── m_output_srv
     │    └── m_figure_server
     ├── mod_dev_res_server
     └── mod_browser_button_server

------------------------------------------------------------------------

## Helper / utility files

| File                      | Notes                                    |
|---------------------------|------------------------------------------|
| `R/fct_calc_helpers.R`    | Calculation utilities                    |
| `R/fct_config_DT.R`       | DT table configuration                   |
| `R/fct_config_plotly.R`   | Plotly configuration                     |
| `R/fct_create_microsim.R` | Microsimulation construction helpers     |
| `R/fct_data.R`            | Data loading/processing                  |
| `R/fct_gini_poverty.R`    | Gini/poverty computation                 |
| `R/fct_incidences.R`      | Incidence analysis computation           |
| `R/fct_input_prep_key.R`  | Input key preparation                    |
| `R/fct_input_ui.R`        | Input UI generation from Excel structure |
| `R/fct_ncp.R`             | N-choice-policy logic                    |
| `R/fct_ncp_plots.R`       | N-choice-policy plot helpers             |
| `R/fct_plot_helpers.R`    | Plot utility functions                   |
| `R/fct_sim_helpers.R`     | Simulation utility functions             |
| `R/fct_tab_input_ui.R`    | Tab-based input UI helpers               |
| `R/fct_test_helpers.R`    | Test helper functions (used in `dev/`)   |
| `R/fct_variables.R`       | Variable name/type management            |
| `R/fct_wb_colours.R`      | World Bank colour palette                |
| `R/f_gg.R`                | ggplot2 wrappers                         |
| `R/f_povineq.R`           | Poverty/inequality formatting            |
| `R/f_rt.R`                | Reactable table helpers                  |
| `R/f_tbl.R`               | Table utilities                          |
| `R/f_theme.R`             | App theme/styling                        |
| `R/f_var_helpres.R`       | Variable helper functions                |
| `R/f_xlsx.R`              | Excel export utilities                   |
