# failed attempt at setting up unit testing, misled by ChatGPT

test_that("fetch_lmr_complete_filter replace=FALSE returns converted data", {
  testthat::skip("DB tests not enabled yet")

  # Fake DB result set (what dbGetQuery would return)
  fake_db <- data.frame(
    fy_qtr = "2025Q1",
    cat_type = "Beer",
    category = "BC Beer",
    subcategory = "BC Commercial Beer",
    netsales = 99967797,
    litres = 199967797,
    fyr = 2025,
    qtr = "Q4",
    cyr = 2025,
    cqtr = "Q1",
    end_qtr = "03-31",
    end_qtr_dt = as.Date("2025-03-31"),
    season = "winter",
    cat_type_short = "Beer",
    category_short = "BC",
    subcategory_short = "BC Major",
    end_qtr_dt = as.Date("2025-03-31"),
    cyr_qtr = "25-Q1",
    cyr_num = 2025,
    stringsAsFactors = FALSE
  )

  testthat::local_mocked_bindings(
    get_con = function() structure(list(), class = "fake_con"),

    db_get_query = function(con, query, params) {
      captured$params <- params
      fake_db
    },

    db_disconnect = function(con) TRUE,

    conversions = function(x) x,  # no-op for unit test

    .package = "lmrtools"
  )

  out1 <- fetch_lmr_complete_filter(replace = FALSE, cat_type = "Beer")

  p <- captured$params
  testthat::expect_length(p, 5)

  testthat::expect_type(p[[1]], "character")
  testthat::expect_length(p[[1]], 1)
  testthat::expect_equal(p[[1]], "Beer")

  testthat::expect_type(p[[2]], "character")
  testthat::expect_length(p[[2]], 1)
  testthat::expect_true(is.na(p[[2]]))

  testthat::expect_type(p[[3]], "character")
  testthat::expect_length(p[[3]], 1)
  testthat::expect_true(is.na(p[[3]]))

  testthat::expect_s3_class(p[[4]], "Date")
  testthat::expect_length(p[[4]], 1)
  testthat::expect_true(is.na(p[[4]]))

  testthat::expect_s3_class(p[[5]], "Date")
  testthat::expect_length(p[[5]], 1)
  testthat::expect_true(is.na(p[[5]]))

  testthat::expect_true(all(c("cat_type_short","category_short","subcategory_short") %in% names(out1)))

  out2 <- fetch_lmr_complete_filter(
    replace = TRUE,
    cat_type = "Beer",
    min_end_qtr_dt = "2025-01-01",
    max_end_qtr_dt = "2025-12-31"
  )

  testthat::expect_equal(out2$cat_type[1], "B")
  testthat::expect_equal(out2$category[1], "BC")
  testthat::expect_equal(out2$subcategory[1], "BC Major")
  testthat::expect_false(any(grepl("_short$", names(out2))))
})


