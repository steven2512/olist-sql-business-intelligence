library(ggplot2)

# Update this file path to the CSV you want to visualize from graph_materials/csv.
csv_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/total_items_sellers.csv"

df <- read.csv(csv_file)
col_name <- colnames(df)[1]

cat("Using column:", col_name, "\n")

ggplot(df, aes(x = .data[[col_name]])) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  labs(
    title = paste("Histogram of", col_name),
    x = col_name,
    y = "Count"
  ) +
  theme_minimal()

ggplot(df, aes(y = .data[[col_name]])) +
  geom_boxplot(fill = "steelblue", color = "black", width = 0.4) +
  labs(
    title = paste("Box Plot of", col_name),
    y = col_name
  ) +
  theme_minimal()
