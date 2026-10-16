# Faster Monte Carlo E[GEGINI] under uniform selection of exactly rv individuals.
# Counts are sampled from the MULTIVARIATE hypergeometric distribution.
# The statistic is computed with the identity:
#   GEGINI = sum_{g<h} |p[g]*k[h] - p[h]*k[g]|.
# Only base R is required; this function does not need gegini().
# Returns the same API as the original geginiMin().
# NOTE: Same seed does not imply the same individual simulations as the old
# implementation (random numbers are consumed in a different order).

geginiMin <- function(strukt, rv, nsim = 10000L, seed = NULL,
                      return_simulations = FALSE, block_size = 10000L) {
  valid_integer <- function(x, lower) {
    is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x) &&
      x == floor(x) && x >= lower && x <= .Machine$integer.max
  }
  if (!is.numeric(strukt) || length(strukt) < 2L || anyNA(strukt) ||
      any(!is.finite(strukt)) || any(strukt <= 0) ||
      any(strukt != floor(strukt)) || sum(strukt) > .Machine$integer.max) {
    stop("'strukt' must have >= 2 positive integer group sizes (total <= integer max).")
  }
  if (!valid_integer(rv, 1L) || rv > sum(strukt)) {
    stop("'rv' must be a positive integer not exceeding the population.")
  }
  if (!valid_integer(nsim, 1L)) stop("'nsim' must be an integer >= 1.")
  if (!valid_integer(block_size, 1L)) stop("'block_size' must be an integer >= 1.")
  if (!is.logical(return_simulations) || length(return_simulations) != 1L ||
      is.na(return_simulations)) stop("'return_simulations' must be TRUE/FALSE.")
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1L || is.na(seed) || !is.finite(seed) || seed != floor(seed) || abs(seed) > .Machine$integer.max) stop("'seed' must be NULL or an integer within R's seed range.")
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
      if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
      else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
        rm(".Random.seed", envir = .GlobalEnv)
    }, add = TRUE)
    set.seed(as.integer(seed))
  }
  nsim <- as.integer(nsim)
  rv <- as.integer(rv)
  ng <- length(strukt)
  k <- strukt / sum(strukt)
  pair <- utils::combn(seq_len(ng), 2L)
  left <- pair[1L, ]
  right <- pair[2L, ]
  simulations <- numeric(nsim)
  if (rv != sum(strukt)) {
    for (first in seq.int(1L, nsim, by = as.integer(block_size))) {
      last <- min(nsim, first + as.integer(block_size) - 1L)
      nb <- last - first + 1L
      counts <- matrix(0, nrow = nb, ncol = ng)
      remaining_participants <- rep.int(rv, nb)
      remaining_population <- sum(strukt)
      for (g in seq_len(ng - 1L)) {
        counts[, g] <- stats::rhyper(nb, m = strukt[g],
          n = remaining_population - strukt[g], k = remaining_participants)
        remaining_participants <- remaining_participants - counts[, g]
        remaining_population <- remaining_population - strukt[g]
      }
      counts[, ng] <- remaining_participants
      scores <- numeric(nb)
      for (j in seq_along(left)) {
        scores <- scores + abs(counts[, left[j]] * k[right[j]] -
                               counts[, right[j]] * k[left[j]])
      }
      simulations[first:last] <- scores / rv
    }
  }
  ans <- mean(simulations)
  if (return_simulations) return(list(
    estimate = ans,
    mc_se = if (nsim >= 2L) stats::sd(simulations) / sqrt(nsim) else NA_real_,
    simulations = simulations))
  ans
}
