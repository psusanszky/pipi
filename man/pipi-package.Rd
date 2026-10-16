\name{pipi-package}
\alias{pipi-package}
\docType{package}
\title{Political Inequality in Participation Index}
\description{
The \pkg{pipi} package implements PIPI point estimates and iid bootstrap
confidence intervals for political-participation inequality across groups.
}
\details{
The main functions are \code{\link{pipi}} and \code{\link{pipi.boot}}.
The randomization expected GEGINI is called \code{geginiExpectedMin} in the
output; it is not the smallest feasible GEGINI. Weighted computations fix
respondent weights and the unweighted participation count. No third-party
packages are needed.
}
\seealso{\code{\link{pipi}}, \code{\link{pipi.boot}}}

\references{
Susánszky, P., Somogyi, R., and Tóth, G. (2023). Political inequality in
participation index - a Gini-based measure of inequalities in political
participation. \emph{Rationality and Society}, 35(2), 231--255.
\doi{10.1177/10434631221143614}.
}
