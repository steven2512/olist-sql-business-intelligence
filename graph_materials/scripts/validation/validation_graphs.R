library(ggplot2)

# Point this to a validation export in graph_materials/csv when those files exist.
csv_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/replace_with_validation_export.csv"

if (file.exists(csv_file)) {
  df <- read.csv(csv_file)
  col_name <- colnames(df)[1]

  cat("Using column:", col_name, "\n")

  ggplot(df, aes(x = .data[[col_name]])) +
    geom_histogram(bins = 30, fill = "slateblue", color = "white") +
    labs(
      title = paste("Histogram of", col_name),
      x = col_name,
      y = "Count"
    ) +
    theme_minimal()

  ggplot(df, aes(y = .data[[col_name]])) +
    geom_boxplot(fill = "slateblue", color = "black", width = 0.4) +
    labs(
      title = paste("Box Plot of", col_name),
      y = col_name
    ) +
    theme_minimal()
} else {
  message("Update csv_file in validation_graphs.R before running this script.")
}
