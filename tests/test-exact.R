# Independent exact small-sample checks of the weighted maximum.
library(pipi)

exact_max <- function(dat) {
  n <- nrow(dat)
  m <- sum(dat$y)
  k <- as.numeric(rowsum(dat$w, dat$g, reorder = TRUE))
  k <- k / sum(k)
  possible <- utils::combn(seq_len(n), m)
  max(apply(possible, 2L, function(ix) {
    counts <- as.numeric(rowsum(dat$w *
      as.numeric(seq_len(n) %in% ix), dat$g, reorder = TRUE))
    as.numeric(gegini(p = counts / sum(counts), k = k))
  }))
}
set.seed(404)
for (j in seq_len(12L)) {
  n <- sample(7:10, 1L)
  g <- sample(LETTERS[1:3], n, replace = TRUE)
  if (length(unique(g)) < 2L) next
  m <- sample(1:(n-1L), 1L)
  yy <- integer(n)
  yy[sample.int(n, m)] <- 1L
  dat <- data.frame(g = g, y = yy, w = stats::runif(n, 0.3, 4))
  expect <- exact_max(dat)
  got <- geginiMax_weighted_ordered(dat, "g", "y", "w")
  stopifnot(isTRUE(all.equal(expect, got$maximum, tolerance = 1e-9)),
            isTRUE(got$certified), got$optimality_gap_bound < 1e-8)
}

# Weighted randomization expectation versus exhaustive allocation.
small <- data.frame(g = c("A", "A", "B", "B", "B"),
                    y = c(1L, 0L, 1L, 0L, 0L), w = c(1, 2, 3, 4, 8))
k <- as.numeric(rowsum(small$w, small$g, reorder = TRUE))
k <- k / sum(k)
sets <- utils::combn(seq_len(nrow(small)), sum(small$y))
true_vals <- apply(sets, 2L, function(ix) {
  p <- as.numeric(rowsum(small$w * as.numeric(seq_len(nrow(small)) %in% ix),
                         small$g, reorder = TRUE))
  as.numeric(gegini(p = p / sum(p), k = k))
})
mc <- geginiMin_weighted(small, "g", "y", "w", nsim = 5000L, seed = 33)
stopifnot(abs(mc$estimate - mean(true_vals)) < 6 * mc$mc_se + 0.002)

# Two-group hypergeometric benchmark E[G]=1/7.
u <- geginiMin(c(5L, 5L), 5L, nsim = 5000L, seed = 33L,
               return_simulations = TRUE)
stopifnot(abs(u$estimate - 1/7) < 6 * u$mc_se + 0.002)
cat("All pipi exact-reference tests passed.\n")
