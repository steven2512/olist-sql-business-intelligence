library(ggplot2)

# Export your SQL result for Q1 to graph_materials/csv and point this path to it.
# Expected columns:
# - month_year
# - total_orders
# - month_revenue
# - month_average_order_value
csv_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/business_performance_q1.csv"

if (file.exists(csv_file)) {
  df <- read.csv(csv_file)
  df$month_year <- as.Date(df$month_year, format = "%Y-%m-%d")
  df <- df[order(df$month_year), ]

  base_theme <- theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(face = "bold")
    )

  orders_plot <- ggplot(df, aes(x = month_year, y = total_orders)) +
    geom_line(color = "steelblue", linewidth = 1.1) +
    scale_x_date(
      date_breaks = "2 months",
      date_labels = "%b %Y",
      expand = expansion(mult = c(0.02, 0.04))
    ) +
    labs(
      title = "Monthly Orders Over Time",
      x = "Month",
      y = "Total Orders"
    ) +
    base_theme

  revenue_plot <- ggplot(df, aes(x = month_year, y = month_revenue)) +
    geom_line(color = "darkgreen", linewidth = 1.1) +
    scale_x_date(
      date_breaks = "2 months",
      date_labels = "%b %Y",
      expand = expansion(mult = c(0.02, 0.04))
    ) +
    labs(
      title = "Monthly Revenue Over Time",
      x = "Month",
      y = "Revenue"
    ) +
    base_theme

  aov_plot <- ggplot(df, aes(x = month_year, y = month_average_order_value)) +
    geom_line(color = "firebrick", linewidth = 1.1) +
    scale_x_date(
      date_breaks = "2 months",
      date_labels = "%b %Y",
      expand = expansion(mult = c(0.02, 0.04))
    ) +
    labs(
      title = "Monthly Average Order Value Over Time",
      x = "Month",
      y = "Average Order Value"
    ) +
    base_theme

  print(orders_plot)
  print(revenue_plot)
  print(aov_plot)
} else {
  message("Export the Q1 SQL result to graph_materials/csv/business_performance_q1.csv before running this script.")
}
