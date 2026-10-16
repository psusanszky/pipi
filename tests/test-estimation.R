# Base-R package integration tests (executed by R CMD check).
library(pipi)
near <- function(a, b, tolerance = 1e-9) {
  stopifnot(isTRUE(all.equal(as.numeric(a), as.numeric(b), tolerance = tolerance)))
}

sizes <- c(20L, 40L, 140L)
parts <- c(15L, 22L, 43L)
d <- data.frame(
  g = rep(c("A", "B", "C"), sizes),
  y = unlist(Map(function(n, m) c(rep(1L, m), rep(0L, n - m)),
                 sizes, parts), use.names = FALSE))
a <- data.frame(g = c("A", "B", "C"), population = sizes,
                participants = parts)

p <- pipi(d, "g", "y", nsim = 1000L, seed = 81L)
pagg <- pipi(a, "g", data_type = "aggregate", population = "population",
             participants = "participants", nsim = 1000L, seed = 81L)
near(p$PiPi, pagg$PiPi)
near(p$geginiExpectedMin, pagg$geginiExpectedMin)
near(p$geginiMaximum, pagg$geginiMaximum)
stopifnot(inherits(p, "pipi"), identical(names(p$input$data), c("g", "y")))

# Group size affects achievable maximum at 40% participation.
near(geginiMax(c(10, 20, 70), 40), 0.45)
near(geginiMax(c(33, 33, 34), 40), 0.5595)

# GEGINI pairwise formula, with unequal group shares.
k <- c(0.1, 0.2, 0.7)
pp <- c(0.2, 0.3, 0.5)
near(gegini(p = pp, k = k),
     sum(abs(outer(pp, k) - outer(k, pp))[upper.tri(matrix(0, 3, 3))]))

# Constant respondent weights reduce exactly to the unweighted algorithm.
d$w <- rep(7, nrow(d))
pconst <- pipi(d, "g", "y", weight = "w", nsim = 1000L, seed = 81L)
near(p$PiPiRaw, pconst$PiPiRaw)
stopifnot(!pconst$weighted_algorithm)

# Unequal weights: scaling should not affect the index or conditional draws.
set.seed(88)
d$w <- stats::rlnorm(nrow(d), 0, 0.6)
pw1 <- pipi(d, "g", "y", "w", nsim = 300L, seed = 53L)
d$w <- d$w * 9
pw2 <- pipi(d, "g", "y", "w", nsim = 300L, seed = 53L)
near(pw1$PiPiRaw, pw2$PiPiRaw, tolerance = 1e-8)
stopifnot(pw1$maximum_certified,
          is.finite(pw1$optimality_gap), pw1$optimality_gap < 1e-8)

# Bootstrap must reuse point estimate but recompute components in each draw.
set.seed(42)
before <- get(".Random.seed", envir = .GlobalEnv)
b1 <- pipi.boot(p, nboot = 40L, nsim = 100L, seed = 67L,
                return_replicates = TRUE, profile = TRUE)
stopifnot(identical(before, get(".Random.seed", envir = .GlobalEnv)))
b2 <- pipi.boot(p, nboot = 40L, nsim = 100L, seed = 67L,
                return_replicates = TRUE)
near(b1$replicates_raw, b2$replicates_raw)
near(b1$bootstrap_ci_raw, b2$bootstrap_ci_raw)
near(b1$replicates, pmax(0, b1$replicates_raw))
stopifnot(inherits(b1, "pipi_boot"), b1$n_valid >= 30,
          is.finite(b1$bootstrap_se_raw),
          identical(b1$point$PiPi, p$PiPi),
          all(c("observed", "maximum", "expected_min", "other", "total") %in%
              names(b1$timing$component_seconds)))

bconst <- pipi.boot(pconst, nboot = 40L, nsim = 100L, seed = 67L,
                    return_replicates = TRUE)
near(b1$replicates_raw, bconst$replicates_raw)

bagg <- pipi.boot(pagg, nboot = 40L, nsim = 100L, seed = 67L)
stopifnot(bagg$n_valid >= 30, all(is.finite(bagg$bootstrap_ci)))

bw1 <- pipi.boot(pw1, nboot = 35L, nsim = 70L, seed = 78L,
                 return_replicates = TRUE)
bw2 <- pipi.boot(pw2, nboot = 35L, nsim = 70L, seed = 78L,
                 return_replicates = TRUE)
near(bw1$replicates_raw, bw2$replicates_raw, tolerance = 1e-8)

# Inputs and mathematically undefined cases.
bad <- function(expr) inherits(tryCatch(force(expr), error = function(e) e), "error")
stopifnot(bad(pipi(d, "g", "y", weight = "unknown")),
          bad(pipi(a, "g", data_type = "aggregate", population = "population",
                   participants = "participants", weight = "w")),
          bad(pipi.boot(p, nboot = 1L)),
          bad(pipi.boot(p, nsim = 1L)))

all_participate <- data.frame(g = rep(c("A", "B"), each = 5), y = rep(1L, 10))
all_point <- pipi(all_participate, "g", "y", nsim = 100L, seed = 1)
stopifnot(is.na(all_point$PiPi), all_point$geginiMaximum == 0)

# S3 methods should be callable after only library(pipi).
invisible(capture.output(print(p)))
invisible(capture.output(summary(p)))
invisible(capture.output(print(b1)))
invisible(capture.output(summary(b1)))
cat("All pipi package integration tests passed.\n")
