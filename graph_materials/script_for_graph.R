library(ggplot2)

# ── CHANGE THIS ───────────────────────────────────────────
csv_file <- "freight_ratio.csv"   # path to your CSV
# ──────────────────────────────────────────────────────────

df       <- read.csv(csv_file)
col_name <- colnames(df)[1]   # auto-grabs the first column name

cat("Using column:", col_name, "\n")  # prints it so you can verify

vals <- df[[col_name]]

# Histogram
ggplot(df, aes(x = .data[[col_name]])) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  labs(title = paste("Histogram of", col_name), x = col_name, y = "Count") +
  theme_minimal()

# Box plot — improved
ggplot(df, aes(x = "", y = .data[[col_name]])) +
  geom_boxplot(
    fill        = "steelblue",
    color       = "black",
    width       = 0.4,
    outlier.shape  = 16,
    outlier.size   = 1.2,
    outlier.alpha  = 0.3,      # fades overlapping dots so clusters are visible
    outlier.color  = "black"
  ) +
  coord_flip() +               # horizontal = much more breathing room
  labs(
    title    = paste("Box Plot of", col_name),
    subtitle = paste0(
      "Median: ", round(median(vals, na.rm = TRUE), 2),
      "  |  IQR: ", round(IQR(vals, na.rm = TRUE), 2),
      "  |  n = ", sum(!is.na(vals))
    ),
    y = col_name,
    x = NULL
  ) +
  theme_minimal() +
  theme(
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
  )