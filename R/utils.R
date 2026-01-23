# Various internal helper functions
# - not include in package for 'public' use

#' Establish connection to the LMR database
#' @return A DBI connection object to the LMR database (technically Fig4)
#' @keywords internal
get_con <- function() {
  DBI::dbConnect(
    RPostgres::Postgres(),
    dbname   = Sys.getenv("FIG4_DB_NAME"),
    host     = Sys.getenv("FIG4_DB_HOST_ENDPT"),
    user     = Sys.getenv("FIG4_DB_USER"),
    password = Sys.getenv("FIG4_DB_PWD"),
    port     = as.numeric(Sys.getenv("FIG4_DB_PORT"))
  )
}

#' Recommended by ChatGPT for easier test structure
#' @keywords internal
db_get_query <- function(con, query, params) {
  DBI::dbGetQuery(con, query, params = params)
}
#' Disconnect from the LMR database
#' recommended by ChatGPT to put here for easier testing 
#' @keywords internal
db_disconnect <- function(con) {
  DBI::dbDisconnect(con)
}

#' Internal helper for database_functions.R SQL queries
#' from ChatGPT
#' @keywords internal
na_if_missing <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA)
  x[[1]]
}
