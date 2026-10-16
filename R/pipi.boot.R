# Simple iid nonparametric bootstrap for a pre-computed pipi() result.
# Bootstrap samples recalculate GEGINI observed, expected minimum, and maximum.
# Survey weights are kept attached to respondents. This is NOT a complex
# survey-design bootstrap (no explicit strata, PSU or replicate weights).
# Aggregated integer counts are resampled via empirical-cell multinomial draws.
# Requires base R only. Load 'pipi.R' and all core functions first.

pipi.boot <- function(object, nboot = 999L, nsim = 500L,
                      conf.level = 0.95, seed = NULL,
                      return_replicates = FALSE, profile = FALSE) {
  if (!inherits(object, "pipi") || is.null(object$input) ||
      is.null(object$input$data)) {
    stop("'object' must be an unmodified result from pipi().")
  }
  .integer_ok <- function(x, lower) {
    is.numeric(x) && length(x) == 1L && !is.na(x) &&
      is.finite(x) && x == floor(x) && x >= lower &&
      x <= .Machine$integer.max
  }
  if (!.integer_ok(nboot, 30L)) stop("'nboot' must be an integer >= 30.")
  if (!.integer_ok(nsim, 2L)) stop("'nsim' must be an integer >= 2.")
  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      !is.finite(conf.level) || conf.level <= 0 || conf.level >= 1) {
    stop("'conf.level' must lie strictly between 0 and 1.")
  }
  for (flag in list(return_replicates, profile)) {
    if (!is.logical(flag) || length(flag) != 1L || is.na(flag)) {
      stop("'return_replicates' and 'profile' must be TRUE or FALSE.")
    }
  }
  if (!is.null(seed) && (!.integer_ok(seed, 0L))) {
    stop("'seed' must be NULL or a nonnegative integer.")
  }
  if (!is.null(seed)) {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit({
      if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
      else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(as.integer(seed))
  }

  meta <- object$input
  data <- meta$data
  data_type <- meta$data_type
  n <- as.integer(object$n)
  B <- as.integer(nboot)
  vals <- rep(NA_real_, B)
  raw_vals <- rep(NA_real_, B)
  failure <- rep(NA_character_, B)
  time_parts <- if (profile) matrix(0, nrow = B, ncol = 5L,
    dimnames = list(NULL, c("observed", "maximum", "expected_min", "other", "total"))) else NULL
  t_boot_start <- proc.time()[["elapsed"]]

  if (data_type == "aggregate") {
    G <- nrow(data)
    n_part <- as.numeric(data[[meta$participants]])
    n_nonpart <- as.numeric(data[[meta$population]]) - n_part
    cell_prob <- c(n_part, n_nonpart) / sum(c(n_part, n_nonpart))
  }

  for (b in seq_len(B)) {
    if (data_type == "individual") {
      ix <- sample.int(n, size = n, replace = TRUE)
      d <- data[ix, , drop = FALSE]
      g_count <- length(unique(d[[meta$group]]))
      m <- sum(d[[meta$participation]])
    } else {
      counts <- as.numeric(stats::rmultinom(1L, size = n, prob = cell_prob)[, 1L])
      new_part <- counts[seq_len(G)]
      new_pop <- new_part + counts[G + seq_len(G)]
      keep <- new_pop > 0
      d <- data[keep, , drop = FALSE]
      d[[meta$population]] <- new_pop[keep]
      d[[meta$participants]] <- new_part[keep]
      g_count <- sum(keep)
      m <- sum(new_part)
    }
    if (g_count < 2L) {
      failure[b] <- "fewer_than_two_groups"
      next
    }
    if (m == 0L) {
      failure[b] <- "no_participants"
      next
    }
    if (m == n) {
      failure[b] <- "all_participate"
      next
    }

    bs <- .PiPi_point(data = d, group = meta$group,
      participation = meta$participation, weight = meta$weight,
      population = meta$population, participants = meta$participants,
      data_type = data_type, nsim = as.integer(nsim), seed = NULL,
      truncate = object$truncated, return_simulations = FALSE,
      tol = meta$tol, max_iter = meta$max_iter,
      max_permutations = meta$max_permutations,
      .profile_components = profile)
    if (!is.finite(bs$PiPi) || !is.finite(bs$PiPiRaw)) {
      failure[b] <- "undefined_index"
      next
    }
    vals[b] <- bs$PiPi
    raw_vals[b] <- bs$PiPiRaw
    if (profile) time_parts[b, ] <- bs$component_seconds
  }

  elapsed <- proc.time()[["elapsed"]] - t_boot_start
  ok <- is.finite(vals) & is.finite(raw_vals)
  n_valid <- sum(ok)
  n_failed <- B - n_valid
  pct <- function(z) {
    if (length(z) < 30L) return(c(lower = NA_real_, upper = NA_real_))
    setNames(as.numeric(stats::quantile(z, probs = c((1 - conf.level) / 2,
       (1 + conf.level) / 2), names = FALSE, type = 7)), c("lower", "upper"))
  }
  ci <- pct(vals[ok])
  raw_ci <- pct(raw_vals[ok])
  se <- if (n_valid >= 2L) stats::sd(vals[ok]) else NA_real_
  raw_se <- if (n_valid >= 2L) stats::sd(raw_vals[ok]) else NA_real_
  reason_tab <- sort(table(failure[!ok]), decreasing = TRUE)
  if (n_failed > 0L) {
    warning(sprintf("%d/%d bootstrap draws yielded undefined PIPI; see $failure_reasons.",
      n_failed, B), call. = FALSE)
  }
  if (n_valid < 30L) warning("Fewer than 30 valid bootstrap draws: CI not computed.", call. = FALSE)

  out <- list(
    point = object, method = if (data_type == "individual")
      "iid respondent bootstrap" else "empirical-cell multinomial bootstrap",
    nboot = B, nsim = as.integer(nsim), conf.level = conf.level,
    n_valid = n_valid, n_failed = n_failed,
    bootstrap_se = se, bootstrap_ci = ci,
    bootstrap_se_raw = raw_se, bootstrap_ci_raw = raw_ci,
    bootstrap_bias = if (n_valid) mean(vals[ok]) - object$PiPi else NA_real_,
    bootstrap_bias_raw = if (n_valid) mean(raw_vals[ok]) - object$PiPiRaw else NA_real_,
    raw_negative_fraction = if (n_valid) mean(raw_vals[ok] < 0) else NA_real_,
    failure_reasons = reason_tab,
    elapsed_seconds = unname(elapsed))
  if (return_replicates) {
    out$replicates <- vals
    out$replicates_raw <- raw_vals
  }
  if (profile) {
    by_part <- colSums(time_parts[ok, , drop = FALSE])
    out$timing <- list(component_seconds = by_part,
      measured_bootstrap_seconds = unname(elapsed),
      non_component_seconds = max(0, unname(elapsed) - unname(by_part[["total"]])),
      valid_replicates = n_valid,
      note = "Elapsed wall-clock timings are approximate; per-call timer resolution can affect very fast components.")
  }
  class(out) <- "pipi_boot"
  out
}

print.pipi_boot <- function(x, ...) {
  cat("PIPI nonparametric bootstrap\n")
  cat("  Point estimate: ", format(x$point$PiPi, digits = 7), "\n", sep = "")
  cat("  Bootstrap SE:   ", format(x$bootstrap_se, digits = 5), "\n", sep = "")
  cat("  ", 100 * x$conf.level, "% CI:       [",
      paste(format(x$bootstrap_ci, digits = 5), collapse = ", "), "]\n", sep = "")
  cat("  Raw PIPI CI:    [",
      paste(format(x$bootstrap_ci_raw, digits = 5), collapse = ", "), "]\n", sep = "")
  cat("  Valid samples:  ", x$n_valid, "/", x$nboot, "\n", sep = "")
  cat("  Time:           ", format(x$elapsed_seconds, digits = 5), " seconds\n", sep = "")
  if (!is.null(x$timing)) {
    cat("  Component time (sum across valid replicates):\n")
    for (name in c("observed", "maximum", "expected_min", "other")) {
      cat("    ", name, ": ", format(x$timing$component_seconds[[name]], digits = 5), " s\n", sep = "")
    }
  }
  invisible(x)
}

summary.pipi_boot <- function(object, ...) {
  print.pipi_boot(object)
  invisible(object)
}
