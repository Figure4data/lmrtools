# functions for manipulating LMR data once imported via database_functions.R
# - functions mostly taken from functions_data.R in bc-lmr-data-products
# - moved here for broader access

#' Summarize data by category type by year
#' @return A dataframe of aggregated data by category type, year
#' @param dataset A dataframe of raw lmr data with filters applied
#' @param dataset_all A dataframe of raw unfiltered lmr data for calculating percent share 
#' @export
aggregate_annual_cat_type <- function(dataset, dataset_all=beer_data) {
  cat("fn: aggregate_annual_cat_type from lmrtools \n")
  # summarize higher level data for % of ttl calculations
  dataset_yr <- dataset_all |> dplyr::group_by(cyr) |> 
    dplyr::summarize(ttl_sales = sum(netsales),
              ttl_litres = sum(litres),
              max_qtr = max(as.character(cqtr)) # for partial yr flag
            ) |> 
    dplyr::mutate(# two yr flags - one for lines, one for points
           yr_flag = ifelse(max_qtr == "Q4", "full", "partial"),
           yr_flag_line = ifelse(yr_flag == "partial", "partial", dplyr::lead(yr_flag))) |> 
    dplyr::ungroup() 
  dataset_yr <- dataset_yr |> 
    dplyr::mutate(yr_flag_line = ifelse(is.na(yr_flag_line), "full", yr_flag_line), 
  )
  # summarize current level (cat_type)
  dataset <- dataset |> dplyr::group_by(cat_type, cyr) |> 
              dplyr::summarize(netsales = sum(netsales),
                        litres = sum(litres)) |> 
                #ungroup() |>
              dplyr::mutate(yoy_sales = (netsales - dplyr::lag(netsales))/dplyr::lag(netsales),
                    yoy_litres = (litres - dplyr::lag(litres))/dplyr::lag(litres))
  # add percent of totals for each category type
  # - join totals to category data set and calculate percentages
  dataset <- dplyr::left_join(dataset, dataset_yr, by=c("cyr")) |>
              dplyr::mutate(pct_ttl_sales = netsales/ttl_sales,
                     pct_ttl_litres = litres/ttl_litres)
  # add yoy chg calculations for % of total
  dataset <- dataset |> 
    # convert cyr to number for lag calculation
    dplyr::mutate(cyr = as.numeric(as.character(cyr))) |>
    dplyr::group_by(cat_type) |> # only need to group for cat_type
    # multiply by 100 to get point values - avoid confusion with %
    dplyr::mutate(yoy_pcp_ttl_sales = (pct_ttl_sales - lag(pct_ttl_sales))*100,
           yoy_pcp_ttl_litres = (pct_ttl_litres - lag(pct_ttl_litres))*100,
           # creating dummy variable to enable color fill in facet plot
           dummy_fill = 'x') |> 
      dplyr::ungroup()
  # reset cyr to factor for plotting
  dataset$cyr <- as.factor(dataset$cyr)
  return(dataset)
}

#' Summarize data by category type by quarter
#' @return A dataframe of aggregated data by category type, quarter
#' @param dataset A dataframe of raw lmr data with filters applied
#' @param n_qtr Number of quarters in each yr; default is 4
#' @export
aggregate_qtr_cat_type <- function(dataset, n_qtr=4) {
  cat("fn: aggregate_qtr_cat_type from lmrtools \n")
  # takes n_qtr from number of quarters selected in input selector for calc yoy lag
  dataset <- dataset %>% group_by(cat_type, cyr, cqtr, cyr_qtr, end_qtr_dt) %>%
    summarize(netsales = sum(netsales),
              litres = sum(litres)) %>% ungroup() %>%
    mutate(qoq_sales = (netsales - lag(netsales))/lag(netsales),
           qoq_litres = (litres - lag(litres))/lag(litres),
           # for same qtr prev yr comparisons
           yoy_qoq_sales = (netsales - lag(netsales, n=n_qtr))/lag(netsales, n=n_qtr),
           yoy_qoq_litres = (litres - lag(litres, n=n_qtr))/lag(litres, n=n_qtr),
           yr_qtr = paste(cyr, cqtr, sep = "-")
    )
  return(dataset)
}

#' Summarize data by year by category within category type OR subcategory within category
#' @return A dataframe of aggregated data by year by category_type/category or category/subcategory (up to two levels)
#' @param dataset A dataframe of raw lmr data with filters applied
#' @param high_cat Character string representing highest level category type or category or subcategory
#' @param low_cat Character string representing low level category/subcategory
#' @param dataset_all A dataframe of raw unfiltered lmr data for calculating percent share
#' @export
aggregate_annual_cat_subcat <- function(dataset, high_cat, low_cat, dataset_all) {
  cat("fn: aggregate_annual_cat_subcat from lmrtools \n")
  # get totals for yr to use in % of total calculations
  # - should not change based on cat filters, since should be consistent % of total
  dataset_yr <- dataset_all %>% group_by(cyr, !!sym(high_cat)) %>% 
    summarize(ttl_sales = sum(netsales),
              ttl_litres = sum(litres),
              max_qtr = max(as.character(cqtr)) # for partial yr flag
            ) %>% mutate(
              yr_flag = ifelse(max_qtr == "Q4", "full", "partial"),
              ) %>% 
    ungroup()
  # summarize current level (category)
  dataset <- dataset %>% 
    group_by(cyr, !!sym(high_cat), !!sym(low_cat)) %>%  
    summarize(netsales = sum(netsales),
              litres = sum(litres)) %>% 
    ungroup()
  # get yoy calculations
  n_lag <- length(unique(dataset[[low_cat]]))
  dataset <- dataset %>% 
    # convert cyr to number for lag calculation
    mutate(cyr = as.numeric(as.character(cyr))) %>% 
    group_by(cyr, !!sym(high_cat), !!sym(low_cat)) %>% ungroup() %>%
    mutate(yoy_sales = (netsales - lag(netsales, n=n_lag))/lag(netsales, n=n_lag),
           yoy_litres = (litres - lag(litres, n=n_lag))/lag(litres, n=n_lag),
          # order cat_type by sales
           category = reorder(category, netsales, FUN = sum)
    ) %>% ungroup()
  # restore cyr to factor
  dataset$cyr <- as.factor(dataset$cyr)
  # add percent of totals for each category
  # - join totals to category data set and calculate percentages
  dataset <- left_join(dataset, dataset_yr, by=c("cyr", high_cat)) %>%
    mutate(pct_ttl_sales = netsales/ttl_sales,
           pct_ttl_litres = litres/ttl_litres)
  # add yoy chg calculations for % of total
  dataset <- dataset %>% 
    group_by(!!sym(low_cat)) %>%
    # multiply by 100 to get point values - avoid confusion with %
    mutate(yoy_pcp_ttl_sales = (pct_ttl_sales - lag(pct_ttl_sales))*100,
           yoy_pcp_ttl_litres = (pct_ttl_litres - lag(pct_ttl_litres))*100) %>% 
    ungroup()
  #print(head(dataset))
  #print(colnames(dataset))
  return(dataset)
}

#' Summarize data by QUARTER by category within category type OR subcategory within category
#' @return A dataframe of aggregated data by quarter by category_type/category or category/subcategory (up to two levels)
#' @param dataset A dataframe of raw lmr data with filters applied
#' @param high_cat Character string representing highest level category type or category or subcategory
#' @param low_cat Character string representing low level category/subcategory
#' @export
aggregate_qtr_cat_subcat <- function(dataset, high_cat, low_cat) {
  cat("fn: aggregate_qtr_cat_subcat from lmrtools \n")
  # get totals for qtr to use in % of total calculations
  # - should not change based on cat filters, since should be consistent % of total
  dataset_qtr <- dataset %>% group_by(cyr, cyr_qtr, cqtr, !!sym(high_cat)) %>% 
    summarize(ttl_sales = sum(netsales),
              ttl_litres = sum(litres)
            )  %>% ungroup()
  # summarize current level (category)
  n_lag <- length(unique(dataset[[low_cat]]))
  n_qtr <- length(unique(dataset$cqtr))
  dataset <- dataset %>% 
    group_by(cyr, cyr_qtr, cqtr, !!sym(high_cat), !!sym(low_cat),) %>% 
    summarize(netsales = sum(netsales),
              litres = sum(litres)) %>% 
    ungroup() %>%
    mutate(qoq_sales = (netsales - lag(netsales, n=n_lag))/lag(netsales, n=n_lag),
           qoq_litres = (litres - lag(litres, n=n_lag))/lag(litres, n_lag),
           yoy_qoq_sales = (netsales - lag(netsales, n=n_lag*n_qtr))/lag(netsales, n=n_lag*n_qtr),
           yoy_qoq_litres = (litres - lag(litres, n=n_lag*n_qtr))/lag(litres, n=n_lag*n_qtr),
           yr_qtr = paste(cyr, cqtr, sep = "-")
    )
  
  # add percent of totals for each category
  # - join totals to category data set and calculate percentages
  dataset <- left_join(dataset, dataset_qtr, by=c("cyr","cqtr","cyr_qtr", high_cat)) %>%
    mutate(pct_ttl_sales = netsales/ttl_sales,
           pct_ttl_litres = litres/ttl_litres)
  # add qoq chg calculations for change in % of total (market share)
  dataset <- dataset %>% 
    group_by(!!sym(low_cat)) %>% 
    # multiply by 100 to get point values - avoid confusion with %
    # NOT USED at QTR level - may need revising to take acct qtrs filtering
    # not sure how this even works (category but not year/qtr?)
    mutate(qoq_pcp_ttl_sales = (pct_ttl_sales - lag(pct_ttl_sales))*100,
           qoq_pcp_ttl_litres = (pct_ttl_litres - lag(pct_ttl_litres))*100) %>% 
    ungroup()
  #print(head(dataset))
  #print(colnames(dataset))
  return(dataset)
}