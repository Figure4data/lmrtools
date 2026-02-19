# lmrtools

An R package for working with Figure 4 LMR database. The main purpose is for **standardized queries to the database for purposes of reporting and analysis** in different contexts.

## Installation

\``devtools::install_github("jyuill/lmrtools")`\`

> will need to reinstall any time there are updates.

Also need **credential management**, discussed below.

## Getting credentials

To access the LMR database, you need to obtain credentials:

-   db name
-   host endpoint
-   username
-   password
-   port number

These are available from the **local version of package repo** (NOT Github) or some other repos related to LMR work. Once you have these assembled:

-   `usethis::edit_r_environ(scope="user")`
    -   "user" scope means will be available for any project on the computer
    -   "project" in case just want to apply to individual project for some reason
-   paste into **.Renviron** file that pops up (or may have to type if copy/paste doesn't work)
-   **.Renviron** file now available in repo
-   *ENSURE to add .Renviron to .gitignore*

## Usage

Once installed, refer to `lmrtools::` to see available functions.

**database_functions.R**: notable ones focused on database operations:

-   `list_tables()` : all the tables for LMR, indeed everything in the Figure 4 database
-   `fetch_db_basic()` : query any table in the database; defaults to lmr_data
-   `fetch_lmr_complete_filter()` : most flexible option for retrieving LMR data, since it queries raw lmr_data table joined with additional quarter info and short versions of category type, category, and subcategory names. PLUS, can filter by category type, category, subcategory or date range (end of quarter date).
    -   using parameter replace=TRUE in the function results in short names for category type, category, subcategory replacing original names.

**data_functions.R**: Growing set of functions for data manipulation after queried from database: - `aggregate_annual_cat_type()`: aggregate data by category type and year, with a set of calculated fields such as year-over-year changes; replaces AnnualCatTypeData used in bc-lmr-data-products. - `aggregate_qtr_cat_type()`: same but quarterly aggregration. - `aggregate_annual_cat_subcat()`: annual aggregation by category and/or subcategory. also available at quarter level.

## Updating

It is expected the package will evolve. Main steps in updating (as far as I understand) are:

1.  **database_functions.R**: add or edit functions as desired.
2.  **data_functions.R**: manipulate data by aggregating, enhancing with calculated fields.
3.  **z_imports.R**: add any new packages and functions used so they are available without using @importFrom in the function code and/or referencing package names for functions (`DBI::dbConnect`, `dplyr::mutate` - although still an option, especially if concerned about potential conflicts)
4.  for new functions, follow existing examples with use of \#' comments: @return, @parameters, @export, @import (if needed), etc.
5.  `devtools::use_package('<pkg name>')` if new packages are needed.
    1.  add package name to DESCRIPTION file
6.  `devtools::document()` to update documentation; any time new functions added, new packages used.
7.  `devtools::load_all()` to test locally.
8.  `devtools::check()` to run diagnostics -\> address issues as needed.
9.  `devtools::install()` in DESCRIPTION: manually update version number, then install new version on computer.
10. Push to Github repo to make available on other computers.
11. install updates in projects with `devtools::install_github('jyuill/lmrtools')`
    1.  normally not needed on computer where library is being developed, since `devtools:install()` takes care of local machine.
    2.  sometimes needed if version changes, creates conflict with shiny app publishing

## Viewing Documentation

Documentation is created for the package by using `#'` comments.

-   Run `devtools::document()` to update documentation
    -   will add/edit files to `/man` folder -\> do not make manual changes; manage through `#'` comments in package code
-   DESCRIPTION file can be manually edited.

Documentation can be accessed by users via:

-   **The Help Query:** Type `?get_lmr_data` or `help("fetch_db_basic")` in the console.

-   **The Index:** Type `help(package = "lmrtools")` to see a list of every documented function in your library.

    -   provides access to the DESCRIPTION file

-   **Autocomplete:** In Positron, when you start typing your function name, a hover-box will appear showing the title and parameters you wrote in your Roxygen comments.

## Other Scenarios

### Posit Connect Cloud Shiny app deployment

To ensure library is included with Shiny app.

#### Console: (first time setup)

-   in Shiny app folder: `rsconnect::writeManifest(appDir="<app directory if not project root>")`
-   creates a **manifest.json** file in app directory, to be pushed to Github.
-   **lmrtools** will be included in references to ALL needed packages, including full meta data info.

#### After updates to package:

If version number (or maybe other major meta data, new packages) is changed, Posit Connect Cloud may have issues.

-   in Shiny app folder: `rsconnect::writeManifest("<app directory">)`.
-   OR: can open manifest.json > search 'lmrtools' and update manually.
-   Push to Github.

#### Credentials for Posit Connect Cloud deployment

-   Add each variable to **Configure variables** from **.Renviron** .
-   **AWS database**: add Posit Connect Cloud IP addresses
    -   see: [Posit Connect Cloud Documentation](https://docs.posit.co/connect-cloud/user/platform/system.html#firewalls)