# devCEQ — Domain Context

## What this package does

`devCEQ` is a World Bank R package that provides standardised infrastructure for building country-specific **fiscal microsimulation Shiny apps** for the Poverty and Equity Policy Lab. Country teams plug in their own microdata and simulation logic; the package provides the full UI shell, input wiring, simulation orchestration, and results display.

Built on [golem](https://thinkr-open.github.io/golem/). Deployed apps exist for Cameroon, Senegal, Côte d'Ivoire, Benin, Indonesia, and others.

---

## Module structure

### Entry points

| File | Role |
|---|---|
| `R/CEQ_run.R` | Top-level function `CEQ_run()` — the single call a country app makes to launch the app |
| `R/CEQ_server.R` | Main Shiny server; wires all modules together |
| `R/CEQ_ui.R` | Main Shiny UI; composes the app shell |
| `R/app_config.R` | golem app configuration |
| `R/zzz.R` | Package startup hooks |

### Active modules — inputs pipeline

| File | Key functions | Notes |
|---|---|---|
| `R/mod_inputs_logic.R` | `mod_inputs_server`, `mod_inputs_ui_wrapper`, `mod_dyn_inp_srv`, `mod_build_inp_srv`, `mod_render_inp_tabs_srv` | Orchestrates all input-side logic; called directly from `CEQ_server.R` |
| `R/mod_inputs_btns.R` | `mod_inputs_btns_server`, `mod_inputs_btns_ui` | Policy-count buttons; called from `mod_inputs_logic.R` |
| `R/mod_inp_n_choices.R` | `mod_inp_n_choices_server`, `mod_inp_n_choices_ui` | Number-of-policies selector; called from `mod_inputs_btns.R` |
| `R/mod_inputs_tabs.R` | `mod_render_inp_tabs_srv`, `mod_inp_tabs_ui`, `mod_inp_tab_switches_ui` | Tabbed input UI; called from `mod_inputs_logic.R` |

### Active modules — simulation

| File | Key functions | Notes |
|---|---|---|
| `R/mod_generic_run_sim.R` | `mod_generic_run_sim_server`, `make_run_sim_server` | Runs the microsimulation; injected into `CEQ_server.R` via `fn_sim_srvr` parameter |
| `R/mod_generic_run_postsim.R` | `mod_generic_run_postsim_server` | Post-simulation processing; injected via `fn_postsim_srvr` |

### Active modules — results display (`m_*` newer pattern)

| File | Key functions | Notes |
|---|---|---|
| `R/m_inputs.R` | `m_inputs_ui` | Input section UI; used in `CEQ_ui.R` via `ceq_ui_new` |
| `R/m_incid.R` | `m_incid_ui`, `m_incid_srv` | Main results/incidences module; injected as `fn_res_disp_srvr` |
| `R/m_pov.R` | `m_pov_srv`, `m_povgini_ui`, `m_povgini_srv` | Poverty and Gini results; called from `m_incid.R` |
| `R/m_outputs.R` | `m_output_ui`, `m_output_srv`, `m_one_output_srv` | Generic output panels; called from `m_incid.R` |
| `R/m_figure.R` | `m_figure_ui`, `m_figure_server` | Figure display; called from `m_incid.R` |
| `R/m_helpers.R` | `f_title_ui`, `f_numericInput_ui`, `f_selegenInput_ui` | Shared UI utility helpers |

---

## Visualization subsystem (deep dive)

### Overview

The visualization layer is a **two-tier system**: the _results page module_ (`m_incid`, `m_pov`) drives the data pipeline, and a generic _output renderer_ (`m_outputs` + `m_figure`) handles displaying any supported object type. Country teams inject their own figures by returning them from the simulation function — they never touch the rendering layer.

### Supported output types

`m_figure_server` / `m_output_srv` detect class and dispatch rendering:

| Type string | R class | How rendered |
|---|---|---|
| `"ggplot"` | `ggplot` | Converted to plotly via `ggplotly()` when `force_ly = TRUE`, else `renderPlot` |
| `"plotly"` | `plotly` / `htmlwidget` | `plotly::renderPlotly` |
| `"datatables"` | `datatables` (DT) | `DT::renderDT` |
| `"flextable"` | `flextable` | `flextable::htmltools_value` |
| `"reactable"` | `reactable` | `reactable::renderReactable` |
| `"data.frame"` | `data.frame` | rendered as a table |

Type detection chain: `is_single_output()` → `get_single_output_type()` → `get_output_structure()`. Legacy alias: `check_object_type()` (in `m_figure.R`); newer: `check_output_type()` (in `m_outputs.R`).

List normalisation helpers in `m_outputs.R`: `flatten_if_single()`, `flatten_outputs()`, `enlist_if_not_list()`, `f_enlist_fig()`.

### Module: `m_incid` — incidence results page

**File**: `R/m_incid.R` | **Functions**: `m_incid_ui()`, `m_incid_srv()`

The main results page. Receives `sim_res` (reactive list of simulation outputs) and owns the full pipeline from raw simulation data to figures.

**Data pipeline:**

```
sim_res()
  └─ f_calc_deciles_by_sim()         # assign households to deciles
  └─ f_agg_by_decile_by_sim()        # aggregate fiscal variables by decile
  └─ f_calc_incidence()              # compute relative/absolute/level incidence
  └─ f_format_incidence()            # → dta_1_incid (wide tidy)
       └─ filter by decile_var       # → dta_2_a
       └─ filter by measure          # → dta_2_b
       └─ f_filter_grouped_stats()   # → dta_2_c (group by)
       └─ filter by group_val        # → dta_out
            └─ f_plot_gg()           # → named list of ggplots → fig$ggs
```

**User filter controls** (all via `m_input_srv`): `ndec` (n deciles), `decby` (decile variable), `incid` (relative/absolute/level), `grpby` (group-by variable), `grpfltr` (group filter), `pltby` (figure selector, optional).

**Outputs:**
- `m_output_srv("fig1", figures = fig$ggs)` → bar chart per fiscal variable, plotly
- `m_output_srv("tbl1", figures = dta_out_formatted |> f_format_rt())` → reactable table
- `m_download_srv(...)` → Excel export modal

**Key country-customisation parameters** (all have defaults): `var_inc`, `var_wt`, `var_group`, `var_agg`, `page_title`, filter titles/choices, `page_ui` (layout function).

### Module: `m_pov` — poverty & Gini results page

**File**: `R/m_pov.R` | **Functions**: `m_pov_srv()`, `m_povgini_ui()`, `m_povgini_srv()`

Parallel structure to `m_incid` but computes poverty headcounts, poverty gaps, and Gini coefficients across income concepts. Key step: filters `sim_res()` to rows where `policy_sim_raw` is non-null before any computation. Renders via `m_output_srv`.

### Module: `m_outputs` — generic output renderer

**File**: `R/m_outputs.R` | **Functions**: `m_output_ui()`, `m_output_srv()`, `m_one_output_srv()`

Accepts _any_ supported object type or a named list thereof. Handles type detection, dispatch to the correct `render*` function, and named-list → tab navigation.

### Module: `m_figure` — lower-level figure updater

**File**: `R/m_figure.R` | **Functions**: `m_figure_ui()`, `m_figure_server()`

Older/simpler renderer for a single `figures` reactive + external `selected` reactive. Always converts ggplot → plotly when `force_ly = TRUE`. `check_object_type()` here is the original type-detection function (refactored as `check_output_type()` in `m_outputs.R`).

### Plot construction helpers

| File | Key functions | Purpose |
|---|---|---|
| `R/f_gg.R` | `f_plot_gg()` | General ggplot2 wrapper (line or bar); used by `m_incid` to build per-variable bar charts |
| `R/fct_ncp_plots.R` | `fct_make_ncp_gg()`, `fct_make_ncp_ly()` | Stacked bar + line overlay charts for N-choice-policy (NCP) results |
| `R/fct_plot_helpers.R` | `plotly_config()`, `flextable_config()`, `fct_config_export_dt()` | Plotly toolbar config, flextable styling, DT export config |
| `R/fct_config_plotly.R` | `format_plotly()` | Plotly post-processing (layout, margins) |
| `R/fct_config_DT.R` | — | DT table styling helpers |
| `R/f_theme.R` | — | bslib / Bootstrap theme used across all outputs |
| `R/fct_wb_colours.R` | — | World Bank brand colours for plots |

### Download / export

| File | Key functions | Notes |
|---|---|---|
| `R/m_download.R` | `m_download_ui()`, `m_download_srv()` | Modal-based Excel export; called from `m_incid_srv` and `m_pov_srv` |
| `R/mod_save_gg_2.R` | `save_ggplot_server2` | ggplot PNG download; used in older `mod_gini_poverty` and `mod_incidences` |
| `R/f_xlsx.R` | — | Lower-level xlsx construction |

### Visualization call hierarchy

```
m_incid_srv  /  m_pov_srv
  ├── m_input_srv × 5-6           # filter controls
  ├── [data pipeline]
  │    └── f_plot_gg()            # builds named list of ggplots
  ├── m_output_srv("fig1")        # renders figures
  │    └── m_figure_server        # type-detect → plotly/DT/etc.
  │         └── format_plotly()
  ├── m_output_srv("tbl1")        # renders reactable table
  │    └── f_format_rt()
  └── m_download_srv              # Excel export modal
```

### Active modules — misc

| File | Key functions | Notes |
|---|---|---|
| `R/mod_info_page.R` | `mod_info_page_server` | Info/about page; called from `CEQ_server.R` |
| `R/mod_browser_button.R` | `mod_browser_button_server`, `mod_browser_button_ui` | Dev debug browser button |
| `R/mod_dev_results.R` | `mod_dev_res_server`, `mod_dev_res_ui` | Dev-mode results tab |
| `R/mod_save_gg_2.R` | `save_ggplot_server2` | ggplot download; called from `mod_gini_poverty.R` and `mod_incidences.R` |

### Example-only modules (not part of main app flow)

| File | Key functions | Notes |
|---|---|---|
| `R/mod_gini_poverty.R` | `mod_gini_ui`, `mod_gini_pov_gen_server` | Only used in `inst/examples/ceq_example_simple/` |
| `R/mod_incidences.R` | `mod_incidences_ui`, `mod_incidences_server` | Old version; only used in examples |

### Dev/test-only files

| File | Notes |
|---|---|
| `R/mod-res-test.R` | Results layout dev/test module; hyphenated name is non-standard |
| `R/test_input_sim.R` | Test runner; not exported in NAMESPACE |
| `R/m_diagnostics.R` | Diagnostic output with internal test/demo functions |
| `R/m_download.R` | Download module with internal demo functions; not confirmed wired into main app |

### Candidates for deletion

| File | Notes |
|---|---|
| `R/fct_z_delete.R` | 100% commented-out deprecated functions; nothing live |
| `R/mod_ceq_progress.R` | Defines `mod_ceq_progress()` but `CEQ_server.R` uses `fct_make_ceq_progress()` directly — function is never called |

---

## Module call hierarchy

```
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
```

---

## Helper / utility files

| File | Notes |
|---|---|
| `R/fct_calc_helpers.R` | Calculation utilities |
| `R/fct_config_DT.R` | DT table configuration |
| `R/fct_config_plotly.R` | Plotly configuration |
| `R/fct_create_microsim.R` | Microsimulation construction helpers |
| `R/fct_data.R` | Data loading/processing |
| `R/fct_gini_poverty.R` | Gini/poverty computation |
| `R/fct_incidences.R` | Incidence analysis computation |
| `R/fct_input_prep_key.R` | Input key preparation |
| `R/fct_input_ui.R` | Input UI generation from Excel structure |
| `R/fct_ncp.R` | N-choice-policy logic |
| `R/fct_ncp_plots.R` | N-choice-policy plot helpers |
| `R/fct_plot_helpers.R` | Plot utility functions |
| `R/fct_sim_helpers.R` | Simulation utility functions |
| `R/fct_tab_input_ui.R` | Tab-based input UI helpers |
| `R/fct_test_helpers.R` | Test helper functions (used in `dev/`) |
| `R/fct_variables.R` | Variable name/type management |
| `R/fct_wb_colours.R` | World Bank colour palette |
| `R/f_gg.R` | ggplot2 wrappers |
| `R/f_povineq.R` | Poverty/inequality formatting |
| `R/f_rt.R` | Reactable table helpers |
| `R/f_tbl.R` | Table utilities |
| `R/f_theme.R` | App theme/styling |
| `R/f_var_helpres.R` | Variable helper functions |
| `R/f_xlsx.R` | Excel export utilities |
