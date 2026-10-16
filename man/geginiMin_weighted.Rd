\name{geginiMin_weighted}
\alias{geginiMin_weighted}
\title{Simulated expected GEGINI with fixed respondent weights}
\description{
Uniformly selects exactly the observed number of respondents without
replacement, while preserving each respondent's group and survey weight.
}
\usage{
geginiMin_weighted(data, group, participation, weight = NULL,
                   nsim = 10000L, seed = NULL,
                   return_simulations = FALSE)
}
\arguments{
\item{data}{Respondent-level data frame.}
\item{group}{Name of a social group column.}
\item{participation}{Name of a binary 0/1 participation column.}
\item{weight}{Name of a strictly positive weight column, or NULL for ones.}
\item{nsim}{Number of Monte Carlo draws.}
\item{seed}{Optional random seed.}
\item{return_simulations}{Return every simulated GEGINI value.}
}
\details{
The number selected is the observed \emph{unweighted} participant count.
The weighted participant total varies by random allocation. This is not a
complex survey-design estimator and is not the mathematical minimum.
}
\value{
A \code{"geginiMinWeighted"} list with \code{estimate},
\code{mc_se}, \code{observed}, \code{group_population_shares}, \code{n},
\code{participants}, \code{nsim}, and optionally \code{simulations}.
}
\examples{
d <- data.frame(g = rep(c("A", "B"), each = 5),
                y = c(1, 1, 0, 0, 0, 1, 0, 0, 0, 0),
                w = seq(1, 2, length.out = 10))
geginiMin_weighted(d, "g", "y", "w", nsim = 100, seed = 1)$estimate
}
