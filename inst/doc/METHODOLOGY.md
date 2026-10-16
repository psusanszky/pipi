# Methodological documentation: Political Inequality in Participation Index (PIPI)

**Package:** `pipi` version 0.1.1  
**Research basis:** Susánszky, Somogyi, and Tóth (2023), *Rationality and Society*, https://doi.org/10.1177/10434631221143614  
**Scope:** PIPI for binary participation, implemented for unweighted individual or aggregate data and extended to fixed individual survey weights.

This document explains the **estimand and computational choices of the R package**. The 2023 article defines the original Gini-based index and motivates normalizing for group structure and participant count. The respondent-level weighted algorithm and bootstrap procedures described here are **package implementation choices/extensions**; they should not be attributed to the article unless explicitly supported there.

## 1. Purpose and interpretation

Political participation measures are frequently binary: a respondent either did or did not vote, attend a protest, participate in a meeting, or engage in another activity. Comparing raw differences across social groups is difficult because apparent inequality is partly shaped by the number of participants and the sizes of the groups being compared.

The PIPI uses the Generalized Educational Gini (GEGINI) to describe inequality in the **distribution of participants across social groups** and normalizes this value relative to a random participation benchmark and the maximum feasible inequality for the observed structure.

The article's motivating criteria concern comparability when the **number of participants**, the **size and number of social groups**, and the resulting **feasible range of GEGINI** differ. Normalization addresses these mechanical features; it does not by itself establish that observed between-group differences are causal or free of sampling bias.

## 2. Notation and observed GEGINI

Assume there are $n$ sampled individuals divided among $K\geq2$ nonempty groups. For respondent $i$:

- $g(i)\in\{1,\ldots,K\}$ denotes group membership;
- $y_i\in\{0,1\}$ indicates participation;
- $w_i>0$ is the respondent's survey weight (equal to 1 in unweighted analysis);
- $m=\sum_i y_i$ is the **observed unweighted number** of participants.

Define each group's share of the total population weight, $k_g$, and its share of the total participant weight, $p_g$:

$$
  k_g=\frac{\sum_{i:g(i)=g}w_i}{\sum_{i=1}^{n}w_i},\qquad
  p_g=\frac{\sum_{i:g(i)=g}w_iy_i}{\sum_{i=1}^{n}w_iy_i}.
$$

Both share vectors sum to one. In unweighted data, these reduce to the respective shares of respondents and observed participants.

Order groups by increasing relative representation, $p_g/k_g$. The generalized Gini is twice the area between the 45-degree equality line and the corresponding Lorenz curve. A mathematically equivalent, order-independent formula used for efficient computation is:

$$
  G(p,k)=\sum_{1\leq g<h\leq K}\left|p_g k_h-p_h k_g\right|.
$$

An observed GEGINI of zero indicates that participant shares match population shares exactly ($p_g=k_g$ for all groups). GEGINI itself need not reach 1 even under the most unequal **feasible** participation allocation. Its feasible maximum depends on group sizes and participation count.

## 3. The randomization-expected "minimum"

The package names the normalization reference **`geginiExpectedMin`** to retain the terminology used in the PIPI literature while emphasizing that this is an **expectation**, *not the smallest mathematically attainable GEGINI*.

Conditional on the observed respondents, their group memberships and weights, and the observed unweighted participant count $m$, construct a random participation vector $Y^*$ by choosing exactly $m$ distinct respondents **uniformly without replacement** from the $n$ respondents. Define

$$
  G_{\mathrm{rand}}^{}=G\bigl(p(Y^*),k\bigr),\qquad
  G_{\mathrm{exp}}=E\left[G_{\mathrm{rand}}\mid \{g(i),w_i\}_{i=1}^n,\ m\right].
$$

The package approximates $G_{\mathrm{exp}}$ from `nsim` independently simulated random allocations:

$$
  \widehat G_{\mathrm{exp}}=\frac{1}{S}\sum_{s=1}^{S}G_{\mathrm{rand},s},\qquad
  \mathrm{MCSE}(\widehat G_{\mathrm{exp}})=\frac{\mathrm{sd}(G_{\mathrm{rand},1:S})}{\sqrt{S}}.
$$

### Unweighted data

With integer group sizes $N_1,\ldots,N_K$ and $\sum_gN_g=n$, the vector of participant counts under uniform allocation has the **multivariate hypergeometric distribution**. The package samples group counts directly and uses an optimized pairwise GEGINI formula. In individual-level equal-weight data and equivalent aggregate data, this produces the same randomization reference up to Monte Carlo variation.

### Unequal respondent weights

The same **unweighted** participant count $m$ is preserved in every random draw. Each sampled respondent retains the original $w_i$ and group membership. Therefore the **sum of selected participant weights can change** from draw to draw. This is a conditional, finite-respondent **random-allocation reference**. It is neither a constraint on weighted participation totals nor a complex survey design-based expectation.

The `mc_se` returned by `pipi()` measures only the numerical uncertainty in $\widehat G_{\mathrm{exp}}$. It is **not** the sampling standard error of the index.

## 4. Maximum feasible GEGINI

The second reference point is the greatest achievable GEGINI if exactly $m$ of the $n$ respondents were participants. Group memberships and survey weights are held fixed:

$$
  G_{\mathrm{max}}=\max_{y_i\in\{0,1\},\ \sum_i y_i=m}G\bigl(p(y),k\bigr).
$$

### Why group composition matters

The maximum cannot generally be assumed to equal 1. For example, with **100 respondents**, **40 participants**, equal weights and **three** social groups:

| Group sizes | Maximum attainable GEGINI |
| --- | ---: |
| 10, 20, 70 | 0.4500 |
| 33, 33, 34 | 0.5595 |

The values above are exact for these unweighted group counts. They demonstrate why a raw GEGINI cannot be compared without accounting for the composition of the underlying groups and the total number of participants.

In unweighted and aggregate modes, `geginiMax()` computes the maximum using feasible group-level allocations subject to each group's capacity. The same maximum applies to equivalent respondent-level unweighted data.

### Individual-level weighted maximum: group-ordering optimization

With unequal weights, group-level totals alone are not sufficient to describe which weighted participant totals are feasible: each weight belongs to a particular respondent. The package therefore maximizes GEGINI over **binary individual selections** while retaining the observed count $m$.

The computational shortcut starts from the pairwise representation of GEGINI. For any fixed group ordering $\pi$, define coefficients

$$
  a_{\pi,g}=\sum_{h\ \mathrm{before}\ g}k_h-\sum_{h\ \mathrm{after}\ g}k_h.
$$

The signed GEGINI associated with that ordering can be written as the **linear-fractional** objective

$$
  L_{\pi}(y)=
  \frac{\sum_{i=1}^{n}a_{\pi,g(i)}w_i y_i}
       {\sum_{i=1}^{n}w_i y_i}.
$$

For every feasible $y$, the GEGINI equals the **largest** such signed expression across orderings. Thus:

$$
  G_{\mathrm{max}}=\max_{\pi}\ \max_{\sum_i y_i=m}L_{\pi}(y).
$$

For a fixed ordering, the package uses a Dinkelbach-type fractional-optimization iteration. At a trial ratio $\lambda$, maximizing the transformed objective amounts to choosing the **$m$ respondents with the largest**

$$
  s_i=w_i\bigl(a_{\pi,g(i)}-\lambda\bigr).
$$

The implementation enumerates all group orderings and solves each fractional problem numerically. It reports a **maximum** and an **`optimality_gap` upper bound** (up to floating-point precision). This is not the earlier multistart local-search heuristic: the group-ordering procedure searches for a **globally optimal assignment to numerical tolerance**.

The search enumerates $K!$ group orderings, so runtime grows rapidly as $K$ increases. The default `max_permutations = 5040` permits at most **seven** groups; users can change this ceiling at their own computational risk. Equal weights bypass this optimization and use the faster unweighted calculation.

## 5. Definition of PIPI

Let $G_{\mathrm{obs}}$ denote observed GEGINI, $\widehat G_{\mathrm{exp}}$ its estimated randomization expectation, and $G_{\mathrm{max}}$ the feasible maximum. The **raw** index is

$$
  \widehat{\mathrm{PIPI}}_{\mathrm{raw}}
  =\frac{G_{\mathrm{obs}}-\widehat G_{\mathrm{exp}}}
  {G_{\mathrm{max}}-\widehat G_{\mathrm{exp}}}.
$$

The package returns both:

- **`PiPiRaw`** — the formula above, which can be negative if the observed inequality is smaller than its randomization expectation.
- **`PiPi`** — the default **zero-truncated** index, `max(0, PiPiRaw)`. If `truncate = FALSE`, `PiPi` equals `PiPiRaw`.

A negative raw PIPI **does not mean negative political inequality**. It means the observed GEGINI is below the random-allocation benchmark. Zero in the truncated index can therefore mean either exact equality or an observed GEGINI below the random benchmark; the raw value distinguishes these situations.

The denominator may be zero or nonpositive within numerical tolerance, for instance when **all respondents participate** and both reference values are zero. In such cases the index is **undefined** and the package returns `NA` rather than dividing by zero. The GEGINI components remain available.

The theoretical normalized index reaches 1 at the maximum feasible GEGINI; numerical rounding and Monte Carlo approximation are acknowledged in the returned diagnostics.

## 6. Inputs, outputs, and constraints

### Input types

| Mode | Required columns | Weighting | Conditions |
| --- | --- | --- | --- |
| Individual | `group`, `participation` | Optional `weight` column | One row per respondent; participation in `{0,1}`; finite positive weights |
| Aggregate | `group`, `population`, `participants` | Not supported | One row per group; positive integer population; integer participants from 0 to population |

At least two nonempty groups and at least one participant are required. The function **does not silently remove missing records**: group labels, participation indicators, and weights must be cleaned beforehand. Aggregate inputs are actual count tables, not rounded survey-weighted population totals.

### Important return values

| `pipi()` field | Interpretation |
| --- | --- |
| `PiPi`, `PiPiRaw` | Default truncated and raw PIPI |
| `geginiObserved` | Observed GEGINI |
| `geginiExpectedMin` | Randomization expectation estimated by Monte Carlo |
| `geginiMaximum` | Greatest feasible GEGINI |
| `mc_se` | Monte Carlo SE of expected GEGINI |
| `optimality_gap`, `maximum_certified` | Optimization diagnostic fields (weighted case) |
| `group_summary` | Shares and counts by group |
| `input` | Relevant original columns and settings retained for `pipi.boot()` |

The `pipi()` object retains only the **columns needed for estimation and resampling**, rather than the whole original survey data frame. These columns may still contain respondent-level information, so handle saved analysis objects appropriately.

## 7. Nonparametric bootstrap inference

The two-function API is designed for reproducibility and efficiency:

```r
p <- pipi(survey, group = "education", participation = "protest",
          weight = "survey_weight", nsim = 1000, seed = 123)

b <- pipi.boot(p, nboot = 999, nsim = 500,
               conf.level = 0.95, seed = 456)
```

The original `pipi()` point estimate is **reused**. For each of the `nboot` bootstrap samples, the index is recalculated with **new group composition and participant count** as appropriate; therefore **all three GEGINI components are recomputed** in each sample. Keeping the original expected minimum and maximum fixed would define a different statistic and omit their sampling variability.

- **Individual mode:** sample $n$ rows with replacement from the observed $n$ respondents. Weights remain attached to rows; they are not recalibrated.
- **Aggregate mode:** draw a multinomial sample of size $n$ from the observed group-by-participation cell probabilities. This is the count-based equivalent of resampling individuals iid from the empirical data.
- **Unusable replicates:** for example, samples with fewer than two groups, no participants, universal participation, or otherwise undefined PIPI are counted and excluded. Inspect `n_valid`, `n_failed`, and `failure_reasons`. If fewer than 30 valid draws remain, confidence intervals are not computed.
- **Confidence intervals:** the package reports **percentile bootstrap intervals**, using the empirical $\alpha/2$ and $1-\alpha/2$ quantiles of valid estimates. It also returns bootstrap standard deviations and estimated biases.

Two separate intervals are returned:

- `bootstrap_ci` for the truncated (or user-selected primary) PIPI;
- `bootstrap_ci_raw` for untruncated `PiPiRaw`.

Correspondingly, `bootstrap_se` and `bootstrap_se_raw` are the bootstrap standard errors. The `raw_negative_fraction` indicates the fraction of valid raw bootstrap replicates below zero.

The bootstrap procedure assumes **independent and identically distributed observations (i.i.d.)**. For weighted data, respondents are resampled with replacement while retaining their original survey weights. The procedure does not account for clustering, stratification, or other features of complex survey sampling designs. In particular, it does not use survey replicate weights or re-estimate calibration weights. Supplying survey weights to `pipi()` does not transform the bootstrap into a complex design-based estimator.

The reference point itself is Monte Carlo-estimated within each bootstrap sample. This adds numerical error, adjustable using the `nsim` argument of `pipi.boot()`; that simulation count is independent of the `nsim` passed to the original `pipi()` call. Before reporting small substantive effects, check numerical sensitivity to increasing `nsim`.

### Coverage and boundary considerations

In development checks using **100 repeated samples per scenario**, empirical coverage of nominal 95% percentile intervals was approximately **92–95%** for zero-near, moderate, high, and weighted-moderate scenarios; an exactly maximal case yielded **100%**. These are **limited numerical diagnostics**, not guarantees of nominal coverage for other sample sizes, participation rates, group structures, or weight distributions.

Near raw PIPI zero or a truncated PIPI boundary, bootstrap distributions can be asymmetric; the raw point estimate may even fall outside its percentile interval. The estimator can show finite-sample bias, particularly near zero. Both raw and truncated results should be examined and reported transparently.

## 8. Reproducibility and reporting recommendations

For a research report, state the social grouping, outcome definition, sample size, observed number of participants, weight construction, number of randomization draws (`nsim`), bootstrap replicates (`nboot`), Monte Carlo draws per bootstrap (`pipi.boot(nsim=...)`), confidence-interval method, and whether raw or zero-truncated PIPI was used.

A compact example:

```r
p <- pipi(data = survey, group = "education",
          participation = "protest", weight = "survey_weight",
          nsim = 10000, seed = 123)

b <- pipi.boot(p, nboot = 999, nsim = 500,
               conf.level = 0.95, seed = 456)

c(PIPI = p$PiPi,
  G_observed = p$geginiObserved,
  G_expected_min = p$geginiExpectedMin,
  G_max = p$geginiMaximum,
  boot_SE = b$bootstrap_se)
b$bootstrap_ci
b$bootstrap_ci_raw
```

Use `citation("pipi")` to generate the bibliographic reference. Reproducible seeds ensure the same random allocations for a fixed package version and R random-number generator environment.

## 9. Reference

Susánszky, P., Somogyi, R., & Tóth, G. (2023). Political inequality in participation index - a Gini-based measure of inequalities in political participation. *Rationality and Society, 35*(2), 231–255. https://doi.org/10.1177/10434631221143614

**Related:** [README.md](README.md) · [INSTALL.md](INSTALL.md) · R help: `?pipi`, `?pipi.boot`, `?gegini`.
