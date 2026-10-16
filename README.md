# pipi: Political Inequality in Participation Index

**`pipi`** is an R package for measuring inequality in **binary political participation** (for example, whether someone voted, protested, or contacted a representative) across social groups. It implements the Political Inequality in Participation Index (PIPI) introduced by **Susánszky, Somogyi, and Tóth (2023)**.

PIPI builds on a generalized Gini index (GEGINI) and adjusts it for (i) the inequality expected when the observed number of participants is allocated randomly, and (ii) the greatest inequality achievable given the observed group composition and participant count.

**Version:** 0.1.1 · **Status:** research software; source installation (not on CRAN) · **Dependencies:** no third-party R packages (R >= 4.0.0)

## Features

- Analyze **respondent-level data**, with `weight = NULL` (equal weights) or a column of positive **survey weights**.
- Analyze **aggregated, unweighted integer counts** by social group.
- Compute the observed GEGINI, **randomization-expected GEGINI** (`geginiExpectedMin`), and attainable GEGINI maximum.
- Use a numerically certified **individual-level weighted maximum** algorithm with no external optimization solver.
- Provides bootstrap standard errors and confidence intervals using nonparametric resampling of individual observations (or equivalent group-by-participation cell counts for aggregate data).
- Reproduce results with optional random seeds, inspect group-level summaries, and obtain a citation for the original article.

## Installation

The package is **not currently available on CRAN**. Once available on GitHub, install the development release with:

```r
install.packages("remotes")  # installation helper only; not a package dependency
remotes::install_github("psusanszky/pipi")
```

Alternatively, build and install from the source project:

In an **RStudio Terminal** (from the directory containing the extracted `pipi/` folder):

```sh
R CMD build pipi
R CMD check --no-manual pipi_0.1.1.tar.gz
R CMD INSTALL pipi_0.1.1.tar.gz
```

Then, in the **R Console**:

```r
library(pipi)
packageVersion("pipi")
```

If you already have the R-built `pipi_0.1.1.tar.gz`, you can instead install it from the R Console:

```r
install.packages("pipi_0.1.1.tar.gz", repos = NULL, type = "source")
library(pipi)
```

The archive must be in your current directory, or you must supply its full path. Full instructions, including Linux/RStudio troubleshooting, are in **[INSTALL.md](inst/doc/INSTALL.md)**.

## Quick start: respondent-level data

Create a small example with three educational groups (10%, 20%, and 70% of the respondents) and 40 participants among 100 respondents:

```r
library(pipi)

survey <- data.frame(
  education = rep(c("Low", "Middle", "High"), c(10, 20, 70)),
  protest = c(rep(1L, 4), rep(0L, 6),
              rep(1L, 12), rep(0L, 8),
              rep(1L, 24), rep(0L, 46))
)

p <- pipi(
  data = survey,
  group = "education",
  participation = "protest",
  nsim = 1000,
  seed = 123
)

print(p)
p$group_summary
```

`participation` must be a binary `0`/`1` (or logical) variable, with one row per respondent. The `group` variable identifies the social categories to compare.

### Weighted respondent-level data

Supply the **name of the weight column**. When omitted (`weight = NULL`), all respondents have weight 1.

```r
survey$survey_weight <- rep(c(0.8, 1.0, 1.2, 1.5), length.out = nrow(survey))

pw <- pipi(
  data = survey,
  group = "education",
  participation = "protest",
  weight = "survey_weight",
  nsim = 1000,
  seed = 123
)

pw$PiPi
pw$geginiMaximum
pw$optimality_gap
```

Weights must be finite, numeric, and strictly positive. The randomization benchmark holds the **unweighted number of participants** fixed; the total weight of selected participants can vary. This is **not** a complex survey-design estimator.

### Aggregated group counts

When only group-level counts are available, specify `data_type = "aggregate"`:

```r
groups <- data.frame(
  education = c("Low", "Middle", "High"),
  population = c(10, 20, 70),
  participants = c(4, 12, 24)
)

pa <- pipi(
  data = groups,
  group = "education",
  population = "population",
  participants = "participants",
  data_type = "aggregate",
  nsim = 1000,
  seed = 123
)

pa$PiPi
```

Aggregate mode requires **actual integer group counts**, not survey-weighted or fractional population estimates. The aggregate and unweighted respondent-level versions agree for equivalent data, apart from Monte Carlo error when different random draws are used.

## Bootstrap confidence intervals

The workflow deliberately has **two functions**. `pipi()` calculates and stores the point estimate; `pipi.boot()` takes this result and estimates uncertainty **without recalculating the original point estimate**.

```r
pb <- pipi.boot(
  pw,
  nboot = 999,
  nsim = 500,
  conf.level = 0.95,
  seed = 456
)

print(pb)
pb$bootstrap_ci       # percentile CI, zero-truncated PIPI
pb$bootstrap_ci_raw   # percentile CI, raw PIPI (may include negatives)
pb$bootstrap_se
pb$bootstrap_se_raw
pb$n_valid
pb$n_failed
```

Every bootstrap replicate **recalculates all three GEGINI components**. This is necessary because the group sizes and participant count can change under resampling. For individual data it resamples respondents with replacement and keeps weights attached to sampled respondents. For aggregate data it samples the group-by-participation cells from the empirical multinomial distribution.

The bootstrap procedure assumes **independent and identically distributed observations (i.i.d.)**. For weighted data, respondents are resampled with replacement while retaining their original survey weights. The procedure does not account for clustering, stratification, or other features of complex survey sampling designs. For a detailed discussion see [METHODOLOGY.md](inst/doc/METHODOLOGY.md).

To inspect performance or retain bootstrap values:

```r
pb_detailed <- pipi.boot(
  p,
  nboot = 199,
  nsim = 500,
  seed = 789,
  profile = TRUE,
  return_replicates = TRUE
)

pb_detailed$timing$component_seconds
pb_detailed$replicates_raw
```

## Understanding the results

For each group, let $k_g$ be its share of the (weighted or unweighted) population and $p_g$ its share of participants. The raw index is

$$
\mathrm{PIPI}_{\mathrm{raw}} =
\frac{G_{\mathrm{observed}} - E[G_{\mathrm{random}}]}
     {G_{\mathrm{maximum}} - E[G_{\mathrm{random}}]}.
$$

By default, `PiPi = max(0, PiPiRaw)`. A negative **raw** PIPI means that observed inequality is **lower** than the expectation under random participation; it does **not** indicate negative inequality. Set `truncate = FALSE` in `pipi()` to use the untruncated index as the primary result.

| Result field | Meaning |
| --- | --- |
| `PiPi` | PIPI with negatives set to zero by default |
| `PiPiRaw` | Untruncated PIPI (may be negative) |
| `geginiObserved` | GEGINI for the observed data |
| `geginiExpectedMin` | **Expected** GEGINI under random allocation; not the mathematical minimum |
| `geginiMaximum` | Largest attainable GEGINI under the specified constraints |
| `mc_se` | Monte Carlo standard error of the **expected GEGINI**, not the sampling SE of PIPI |
| `group_summary` | Group sizes, participant counts, weighted totals, and shares |
| `optimality_gap` | Weighted maximum's numerical optimality-gap bound; `NA` in unweighted mode |
| `bootstrap_ci`, `bootstrap_ci_raw` | Percentile intervals from `pipi.boot()` |

If the normalization denominator is zero (e.g., **all respondents participate**), PIPI is undefined and returned as `NA`. Samples with missing inputs are not silently modified: clean them explicitly before estimation.

## Methodology and limitations

The [methodological documentation](inst/doc/METHODOLOGY.md) explains the GEGINI formula, the randomization-expected minimum, the feasible maximum for unequal groups and fixed individual weights, numerical optimization, the bootstrap, and interpretation. The original article introduces the unweighted index; the **fixed-individual-weight implementation** is an explicit extension in this package and should not be mistaken for full survey-design inference.

The weighted maximum checks all group orders, with `max_permutations = 5040` by default (**up to seven groups**). The computational cost can rise rapidly when the number of social groups increases. Monte Carlo estimates and percentile confidence intervals have finite-simulation error and can be less reliable near the index boundaries.

## Help and reproducibility

```r
?pipi
?pipi.boot
?gegini
citation("pipi")
toBibtex(citation("pipi"))
```

For package-level tests, run `R CMD check --no-manual pipi_0.1.1.tar.gz` in a Terminal after `R CMD build`. The version 0.1.1 code has passed the R CMD check in the development environment; after updating documentation, rerun the check on the new source build.

## Citation

Please cite the **original three-author article** when using PIPI:

> Susánszky, P., Somogyi, R., & Tóth, G. (2023). Political inequality in participation index - a Gini-based measure of inequalities in political participation. *Rationality and Society, 35*(2), 231–255. https://doi.org/10.1177/10434631221143614

The installed package's `citation("pipi")` returns the formatted reference and BibTeX entry.

## License

GPL (>= 3), as specified in the package `DESCRIPTION`. Confirm maintainer contact and release permissions before public distribution.
