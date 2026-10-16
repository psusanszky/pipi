# Installing and checking the `pipi` R package

**Applies to:** `pipi` version **0.1.1**. These commands are suitable for Linux (including RStudio on Ubuntu and similar distributions). The R source package is not yet distributed through CRAN.

## Requirements

- **R 4.0.0 or newer**.
- An R installation accessible from the command line (`R --version`).
- The `pipi` **source project** (`pipi/` directory) or an **R-built** source archive (`pipi_0.1.1.tar.gz`).
- No third-party R packages are required for package operation. Only R's bundled packages are used.

On Windows, installing source packages may require **Rtools**; on macOS, source installations may require the **Xcode Command Line Tools**. Follow your platform's usual R source-package guidance.

## Option A: build, check, and install from the project folder (recommended)

1. Download and **extract** the source-project ZIP. It contains a folder named `pipi` with `DESCRIPTION`, `NAMESPACE`, `R/`, `man/`, `tests/`, and `inst/` inside it.
2. In **RStudio**, open the **Terminal** tab (not the R Console).
3. Navigate to the directory **containing** the extracted `pipi` folder.
4. Run the commands below, one at a time.

Expected folder structure:

```text
your-project-directory/
└── pipi/
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── README.md
    ├── INSTALL.md
    ├── METHODOLOGY.md
    ├── R/
    ├── man/
    ├── tests/
    └── inst/
```

Terminal:

```sh
# Confirm that the project folder is present.
ls -l pipi/DESCRIPTION

# Build the actual R source package archive.
R CMD build pipi

# Check the exact archive produced by the build step.
R CMD check --no-manual pipi_0.1.1.tar.gz

# Install it.
R CMD INSTALL pipi_0.1.1.tar.gz
```

The check should finish with **`Status: OK`**. If it reports `ERROR`, `WARNING`, or `NOTE`, inspect the details in `pipi.Rcheck/00check.log` before public release. Running `R CMD build` first is important: a ZIP created directly from a folder is **not** the same as an R-built source archive.

## Option B: install an existing R-built `.tar.gz`

If you already have a valid `pipi_0.1.1.tar.gz` generated with `R CMD build`, you can install it directly, without extracting the archive.

In the **R Console** (not the Terminal):

```r
install.packages("pipi_0.1.1.tar.gz", repos = NULL, type = "source")
library(pipi)
packageVersion("pipi")
```

If the archive is not in your current R working directory, use a **full filename path**:

```r
install.packages("/path/to/pipi_0.1.1.tar.gz", repos = NULL, type = "source")
```

Or select the archive interactively in RStudio:

```r
archive <- file.choose()
install.packages(archive, repos = NULL, type = "source")
```

## After installation: verify the installed package

Restart the R session in RStudio (**Session > Restart R**) to clear older manually sourced functions, then run in the **R Console**:

```r
library(pipi)
packageVersion("pipi")
find("pipi")
find("pipi.boot")

?pipi
?pipi.boot
citation("pipi")
```

With a clean R session, `find("pipi")` should normally show only `"package:pipi"`. If you see both `".GlobalEnv"` and `"package:pipi"`, an older function loaded using `source()` is masking the installed package function. Restart R, or explicitly call `pipi::pipi()` and `pipi::pipi.boot()`.

A minimal functional test:

```r
example_data <- data.frame(
  group = rep(c("A", "B", "C"), c(10, 20, 70)),
  participated = c(rep(1L, 4), rep(0L, 6),
                   rep(1L, 12), rep(0L, 8),
                   rep(1L, 24), rep(0L, 46))
)

p <- pipi(example_data, group = "group", participation = "participated",
          nsim = 1000, seed = 123)
print(p)

b <- pipi.boot(p, nboot = 99, nsim = 200, seed = 456)
print(b)
```

Both commands should return a PIPI result; the bootstrap should show confidence intervals and the number of valid resamples.

## Troubleshooting

### `ERROR: cannot change to directory 'pipi'`

You are not in the directory containing `pipi/`, or the ZIP has not yet been extracted. Check:

```sh
pwd
ls -la
find . -maxdepth 3 -name DESCRIPTION -print
```

Use the resulting **actual path** with `R CMD build`, for example:

```sh
R CMD build /actual/path/to/extracted/project/pipi
```

The `.tar.gz` output is written to the **current Terminal directory**, not necessarily inside the source directory.

### `Warning: 'pipi_0.1.1.tar.gz' is neither a file nor a directory`

The build did not create the archive where you are looking, you are using a different working directory, or the filename/version does not match. Run:

```sh
pwd
ls -lh pipi_*.tar.gz
```

Do not run `R CMD check` or `R CMD INSTALL` until the archive exists. Use the actual filename (for example, **0.1.1**, not **0.1.0**).

### `Required fields missing or empty: 'Author' 'Maintainer'`

For an `Authors@R`-based source project, create the source archive using **`R CMD build pipi`** rather than building a `.tar.gz` manually. The build process generates the derived author/maintainer metadata. Also verify that the `Authors@R` field itself contains a person with role `cre` and a valid email address.

### `The following objects are masked by '.GlobalEnv'`

Older functions (`pipi`, `pipi.boot`, etc.) remain in your R session after using `source()`. This is **not** an installation error. Restart R before evaluating the installed package.

### `R CMD check`: undefined `head`, `tail`, or `setNames`

The corrected 0.1.1 `NAMESPACE` includes:

```text
importFrom(stats,setNames)
importFrom(utils,head)
importFrom(utils,tail)
```

Make sure you are building the updated source project. If you regenerate `NAMESPACE` using a documentation tool, preserve these imports.

### `R CMD check` reports a NOTE

Read the log rather than assuming that a NOTE represents a calculation error:

```sh
grep -A 15 'NOTE' pipi.Rcheck/00check.log
```

The latest 0.1.1 source passed **`Status: OK`** in the project's development R environment before this documentation update. Rerun `R CMD check` on the newly built archive after making documentation changes.

## Keeping the local source and installed version in sync

When you change the package source, rerun:

```sh
R CMD build pipi
R CMD check --no-manual pipi_0.1.1.tar.gz
R CMD INSTALL pipi_0.1.1.tar.gz
```

Restart R and reload `library(pipi)` to ensure you are testing the newly installed build. Avoid accidentally editing a different copy of the `pipi/` directory.

## Documentation and citation

- [README.md](README.md): quick start and examples.
- [METHODOLOGY.md](METHODOLOGY.md): mathematical definition, weighted estimand, algorithms, and bootstrap limitations.
- `?pipi`, `?pipi.boot`, `?gegini`: function help in R.
- `citation("pipi")`: article citation, including BibTeX.

**Article to cite:** Susánszky, P., Somogyi, R., & Tóth, G. (2023). *Political inequality in participation index - a Gini-based measure of inequalities in political participation*. Rationality and Society, 35(2), 231–255. https://doi.org/10.1177/10434631221143614
