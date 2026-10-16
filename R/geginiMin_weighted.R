# Faster respondent-level weighted randomization benchmark for GEGINI.
# Each draw selects exactly m respondents uniformly without replacement;
# their original weights and group membership remain attached.
# NO survey-design variance adjustment is performed.
# Base R only; preserves the earlier geginiMin_weighted() return structure.

geginiMin_weighted <- function(data, group, participation, weight = NULL,
                               nsim = 10000L, seed = NULL,
                               return_simulations = FALSE) {
  valid_column <- function(name) is.character(name) && length(name) == 1L &&
    !is.na(name) && name %in% names(data)
  if (!is.data.frame(data)) stop("'data' must be a data.frame.")
  if (!valid_column(group)) stop("'group' must name one column.")
  if (!valid_column(participation)) stop("'participation' must name one column.")
  if (!is.null(weight) && !valid_column(weight))
    stop("'weight' must be NULL or name one column.")
  valid_integer <- function(x, lower) is.numeric(x) && length(x) == 1L &&
    !is.na(x) && is.finite(x) && x == floor(x) && x >= lower &&
    x <= .Machine$integer.max
  if (!valid_integer(nsim, 2L)) stop("'nsim' must be an integer >= 2.")
  if (!is.logical(return_simulations) || length(return_simulations) != 1L ||
      is.na(return_simulations)) stop("'return_simulations' must be TRUE/FALSE.")
  g <- data[[group]]
  y <- data[[participation]]
  w <- if (is.null(weight)) rep.int(1, nrow(data)) else data[[weight]]
  if (anyNA(g) || anyNA(y) || anyNA(w))
    stop('Missing group, participation or weight values: filter explicitly before calling.')
  if ((!is.numeric(y) && !is.logical(y)) || !all(y %in% c(0, 1)))
    stop("'participation' must be numeric or logical 0/1.")
  if (!is.numeric(w) || any(!is.finite(w)) || any(w <= 0))
    stop("'weight' must contain strictly positive, finite numbers.")
  g <- factor(g)
  ng <- nlevels(g)
  if (ng < 2L) stop("At least two observed groups are required.")
  g_id <- as.integer(g)
  n <- length(y)
  m <- sum(y)
  if (m < 1L) stop("At least one participant is required.")
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1L || is.na(seed) || !is.finite(seed) || seed != floor(seed) || abs(seed) > .Machine$integer.max) stop("'seed' must be NULL or an integer within R's seed range.")
    had_seed <- exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get('.Random.seed', envir = .GlobalEnv)
    on.exit({
      if (had_seed) assign('.Random.seed', old_seed, envir = .GlobalEnv)
      else if (exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE))
        rm('.Random.seed', envir = .GlobalEnv)
    }, add = TRUE)
    set.seed(as.integer(seed))
  }
  group_total <- as.numeric(rowsum(w, g_id, reorder = TRUE))
  k <- group_total / sum(group_total)
  pair <- utils::combn(seq_len(ng), 2L)
  left <- pair[1L, ]
  right <- pair[2L, ]
  # Weighted group totals among actually observed participants.
  actual <- as.numeric(rowsum(w * as.numeric(y), g_id, reorder = TRUE))
  actual_g <- sum(abs(actual[left] * k[right] - actual[right] * k[left])) / sum(actual)
  simulations <- numeric(as.integer(nsim))
  if (m != n) {
    for (b in seq_len(as.integer(nsim))) {
      selected <- sample.int(n, size = m, replace = FALSE)
      # Integer group codes save repeated factor construction and reordering.
      # rowsum returns only groups present among selected respondents.
      z <- rowsum(w[selected], g_id[selected], reorder = FALSE)
      s <- numeric(ng)
      s[as.integer(rownames(z))] <- as.numeric(z[, 1L])
      simulations[b] <- sum(abs(s[left] * k[right] - s[right] * k[left])) / sum(s)
    }
  }
  result <- list(
    estimate = mean(simulations),
    mc_se = stats::sd(simulations) / sqrt(nsim),
    observed = as.numeric(actual_g),
    group_population_shares = setNames(k, levels(g)),
    n = n,
    participants = m,
    nsim = as.integer(nsim))
  if (return_simulations) result$simulations <- simulations
  class(result) <- 'geginiMinWeighted'
  result
}
