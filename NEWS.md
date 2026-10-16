# pipi 0.1.1

- Expanded English GitHub README, methodological documentation and step-by-step installation guide (documentation-only update).

- Added an `inst/CITATION` file referencing Susánszky, Somogyi and Tóth (2023), *Rationality and Society*, DOI 10.1177/10434631221143614.
- Replaced provisional metadata with all three authors and the corresponding-author email printed in the article (please verify the maintenance address before public release).
- Added explicit `stats` and `utils` imports to remove the earlier R CMD check NOTE.
- No changes to the validated statistical algorithms.

# pipi 0.1.0 (development release)

- First installable source package with `pipi()` and `pipi.boot()`.
- Respondent-level unweighted and weighted inputs, and aggregated integer counts.
- Fast Monte Carlo expected-minimum algorithms.
- Globally optimized respondent-level weighted maximum, with an optimality-gap bound.
- iid nonparametric percentile bootstrap with raw and zero-truncated intervals.
- Base-R integration tests and reference documentation; no third-party package dependencies.

**Release checklist:** replace provisional maintainer metadata and confirm license choice,
run `R CMD check --as-cran`, check package naming and add citation metadata before public release.
