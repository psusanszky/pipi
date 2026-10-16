\name{pipi}
\alias{pipi}
\alias{print.pipi}
\alias{summary.pipi}
\title{Calculate the Political Inequality in Participation Index}
\description{
Computes PIPI and its three GEGINI components for respondent-level or
aggregated participation data. Survey weights are optional for respondent-level
data; no additional R packages are required.
}
\usage{
pipi(data, group, participation = NULL, weight = NULL,
     population = NULL, participants = NULL,
     data_type = c("individual", "aggregate"),
     nsim = 1000L, seed = NULL, truncate = TRUE,
     return_simulations = FALSE, tol = 1e-11,
     max_iter = 100L, max_permutations = 5040L)
\method{print}{pipi}(x, ...)
\method{summary}{pipi}(object, ...)
}
\arguments{
\item{data}{A data frame with one row per respondent (individual mode) or
one row per social group (aggregate mode).}
\item{group}{Name of the group column (character scalar).}
\item{participation}{Name of a nonmissing binary 0/1 participation column
in individual mode.}
\item{weight}{Optional name of a positive numeric respondent-weight column;
\code{NULL} gives everyone weight one. Not accepted in aggregate mode.}
\item{population}{Name of the integer group-size column in aggregate mode.}
\item{participants}{Name of the integer group participant-count column in aggregate mode.}
\item{data_type}{\code{"individual"} (default) or \code{"aggregate"}.}
\item{nsim}{Number of random allocations used to estimate expected GEGINI.}
\item{seed}{Optional integer random seed; supplied seeds preserve the caller's
random-number state.}
\item{truncate}{If \code{TRUE} (default), negative raw PIPI values are reported
as zero in \code{PiPi}. \code{PiPiRaw} is always retained.}
\item{return_simulations}{Return the individual randomization GEGINI values
in \code{min_simulations}. This may use more memory.}
\item{tol}{Numerical tolerance in the weighted maximum optimizer.}
\item{max_iter}{Maximum number of fractional-optimization iterations per
group ordering.}
\item{max_permutations}{Maximum allowed number of group orderings. Defaults
to 5040 (seven groups). Higher settings can be expensive.}
\item{x, object}{Result returned by \code{pipi()}.}
\item{...}{Additional arguments (currently ignored by print and summary).}
}
\details{
PIPI is calculated as
\deqn{PIPI_{raw} = (G_{observed} - E[G_{random}]) / (G_{max} - E[G_{random}]).}
\code{geginiExpectedMin} is the expected generalized Gini under uniform
random allocation of exactly the observed \emph{unweighted} number of
participants, without replacement. It is not necessarily the mathematically
smallest feasible GEGINI.

For weighted data, the survey weights and group memberships are fixed to
respondents. The weighted number of participants changes between random
allocations. The maximum is found by a globally optimizing group-ordering
algorithm, numerically certified to the reported tolerance. If the weights are
all equal, the faster unweighted calculation is used.

If all respondents participate, the normalization denominator is zero and
PIPI is returned as \code{NA_real_}. Aggregate mode accepts only actual
nonnegative integer counts, not fractional or survey-weighted group totals.
The result retains the relevant data columns for use by \code{pipi.boot()}.
}
\value{
A list of class \code{"pipi"} containing \code{PiPi}, \code{PiPiRaw},
\code{geginiObserved}, \code{geginiExpectedMin}, \code{geginiMaximum},
\code{mc_se} (Monte Carlo standard error for expected GEGINI),
\code{group_summary}, \code{optimality_gap}, \code{maximum_certified},
\code{input} (for a later bootstrap), and other diagnostic fields.
\code{mc_se} is not a survey standard error. Legacy aliases
\code{geginiRaw}, \code{StrMin}, and \code{StrMax} are also available.
}
\examples{
d <- data.frame(
  education = rep(c("low", "middle", "high"), c(10, 20, 70)),
  protest = c(rep(1, 5), rep(0, 5), rep(1, 10), rep(0, 10),
              rep(1, 25), rep(0, 45)))
res <- pipi(d, group = "education", participation = "protest",
            nsim = 200, seed = 1)
res$PiPi
res$geginiExpectedMin

agg <- data.frame(education = c("low", "middle", "high"),
                  population = c(10, 20, 70), participants = c(5, 10, 25))
pipi(agg, group = "education", population = "population",
     participants = "participants", data_type = "aggregate",
     nsim = 200, seed = 1)$PiPi
}
\seealso{\code{\link{pipi.boot}}, \code{\link{gegini}}}
