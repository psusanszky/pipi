\name{geginiMax_weighted_ordered}
\alias{geginiMax_weighted_ordered}
\title{Globally optimized weighted GEGINI maximum}
\description{
Optimizes GEGINI over possible respondent-level participant assignments
with fixed weights, memberships, and unweighted participant count.
}
\usage{
geginiMax_weighted_ordered(data, group, participation, weight = NULL,
                           tol = 1e-11, max_iter = 100L,
                           max_permutations = 5040L)
}
\arguments{
\item{data}{Respondent-level data frame.}
\item{group}{Name of the group column.}
\item{participation}{Name of a binary 0/1 participation column.}
\item{weight}{Name of a strictly positive respondent-weight column, or NULL.}
\item{tol}{Positive numerical tolerance for the optimizer.}
\item{max_iter}{Maximum iterations per group ordering.}
\item{max_permutations}{Maximum number of group orderings evaluated.}
}
\details{
All \eqn{G!} group orderings are considered. For each ordering, a
linear-fractional objective is optimized by Dinkelbach iterations. The inner
problem selects the observed count of respondents with highest scores.
The reported optimality bound is numerical (subject to floating-point error).
The number of orderings grows factorially with the number of social groups.
}
\value{
A \code{"geginiMaxWeightedOrdered"} list containing \code{maximum},
\code{selected_rows}, \code{certified}, \code{optimality_gap_bound},
\code{upper_bound}, \code{permutations_checked}, and other diagnostics.
}
\examples{
d <- data.frame(g = rep(c("A", "B"), each = 5),
                y = c(1, 1, 0, 0, 0, 1, 0, 0, 0, 0),
                w = seq(1, 2, length.out = 10))
geginiMax_weighted_ordered(d, "g", "y", "w")$maximum
}
