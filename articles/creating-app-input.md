# Creating app's input page

``` r

library(devCEQ)
# library(tidyverse)
```

Useful functions:

``` r

?load_input_xlsx
#> No documentation for 'load_input_xlsx' in specified packages and libraries:
#> you could try '??load_input_xlsx'
?inp_str_test
#> No documentation for 'inp_str_test' in specified packages and libraries:
#> you could try '??inp_str_test'
?gen_inp_str_front
#> No documentation for 'gen_inp_str_front' in specified packages and libraries:
#> you could try '??gen_inp_str_front'
?gen_tabinp_ui_front
#> No documentation for 'gen_tabinp_ui_front' in specified packages and libraries:
#> you could try '??gen_tabinp_ui_front'
?test_gen_inp_front_simple
#> No documentation for 'test_gen_inp_front_simple' in specified packages and libraries:
#> you could try '??test_gen_inp_front_simple'
?test_gen_inp_front_tabs
#> No documentation for 'test_gen_inp_front_tabs' in specified packages and libraries:
#> you could try '??test_gen_inp_front_tabs'
```

``` r

?load_inputtabs_xlsx
#> No documentation for 'load_inputtabs_xlsx' in specified packages and libraries:
#> you could try '??load_inputtabs_xlsx'
?load_inputtables_xlsx
#> No documentation for 'load_inputtables_xlsx' in specified packages and libraries:
#> you could try '??load_inputtables_xlsx'
?gen_tabinp_ui_front
#> No documentation for 'gen_tabinp_ui_front' in specified packages and libraries:
#> you could try '??gen_tabinp_ui_front'
?gen_tabinp_ui
#> No documentation for 'gen_tabinp_ui' in specified packages and libraries:
#> you could try '??gen_tabinp_ui'
?test_genui_fn
#> No documentation for 'test_genui_fn' in specified packages and libraries:
#> you could try '??test_genui_fn'
```

``` r


path <- "./data-raw/complex-inputs-structure.xlsx"
path <- "../ivory_coast/civCEQapp/data-app/civ-inputs-structure.xlsx"
inp_raw_str <- path %>% load_input_xlsx()
inp_tab_str <- path %>% load_inputtabs_xlsx()
inp_table_str <- path %>% load_inputtables_xlsx()

# Simple UI generation
test_gen_inp_front_simple(inp_raw_str)
test_gen_inp_front_simple(inp_raw_str, inp_tab_str)
test_gen_inp_front_simple(inp_raw_str, NULL, inp_table_str)
test_gen_inp_front_simple(inp_raw_str, inp_tab_str, inp_table_str, n_choices = 12)




# Checking if the tabs are working with all the files
test_gen_inp_front_tabs_file( "./data-raw/complex-inputs-structure.xlsx")
test_gen_inp_front_tabs_file( "./data-raw/ben-inputs-structure.xlsx")
test_gen_inp_front_tabs_file( "./data-raw/ceq-inputs-idn-2022.xlsx")
test_gen_inp_front_tabs_file( "./data-raw/simple-inputs-structure.xlsx")
```
