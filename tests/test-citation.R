library(pipi)
ref <- citation("pipi")
stopifnot(inherits(ref, "citation"), length(ref) >= 1L)
entries <- vapply(ref, function(x) if (is.null(x$doi)) "" else x$doi, character(1))
stopifnot("10.1177/10434631221143614" %in% entries)
formatted <- paste(format(ref), collapse = " ")
stopifnot(grepl("Susánszky", formatted, fixed = TRUE),
          grepl("Somogyi", formatted, fixed = TRUE),
          grepl("Tóth", formatted, fixed = TRUE))
