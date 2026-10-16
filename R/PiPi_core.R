# Unified PIPI estimator for individual-level or aggregated count data.
#
# Required existing functions (load/source first):
#   gegini()                     in gegini3.R
#   geginiMin()                  in geginiMin.R
#   geginiMax()                  in geginiMax3.R
#   geginiMin_weighted()         in geginiMin_weighted.R, for nonconstant weights
#   geginiMax_weighted_ordered() in geginiMax_weighted_ordered.R, for nonconstant weights
#
# geginiExpectedMin is the EXPECTED GEGINI under random allocation of exactly
# the observed UNWEIGHTED number of participants (without replacement).
# It is NOT necessarily the mathematically smallest feasible GEGINI.
#
# All weights are positive respondent-level weights; fixed on respondents.
# This is a finite-sample randomization benchmark, not an estimator that
# incorporates complex survey design (strata, clustering, sampling variance).

.PiPi_point <- function(data, group, participation = NULL, weight = NULL,
                 population = NULL, participants = NULL,
                 data_type = c("individual", "aggregate"),
                 nsim = 10000L, seed = NULL, truncate = TRUE,
                 return_simulations = FALSE,
                 tol = 1e-11, max_iter = 100L,
                 max_permutations = 5040L, .profile_components = FALSE) {
  .start_total <- if (.profile_components) proc.time()[["elapsed"]] else NULL
  data_type <- match.arg(data_type)
  if (!is.data.frame(data)) stop("'data' must be a data.frame.")
  valid_column <- function(name) {
    is.character(name) && length(name) == 1L && !is.na(name) &&
      nzchar(name) && name %in% names(data)
  }
  if (!valid_column(group)) stop("'group' must name a column in 'data'.")
  if (!is.numeric(nsim) || length(nsim) != 1L || is.na(nsim) ||
      !is.finite(nsim) || nsim != floor(nsim) || nsim < 2L ||
      nsim > .Machine$integer.max) {
    stop("'nsim' must be an integer >= 2.")
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L ||
      is.na(seed) || !is.finite(seed) || seed != floor(seed))) {
    stop("'seed' must be NULL or a finite integer.")
  }
  for (flag in list(truncate, return_simulations)) {
    if (!is.logical(flag) || length(flag) != 1L || is.na(flag)) {
      stop("'truncate' and 'return_simulations' must each be TRUE or FALSE.")
    }
  }
  if (anyNA(data[[group]])) stop("Missing group values: filter explicitly before calling PiPi().")

  simulation <- NULL
  maximum_details <- NULL
  use_weighted_method <- FALSE
  weight_supplied <- !is.null(weight)

  if (data_type == "individual") {
    if (!valid_column(participation)) stop("'participation' must name a column for individual data.")
    if (!is.null(population) || !is.null(participants)) {
      stop("'population' and 'participants' are for aggregate data only.")
    }
    if (weight_supplied && !valid_column(weight)) {
      stop("'weight' must be NULL or name a column in 'data'.")
    }
    g <- factor(data[[group]])
    y <- data[[participation]]
    if ((!is.numeric(y) && !is.logical(y)) || anyNA(y) ||
        !all(y %in% c(0, 1))) {
      stop("Individual-level 'participation' must contain only nonmissing 0/1 values.")
    }
    w <- if (weight_supplied) data[[weight]] else rep(1, nrow(data))
    if (!is.numeric(w) || anyNA(w) || any(!is.finite(w)) || any(w <= 0)) {
      stop("Individual weights must be numeric, finite and strictly positive.")
    }
    if (!is.finite(sum(w))) stop("Total survey weight is not finite.")
    group_sizes <- as.numeric(table(g))
    participant_counts <- as.numeric(rowsum(as.numeric(y), g, reorder = TRUE))
    n <- nrow(data)
    m <- sum(y)
    # Equal weights are mathematically equivalent to unweighted counts, even
    # if the user supplied a constant survey-weight column.
    use_weighted_method <- weight_supplied && !all(w == w[1L])
    if (weight_supplied) {
      group_totals <- as.numeric(rowsum(w, g, reorder = TRUE))
      participant_totals <- as.numeric(rowsum(w * y, g, reorder = TRUE))
      if (!is.finite(sum(participant_totals)) || sum(participant_totals) <= 0) {
        stop("Total participant weight is not finite and positive.")
      }
    } else {
      group_totals <- group_sizes
      participant_totals <- participant_counts
    }
  } else {
    if (!is.null(weight)) {
      stop("'weight' is not supported for aggregate data. Supply unweighted integer counts.")
    }
    if (!is.null(participation)) {
      stop("Use 'participants', not 'participation', for aggregate data.")
    }
    if (!valid_column(population) || !valid_column(participants)) {
      stop("For aggregate data, 'population' and 'participants' must name columns.")
    }
    if (anyDuplicated(as.character(data[[group]]))) {
      stop("Aggregate data must contain exactly one row per group.")
    }
    group_sizes <- data[[population]]
    participant_counts <- data[[participants]]
    if (!is.numeric(group_sizes) || anyNA(group_sizes) ||
        any(!is.finite(group_sizes)) || any(group_sizes <= 0) ||
        any(group_sizes != floor(group_sizes))) {
      stop("Aggregate 'population' must contain positive integer group sizes.")
    }
    if (!is.numeric(participant_counts) || anyNA(participant_counts) ||
        any(!is.finite(participant_counts)) || any(participant_counts < 0) ||
        any(participant_counts != floor(participant_counts)) ||
        any(participant_counts > group_sizes)) {
      stop("Aggregate 'participants' must contain integer counts between 0 and group size.")
    }
    group_sizes <- as.numeric(group_sizes)
    participant_counts <- as.numeric(participant_counts)
    group_totals <- group_sizes
    participant_totals <- participant_counts
    n <- sum(group_sizes)
    m <- sum(participant_counts)
    g <- as.character(data[[group]])
  }

  if (length(group_sizes) < 2L || any(group_sizes == 0L)) {
    stop("At least two nonempty social groups are required.")
  }
  if (!is.finite(n) || !is.finite(m) || m < 1 || m > n) {
    stop("The observed number of participants must be between 1 and the total sample size.")
  }
  if (n > .Machine$integer.max) {
    stop("Total population size exceeds the supported finite-sample simulation range.")
  }

  k <- group_totals / sum(group_totals)
  p <- participant_totals / sum(participant_totals)
  .t_observed_start <- if (.profile_components) proc.time()[["elapsed"]] else NULL
  observed <- as.numeric(gegini(p = p, k = k))
  .t_observed_end <- if (.profile_components) proc.time()[["elapsed"]] else NULL

  .t_max_start <- if (.profile_components) proc.time()[["elapsed"]] else NULL
  if (use_weighted_method) {
    if (!exists("geginiMax_weighted_ordered", mode = "function")) {
      stop("Source 'geginiMax_weighted_ordered.R' before calculating weighted PIPI.")
    }
    if (!exists("geginiMin_weighted", mode = "function")) {
      stop("Source 'geginiMin_weighted.R' before calculating weighted PIPI.")
    }
    maximum_details <- geginiMax_weighted_ordered(
      data = data, group = group, participation = participation, weight = weight,
      tol = tol, max_iter = max_iter, max_permutations = max_permutations)
    maximum <- as.numeric(maximum_details$maximum)
    optimality_gap <- as.numeric(maximum_details$optimality_gap_bound)
    maximum_certified <- isTRUE(maximum_details$certified)
    maximum_method <- maximum_details$method
  } else {
    if (!exists("geginiMax", mode = "function")) {
      stop("Source 'geginiMax3.R' before calculating unweighted PIPI.")
    }
    maximum <- as.numeric(geginiMax(strukt = group_sizes, rv = m))
    optimality_gap <- NA_real_
    maximum_certified <- TRUE
    maximum_method <- "Unweighted group-count maximum"
  }

  .t_max_end <- if (.profile_components) proc.time()[["elapsed"]] else NULL
  .t_min_start <- if (.profile_components) proc.time()[["elapsed"]] else NULL
  if (m == n) {
    # All allocations are identical; no random simulation is necessary.
    expected_min <- 0
    mc_se <- 0
    if (return_simulations) simulation <- rep(0, as.integer(nsim))
  } else if (use_weighted_method) {
    minimum_result <- geginiMin_weighted(
      data = data, group = group, participation = participation, weight = weight,
      nsim = nsim, seed = seed, return_simulations = return_simulations)
    expected_min <- as.numeric(minimum_result$estimate)
    mc_se <- as.numeric(minimum_result$mc_se)
    if (return_simulations) simulation <- minimum_result$simulations
  } else {
    if (!exists("geginiMin", mode = "function")) {
      stop("Source 'geginiMin.R' before calculating unweighted PIPI.")
    }
    # Request full simulations internally to provide mc_se for every mode.
    minimum_result <- geginiMin(
      strukt = group_sizes, rv = m, nsim = nsim, seed = seed,
      return_simulations = TRUE)
    expected_min <- as.numeric(minimum_result$estimate)
    mc_se <- as.numeric(minimum_result$mc_se)
    if (return_simulations) simulation <- minimum_result$simulations
  }

  .t_min_end <- if (.profile_components) proc.time()[["elapsed"]] else NULL
  denominator <- maximum - expected_min
  is_degenerate <- !is.finite(denominator) || denominator <= 1e-12
  raw <- if (is_degenerate) NA_real_ else (observed - expected_min) / denominator
  value <- if (isTRUE(truncate) && !is.na(raw)) max(0, raw) else raw

  group_labels <- if (data_type == "individual") levels(g) else g
  group_summary <- data.frame(
    group = group_labels,
    population = as.numeric(group_sizes),
    participants = as.numeric(participant_counts),
    weighted_population = as.numeric(group_totals),
    weighted_participants = as.numeric(participant_totals),
    k = as.numeric(k),
    p = as.numeric(p),
    stringsAsFactors = FALSE)

  out <- list(
    PiPi = as.numeric(value), PiPiRaw = as.numeric(raw),
    geginiObserved = as.numeric(observed),
    geginiExpectedMin = as.numeric(expected_min),
    geginiMaximum = as.numeric(maximum),
    mc_se = as.numeric(mc_se),
    optimality_gap = optimality_gap,
    maximum_certified = maximum_certified,
    maximum_method = maximum_method,
    data_type = data_type,
    weight_supplied = weight_supplied,
    weighted_algorithm = use_weighted_method,
    n = n, participants = m, groups = length(group_sizes),
    nsim = as.integer(nsim), truncated = truncate,
    denominator = as.numeric(denominator),
    group_summary = group_summary,
    # Backward-compatible names used in earlier PIPI scripts:
    geginiRaw = as.numeric(observed),
    StrMin = as.numeric(expected_min),
    StrMax = as.numeric(maximum))
  if (return_simulations) out$min_simulations <- as.numeric(simulation)
  if (.profile_components) {
    .elapsed_total <- proc.time()[["elapsed"]] - .start_total
    .component <- c(
      observed = .t_observed_end - .t_observed_start,
      maximum = .t_max_end - .t_max_start,
      expected_min = .t_min_end - .t_min_start)
    out$component_seconds <- c(.component,
      other = max(0, .elapsed_total - sum(.component)), total = .elapsed_total)
  }
  class(out) <- "PiPi"
  out
}

