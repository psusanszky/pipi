# Globally optimized individual-level weighted GEGINI maximum (base R only).
#
# This computes max_y GEGINI(y), keeping survey weights and group membership
# fixed and constraining sum(y) to the OBSERVED UNWEIGHTED participant count.
#
# For each permutation of the G groups, the signed GEGINI numerator is linear
# in group weighted participant totals. The resulting ratio of two linear
# functions is maximized with a Dinkelbach iteration: for a given lambda,
# select the m respondents with the largest w_i * (a_group(i) - lambda).
# Exhausting all G! group permutations gives the GLOBAL optimum to tolerance.
#
# The returned optimality_gap_bound is a mathematical upper bound on the
# maximum minus the reported value, apart from floating-point roundoff.
# No external R packages or previously defined GEGINI functions are required.

geginiMax_weighted_ordered <- function(data, group, participation, weight = NULL,
                                       tol = 1e-11, max_iter = 100L,
                                       max_permutations = 5040L) {
  if (!is.data.frame(data)) stop('data must be a data.frame.')
  for (nm in c(group, participation, weight)) {
    if (!is.character(nm) || length(nm) != 1L || is.na(nm) ||
        !nm %in% names(data)) stop('Invalid column name: group, participation, or weight.')
  }
  for (v in list(max_iter, max_permutations)) {
    if (!is.numeric(v) || length(v) != 1L || !is.finite(v) ||
        v < 1 || v != floor(v)) stop('max_iter and max_permutations must be positive integers.')
  }
  if (!is.numeric(tol) || length(tol) != 1L || !is.finite(tol) || tol <= 0) {
    stop('tol must be a finite positive number.')
  }

  g <- data[[group]]
  y <- data[[participation]]
  w_original <- if (is.null(weight)) rep(1, nrow(data)) else data[[weight]]
  if (anyNA(g) || anyNA(y) || anyNA(w_original)) stop('Remove missing values explicitly.')
  if ((!is.numeric(y) && !is.logical(y)) || !all(y %in% c(0, 1))) {
    stop('Participation must be numeric/logical binary 0/1.')
  }
  if (!is.numeric(w_original) || any(!is.finite(w_original)) ||
      any(w_original <= 0)) stop('Weights must be finite and strictly positive.')

  g <- factor(g)
  G <- nlevels(g)
  n <- length(y)
  m <- as.integer(sum(y))
  if (G < 2L) stop('At least two observed groups are required.')
  if (m < 1L) stop('At least one observed participant is required.')

  n_perm <- factorial(G)
  if (!is.finite(n_perm) || n_perm > max_permutations) {
    stop(sprintf('There are %s group permutations; max_permutations=%s. Increase the limit only if runtime is acceptable.',
                 format(n_perm, scientific = FALSE), max_permutations))
  }
  id <- as.integer(g)
  # Rescale to avoid overflow for very large weights; changes no ratio or optimum.
  w <- w_original / max(w_original)
  if (any(w <= 0)) stop('Weight range is too extreme for double-precision computation.')
  group_weight <- as.numeric(rowsum(w, g, reorder = TRUE))
  k <- group_weight / sum(group_weight)
  names(k) <- levels(g)

  # Independent formula used to verify the final selected assignment.
  pair_gini <- function(selected) {
    s <- numeric(G)
    sums <- rowsum(w[selected], factor(id[selected], levels = seq_len(G)), reorder = TRUE)
    s[as.integer(rownames(sums))] <- as.numeric(sums[, 1L])
    p <- s / sum(s)
    pairs <- utils::combn(G, 2L)
    sum(abs(p[pairs[1L, ]] * k[pairs[2L, ]] -
            p[pairs[2L, ]] * k[pairs[1L, ]]))
  }
  if (m == n) {
    return(structure(list(maximum = 0, selected_rows = seq_len(n),
      certified = TRUE, optimality_gap_bound = 0, upper_bound = 0,
      method = 'all respondents participate', n = n, participants = m,
      groups = G, group_population_shares = k,
      group_participant_shares_at_max = k,
      permutations_checked = 0L, iterations_total = 0L, tol = tol),
      class = 'geginiMaxWeightedOrdered'))
  }

  # For every assignment of m individuals, sum(w[selected]) >= min_den.
  # This gives a rigorous ratio upper bound from the Dinkelbach residual.
  min_den <- sum(sort(w)[seq_len(m)])
  if (!is.finite(min_den) || min_den <= 0) stop('Cannot bound weighted denominator numerically.')

  best_rows <- which(y == 1)
  best_value <- pair_gini(best_rows)  # Feasible GLOBAL lower bound.
  max_upper <- best_value
  iterations_total <- 0L
  checked <- 0L

  evaluate_order <- function(perm) {
    # If p_perm[1]/k_perm[1] <= ... <= p_perm[G]/k_perm[G], then
    # GEGINI = sum_j a_perm[j] * p_perm[j], with:
    # a_perm[j] = sum_{h<j} k_perm[h] - sum_{h>j} k_perm[h].
    kp <- k[perm]
    before <- c(0, cumsum(kp)[seq_len(G - 1L)])
    a <- numeric(G)
    a[perm] <- 2 * before + kp - 1
    aw <- a[id] * w

    # best_value is a feasible lower bound for the max over all permutations.
    lambda <- best_value
    finished <- FALSE
    for (iter in seq_len(as.integer(max_iter))) {
      score <- aw - lambda * w
      selected <- order(score, decreasing = TRUE)[seq_len(m)]
      residual <- sum(score[selected])  # max_y (numerator - lambda*denominator)
      bound <- lambda + max(0, residual) / min_den
      if (residual <= tol * min_den) {
        max_upper <<- max(max_upper, bound)
        finished <- TRUE
        iterations_total <<- iterations_total + iter
        break
      }
      denom <- sum(w[selected])
      value <- sum(aw[selected]) / denom
      if (!is.finite(value) || value <= lambda) {
        stop('Numerical stagnation in linear-fractional optimization; increase tol or check weights.')
      }
      if (value > best_value) {
        best_value <<- value
        best_rows <<- selected
      }
      lambda <- value
    }
    if (!finished) stop('Dinkelbach iteration limit exceeded. Increase max_iter; no certification was produced.')
    checked <<- checked + 1L
    invisible(NULL)
  }

  enumerate_orders <- function(prefix, remaining) {
    if (!length(remaining)) {
      evaluate_order(prefix)
    } else {
      for (j in seq_along(remaining)) {
        enumerate_orders(c(prefix, remaining[j]), remaining[-j])
      }
    }
    invisible(NULL)
  }
  enumerate_orders(integer(0), seq_len(G))

  # Recalculate independently using the unsigned pairwise GEGINI identity.
  verified_value <- pair_gini(best_rows)
  if (!is.finite(verified_value) ||
      abs(verified_value - best_value) > max(1e-9, 10 * tol)) {
    stop('Internal verification failed: selected assignment does not reproduce the maximum.')
  }
  best_value <- verified_value
  max_upper <- max(max_upper, best_value)
  selected_weight <- numeric(G)
  sums <- rowsum(w[best_rows], factor(id[best_rows], levels = seq_len(G)), reorder = TRUE)
  selected_weight[as.integer(rownames(sums))] <- as.numeric(sums[, 1L])
  p <- selected_weight / sum(selected_weight)
  names(p) <- levels(g)
  structure(list(maximum = as.numeric(best_value),
    selected_rows = as.integer(best_rows), certified = TRUE,
    optimality_gap_bound = max(0, as.numeric(max_upper - best_value)),
    upper_bound = as.numeric(max_upper),
    method = 'all group orders + linear-fractional optimization (base R)',
    n = n, participants = m, groups = G,
    group_population_shares = k,
    group_participant_shares_at_max = p,
    permutations_checked = checked, iterations_total = iterations_total,
    tol = tol), class = 'geginiMaxWeightedOrdered')
}
