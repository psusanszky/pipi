# PIPI methodological and computational guide

This text is shipped with the package; read the help pages for exact argument
names and return values.

## Two-stage workflow

1. `pipi()` computes observed GEGINI, simulated random-allocation expected
   GEGINI (`geginiExpectedMin`) and the feasible maximum, then calculates PIPI.
2. `pipi.boot()` takes that output object and recomputes the full PIPI in each
   independent-with-replacement bootstrap sample. The original point estimate
   and the unnecessary original data columns are never recomputed.

The bootstrap can be relatively slow if there are many groups because the
weighted maximum examines all group orderings. `profile = TRUE` provides
timings; Monte Carlo draws and bootstrap replicates are configurable.

## What is held fixed?

In each randomization-benchmark draw, the total **unweighted** number of
participants stays fixed at the observed value. Respondent weights and social
group memberships stay attached to respondents, but the sum of the weights of
selected participants is allowed to vary. This is distinct from holding
weighted participation totals fixed and from a complex survey-design estimator.

In a bootstrap replicate, the group sizes and the observed unweighted number
of participants generally change, so the expected and maximum GEGINI must be
recomputed for that replicate. Reusing the original three components would
change the bootstrap estimand.

## Interpretation

- `geginiObserved`: inequality in observed weighted/unweighted group shares.
- `geginiExpectedMin`: expected inequality under random participation; despite
  its name, **not the smallest attainable GEGINI**.
- `geginiMaximum`: highest GEGINI feasible under the fixed respondent set,
  weights, and participant count in that point/replicate sample.
- `PiPiRaw`: may be negative when observed inequality is below the random
  allocation expectation.
- `PiPi`: by default, negative `PiPiRaw` becomes zero.
- `bootstrap_ci_raw`: untruncated raw percentile interval; may include negatives.
- `bootstrap_ci`: truncated percentile interval.

The Monte Carlo standard error `mc_se` concerns the estimated expected GEGINI;
it is not the bootstrap standard error of PIPI.

## Data requirements

Individual data: a `data.frame` with one row per respondent, nonmissing social
group, 0/1 participation, and optional strictly positive finite weights.
Aggregate data: one row per group, with strictly positive integer population
counts and integer participant counts between zero and population count.
Neither mode silently drops rows with missing values.

The index may be undefined for some samples, for example when everybody
participates; `PiPi` and `PiPiRaw` will then be `NA`.

## Inference limitations

The bootstrap assumes iid observations. Attaching fixed post-stratification or
calibration weights to sampled respondents is a pragmatic bootstrap convention,
not a substitute for replicating the underlying stratification, clustering,
or original weight-calibration procedure. In complex surveys, a design-aware
procedure may be more appropriate.

The bootstrap uses percentile intervals, which can have imperfect coverage
near zero or one and when the estimator is biased. Earlier small simulation
studies are encouraging but not a general guarantee of 95% coverage.

## Reference

Please cite Susánszky, P., Somogyi, R., and Tóth, G. (2023),
“Political inequality in participation index - a Gini-based measure of
inequalities in political participation,” *Rationality and Society*,
35(2), 231–255. DOI: 10.1177/10434631221143614.

From an installed R session, run `citation("pipi")` or
`toBibtex(citation("pipi"))`.
