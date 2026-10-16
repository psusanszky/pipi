# Install pipi_0.1.0.tar.gz first.
library(pipi)
survey <- data.frame(
  group = rep(c("A", "B", "C"), c(10L, 20L, 70L)),
  participate = c(rep(1L, 5L), rep(0L, 5L),
                  rep(1L, 10L), rep(0L, 10L),
                  rep(1L, 25L), rep(0L, 45L)))
survey$weight <- seq(0.8, 1.2, length.out = nrow(survey))
p <- pipi(survey, "group", "participate", "weight", nsim = 1000, seed = 11)
print(p)
print(p$group_summary)
pb <- pipi.boot(p, nboot = 199, nsim = 250, seed = 22, profile = TRUE)
print(pb)
