library(ggplot2)

# ── CHANGE THIS ───────────────────────────────────────────
csv_file <- "delivery_time.csv"   # path to your CSV
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

# Box plot
ggplot(df, aes(y = .data[[col_name]])) +
  geom_boxplot(fill = "steelblue", color = "black", width = 0.4) +
  labs(title = paste("Box Plot of", col_name), y = col_name) +
  theme_minimal()