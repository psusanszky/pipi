# Point estimator for the Political Inequality in Participation Index.
# Load PiPi_core.R and all core GEGINI functions before this file.
# Requires base R only.
#
# The result stores only the input columns needed for a later pipi.boot() call.
# 'nsim' controls only the point-estimate randomization benchmark.

pipi <- function(data, group, participation = NULL, weight = NULL,
                 population = NULL, participants = NULL,
                 data_type = c("individual", "aggregate"),
                 nsim = 1000L, seed = NULL, truncate = TRUE,
                 return_simulations = FALSE, tol = 1e-11,
                 max_iter = 100L, max_permutations = 5040L) {
  data_type <- match.arg(data_type)
  if (!exists(".PiPi_point", mode = "function")) {
    stop("Load 'PiPi_core.R' and its GEGINI dependencies first.")
  }
  point <- .PiPi_point(data = data, group = group,
    participation = participation, weight = weight,
    population = population, participants = participants,
    data_type = data_type, nsim = nsim, seed = seed, truncate = truncate,
    return_simulations = return_simulations, tol = tol,
    max_iter = max_iter, max_permutations = max_permutations)

  keep <- if (data_type == "individual") c(group, participation, weight)
          else c(group, population, participants)
  # Do not retain unrelated (potentially sensitive) survey columns.
  input_data <- data[, unique(keep), drop = FALSE]
  point$input <- list(
    data = input_data, group = group, participation = participation,
    weight = weight, population = population, participants = participants,
    data_type = data_type, tol = tol, max_iter = max_iter,
    max_permutations = max_permutations)
  point$seed <- seed
  class(point) <- c("pipi", "PiPi")
  point
}

print.pipi <- function(x, ...) {
  cat("PIPI point estimate (", x$data_type,
      if (isTRUE(x$weighted_algorithm)) ", weighted" else ", unweighted/equal weights",
      ")\n", sep = "")
  cat("  PIPI:                 ", format(x$PiPi, digits = 7), "\n", sep = "")
  cat("  Raw PIPI:             ", format(x$PiPiRaw, digits = 7), "\n", sep = "")
  cat("  Observed GEGINI:      ", format(x$geginiObserved, digits = 7), "\n", sep = "")
  cat("  Expected minimum:     ", format(x$geginiExpectedMin, digits = 7), "\n", sep = "")
  cat("  Maximum GEGINI:       ", format(x$geginiMaximum, digits = 7), "\n", sep = "")
  cat("  MC SE (expected min): ", format(x$mc_se, digits = 4), "\n", sep = "")
  if (!is.finite(x$PiPi)) cat("  Note: PIPI is undefined for this sample.\n")
  invisible(x)
}

summary.pipi <- function(object, ...) {
  print.pipi(object)
  invisible(object)
}
