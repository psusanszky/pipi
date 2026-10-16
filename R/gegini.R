# GEGINI calculation. Formula unchanged from the validated prototype.
# This version tightens input checks and provides a functional base-R plot.
gegini <- function(df = NULL, p = NULL, k = NULL, normalize = TRUE,
                   plot = FALSE, returnTable = FALSE, ...) {
  if (!is.null(df)) {
    if (!is.data.frame(df) || !all(c("p", "k") %in% names(df)))
      stop("'df' must be a data.frame containing 'p' and 'k'.")
    p <- df$p
    k <- df$k
  }
  if (is.null(p) || is.null(k) || !is.numeric(p) || !is.numeric(k) ||
      length(p) != length(k) || length(p) < 2L || anyNA(p) || anyNA(k) ||
      any(!is.finite(p)) || any(!is.finite(k)))
    stop("'p' and 'k' must be finite numeric vectors of the same length (at least 2).")
  if (any(p < 0) || all(p == 0)) stop("'p' must be nonnegative with a positive total.")
  if (any(k <= 0)) stop("Every group population share 'k' must be positive.")
  if (!is.logical(normalize) || length(normalize) != 1L || is.na(normalize))
    stop("'normalize' must be TRUE or FALSE.")
  if (!is.logical(plot) || length(plot) != 1L || is.na(plot) ||
      !is.logical(returnTable) || length(returnTable) != 1L || is.na(returnTable))
    stop("'plot' and 'returnTable' must be TRUE or FALSE.")

  if (round(sum(p), 6L) != 1) {
    if (!normalize) stop("'p' does not sum to one. Set 'normalize=TRUE'.")
    warning("'p' vector is normalized.", call. = FALSE)
    p <- p / sum(p)
  }
  if (round(sum(k), 6L) != 1) {
    if (!normalize) stop("'k' does not sum to one. Set 'normalize=TRUE'.")
    warning("'k' vector is normalized.", call. = FALSE)
    k <- k / sum(k)
  }
  tab <- data.frame(p = p, k = k, slope = p / k)
  if (!is.null(df)) rownames(tab) <- rownames(df)
  tab <- tab[order(tab$slope), , drop = FALSE]
  tab$cumSum <- cumsum(tab$k)
  value <- 2 * (0.5 - (sum(tab$k * tab$p / 2) +
                       sum(tab$p * (1 - tab$cumSum))))
  value <- structure(as.numeric(value), class = "gegini")
  if (plot) .pipi_plot_lorenz(tab, value = value, ...)
  if (returnTable) {
    return(structure(list(gegini = value, inequalityTable = tab),
                     class = "geginiTable"))
  }
  value
}

#' @noRd
.pipi_plot_lorenz <- function(x, value = NULL, lwd = 2, xlab = "Population share",
                        ylab = "Participant share", main = "GEGINI Lorenz curve",
                        texts = FALSE, ...) {
  if (inherits(x, "geginiTable")) {
    value <- as.numeric(x$gegini)
    x <- x$inequalityTable
  }
  if (!is.data.frame(x) || !all(c("p", "k") %in% names(x)))
    stop("Plotting requires a GEGINI inequality table; call gegini(..., returnTable=TRUE).")
  K <- c(0, cumsum(x$k))
  L <- c(0, cumsum(x$p))
  if (!is.null(value)) main <- paste0(main, " (", format(round(value, 4)), ")")
  graphics::plot(K, L, type = "l", lwd = lwd, xlab = xlab, ylab = ylab,
                 main = main, xlim = c(0, 1), ylim = c(0, 1),
                 xaxs = "i", yaxs = "i", ...)
  graphics::abline(0, 1, lty = 2, col = "gray50")
  graphics::points(K, L, pch = 19, cex = 0.6)
  if (isTRUE(texts)) {
    labels <- rownames(x)
    graphics::text((head(K, -1L) + tail(K, -1L)) / 2,
                   (head(L, -1L) + tail(L, -1L)) / 2,
                   labels = labels, cex = 0.7, pos = 3)
  }
  invisible(x)
}

plot.geginiTable <- function(x, ...) .pipi_plot_lorenz(x, ...)
