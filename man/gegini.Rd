\name{gegini}
\alias{gegini}
\alias{plot.geginiTable}
\title{Generalized Gini index for political participation}
\description{
Calculates the generalized Gini index from participant shares \code{p}
and population shares \code{k} across nonempty groups.
}
\usage{
gegini(df = NULL, p = NULL, k = NULL, normalize = TRUE,
       plot = FALSE, returnTable = FALSE, ...)
\method{plot}{geginiTable}(x, ...)
}
\arguments{
\item{df}{Optional data frame containing columns \code{p} and \code{k}.}
\item{p}{Numeric vector of group shares among participants.}
\item{k}{Numeric vector of population group shares, all strictly positive.}
\item{normalize}{Normalize vectors not summing to one (with a warning).}
\item{plot}{Draw the corresponding Lorenz curve.}
\item{returnTable}{Return the sorted inequality table along with the index.}
\item{x}{GEGINI table returned with \code{returnTable=TRUE}.}
\item{...}{Additional base-graphics parameters passed to the Lorenz plot.}
}
\details{
Groups are ordered by their participant-to-population share ratios.
GEGINI can equivalently be written as
\deqn{G = \sum_{g<h} |p_g k_h - p_h k_g|.}
Zero participant shares are allowed but population shares must be positive.
}
\value{
A single numeric index of class \code{"gegini"}; if
\code{returnTable=TRUE}, a list of class \code{"geginiTable"} containing
\code{gegini} and \code{inequalityTable}.
}
\examples{
gegini(p = c(0.1, 0.3, 0.6), k = c(0.2, 0.3, 0.5))
}
