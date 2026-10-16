\name{geginiMin}
\alias{geginiMin}
\title{Simulated expected GEGINI under unweighted random participation}
\description{
Estimates expected GEGINI by generating participant counts from a
multivariate hypergeometric distribution with a fixed participant count.
}
\usage{
geginiMin(strukt, rv, nsim = 10000L, seed = NULL,
          return_simulations = FALSE, block_size = 10000L)
}
\arguments{
\item{strukt}{Positive integer group sizes (at least two groups).}
\item{rv}{Observed unweighted number of participants, between one and \code{sum(strukt)}.}
\item{nsim}{Number of Monte Carlo draws.}
\item{seed}{Optional random seed.}
\item{return_simulations}{If TRUE, return a list with all draws and their Monte Carlo SE.}
\item{block_size}{Number of draws processed together to limit memory use.}
}
\details{
Although historically called a minimum, this is the expectation under
random participation, not the theoretical minimum achievable GEGINI. Each
allocation selects exactly \code{rv} people uniformly without replacement.
The routine is implemented in base R using vectorized hypergeometric draws.
}
\value{
If \code{return_simulations=FALSE}, a numeric expected GEGINI. If TRUE,
a list containing \code{estimate}, \code{mc_se}, and \code{simulations}.
}
\examples{
geginiMin(c(5, 5), rv = 5, nsim = 1000, seed = 1)
}
