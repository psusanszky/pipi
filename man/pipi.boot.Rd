\name{pipi.boot}
\alias{pipi.boot}
\alias{print.pipi_boot}
\alias{summary.pipi_boot}
\title{Nonparametric bootstrap confidence intervals for PIPI}
\description{
Takes an existing \code{pipi()} object, resamples respondents or group-by-
participation cells, and recomputes the entire index on each bootstrap sample.
Returns percentile intervals for both the truncated and raw index.
}
\usage{
pipi.boot(object, nboot = 999L, nsim = 500L,
          conf.level = 0.95, seed = NULL,
          return_replicates = FALSE, profile = FALSE)
\method{print}{pipi_boot}(x, ...)
\method{summary}{pipi_boot}(object, ...)
}
\arguments{
\item{object}{Output of \code{pipi()}; it must retain \code{input$data}.}
\item{nboot}{Number of bootstrap replicates (integer, at least 30).}
\item{nsim}{Number of random allocations within each bootstrap replicate
for computing \code{geginiExpectedMin} (integer, at least two).}
\item{conf.level}{Confidence level between zero and one.}
\item{seed}{Optional integer random seed, with caller RNG state preserved.}
\item{return_replicates}{Whether to include raw and truncated bootstrap
replicate vectors.}
\item{profile}{Measure approximate elapsed time spent in each PIPI component.}
\item{x}{Output of \code{pipi.boot()}.}
\item{...}{Additional arguments (currently ignored by print and summary).}
}
\details{
For individual-level data, \code{n} rows are selected with replacement
from the original \code{n} respondents. Survey weights remain attached to
individuals; they are not recomputed. For aggregate integer counts, bootstrap
cell counts are drawn from the multinomial distribution over group by
participation cells. This is the equivalent iid empirical-distribution
bootstrap, and does not require expanding the counts into individual rows.

Each replicate recalculates observed GEGINI, randomization expected GEGINI,
and feasible maximum GEGINI. Original point estimates are not recalculated.
A missing or mathematically undefined replicate is excluded; its reason is
recorded and a warning emitted. Percentile intervals are calculated from
valid replicates when there are at least 30.

The standard errors and confidence intervals quantify sampling variation
under independent, identically distributed observations. They do \emph{not}
incorporate complex survey sampling designs, clustering, stratification, or
replicate weights. The inner Monte Carlo approximation can add numerical noise.
Near zero or one, percentile intervals may have nonstandard coverage.
}
\value{
An object of class \code{"pipi_boot"} with \code{point},
\code{bootstrap_se}, \code{bootstrap_ci}, \code{bootstrap_se_raw},
\code{bootstrap_ci_raw}, \code{bootstrap_bias}, \code{bootstrap_bias_raw},
\code{raw_negative_fraction}, \code{n_valid}, \code{n_failed},
\code{failure_reasons}, and \code{elapsed_seconds}. With options enabled,
\code{replicates}, \code{replicates_raw}, and \code{timing} are included.
}
\examples{
d <- data.frame(g = rep(c("A", "B", "C"), c(10, 20, 70)),
                y = c(rep(1, 5), rep(0, 5), rep(1, 10), rep(0, 10),
                      rep(1, 25), rep(0, 45)))
p <- pipi(d, "g", "y", nsim = 200, seed = 1)
b <- pipi.boot(p, nboot = 30, nsim = 50, seed = 2)
b$bootstrap_ci
b$bootstrap_ci_raw
}
\seealso{\code{\link{pipi}}}
