\name{geginiMax}
\alias{geginiMax}
\title{Maximum feasible GEGINI from unweighted group counts}
\description{
Finds the largest GEGINI among allocations of \code{rv} participants to
social groups with fixed integer capacities.
}
\usage{
geginiMax(strukt = NULL, rv = NULL)
}
\arguments{
\item{strukt}{Vector of positive integer group sizes.}
\item{rv}{Observed unweighted number of participants.}
}
\details{
Uses the original group-count allocation algorithm. This calculation is
for unweighted counts; use \code{geginiMax_weighted_ordered()} if respondent
weights differ. Calls with invalid counts should be avoided; \code{pipi()}
validates its input before invoking this routine.
}
\value{Numeric maximal feasible GEGINI of class \code{"geginiMax"}.}
\examples{
geginiMax(c(10, 20, 70), rv = 40)
}
