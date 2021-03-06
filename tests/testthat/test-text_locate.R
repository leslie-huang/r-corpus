context("text_locate")


test_that("'text_count' can count instances", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")

    expect_equal(text_count(text, "is"), c(3, 0, 0))
    expect_equal(text_count(text, "a"), c(3, 1, 0))
    expect_equal(text_count(text, "rose"), c(4, 1, 1))
    expect_equal(text_count(text, c("is", "a", "rose")), c(10, 2, 1))
})


test_that("'text_count' can use a custom filter", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")
    f <- text_filter(map_case = FALSE)

    expect_equal(text_count(text, "rose", f), c(3, 1, 0))
})


test_that("'text_detect' can find instances", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")

    expect_equal(text_detect(text, "is"), c(TRUE, FALSE, FALSE))
    expect_equal(text_detect(text, "rose"), c(TRUE, TRUE, TRUE))
    expect_equal(text_detect(text, "a"), c(TRUE, TRUE, FALSE))
    expect_equal(text_detect(text, c("is", "a", "rose")), c(TRUE, TRUE, TRUE))
})


test_that("'text_detect' can use a custom filter", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")
    f <- text_filter(map_case = FALSE)

    expect_equal(text_detect(text, "rose", f), c(TRUE, TRUE, FALSE))
})


test_that("'text_match' can return matching term as a factor", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")

    actual <- text_match(text, c(".", "rose"))

    expected <- data.frame(
        text = structure(c(1, 1, 1, 1, 1, 2, 2, 3), levels = as.character(1:3),
                         class = "factor"),
        term = structure(c(2, 2, 2, 2, 1, 2, 1, 2), levels = c(".", "rose"),
                         class = "factor"),
        row.names = NULL,
        stringsAsFactors = FALSE)
    class(expected) <- c("corpus_frame", "data.frame")

    expect_equal(actual, expected)
})


test_that("'text_match' works with NULL terms", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")

    actual <- text_match(text, NULL)
    expected <- data.frame(text = structure(integer(), levels = labels(text),
                                            class = "factor"),
                           term = structure(integer(), levels = character(),
                                            class = "factor"))
    class(expected) <- c("corpus_frame", "data.frame")
    expect_equal(actual, expected)
})


test_that("'text_match' errors for invalid arguments", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")

    expect_error(text_match(text, 1),
                 "'terms' must be a character vector or NULL")

    expect_error(text_match(text, c("rose", NA)),
                 "'terms' argument cannot contain missing values")

    invalid <- "fa\xE7ile"; Encoding(invalid) <- "UTF-8"
    expect_error(text_match(text, invalid),
                 "'terms' argument cannot contain invalid UTF-8")

    expect_error(text_match(text, c("rose", "  rose  ")),
                 "'terms' argument cannot contain duplicate types")
})


test_that("'text_locate' can give instance contexts", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")

    actual <- text_locate(text, "rose")

    expected <- data.frame(
        text = structure(c(1, 1, 1, 1, 2, 3), levels = as.character(1:3),
                         class = "factor"),
        before = as_corpus_text(c("", "Rose is a ", "Rose is a rose is a ",
                   "Rose is a rose is a rose is a ", "A ",
                   "Snow White and ")),
        instance = as_corpus_text(c("Rose", "rose", "rose", "rose", "rose", "Rose")),
        after = as_corpus_text(c(" is a rose is a rose is a rose.",
                          " is a rose is a rose.", " is a rose.", ".",
                          " by any other name would smell as sweet.",
                          " Red")),
        row.names = NULL,
        stringsAsFactors = FALSE)
    class(expected) <- c("corpus_text_locate", "corpus_frame", "data.frame")

    expect_equal(actual, expected)
})


test_that("'text_locate' can use a custom filter", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")
    f <- text_filter(map_case = FALSE)
    actual <- text_locate(text, "Rose", f)

    expected <- data.frame(
        text = structure(c(1, 3), levels = as.character(1:3),
                         class = "factor"),
        before = as_corpus_text(c("", "Snow White and "), filter = f),
        instance = as_corpus_text(c("Rose", "Rose"), filter = f),
        after = as_corpus_text(c(" is a rose is a rose is a rose.", " Red"),
                        filter = f),
        row.names = NULL,
        stringsAsFactors = FALSE)
    class(expected) <- c("corpus_text_locate", "corpus_frame", "data.frame")

    expect_equal(actual, expected)
})


test_that("'text_locate' prints results correctly", {
    skip_on_os("windows")
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")
    f <- text_filter(map_case = FALSE)
    loc <- text_locate(text, "Rose", f)

    ctype <- switch_ctype("C")
    on.exit(Sys.setlocale("LC_CTYPE", ctype))

    lines <- strsplit(capture_output(print(loc), width = 76), "\n")[[1]]

    expect_equal(lines, c(
"  text            before             instance             after             ",
"1 1                                    Rose    is a rose is a rose is a r...",
"2 3                  Snow White and    Rose    Red                          "))
})


test_that("'text_sample' can give a random sample", {
    text <- c("Rose is a rose is a rose is a rose.",
              "A rose by any other name would smell as sweet.",
              "Snow White and Rose Red")

    loc <- text_sample(text, "rose", 3)
    expect_equal(nrow(loc), 3)

    loc <- text_sample(text, "rose")
    expect_equal(nrow(loc), nrow(text_locate(text, "rose")))
})
