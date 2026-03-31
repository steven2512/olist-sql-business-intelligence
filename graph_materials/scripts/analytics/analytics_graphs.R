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

# ============================================================
# Q4. New vs Repeat Customer Mix by Month
# ============================================================
# Export your SQL result for the new vs repeat customer mix to:
# graph_materials/csv/new_vs_repeat_customer_mix.csv
#
# Expected columns:
# - month_day
# - proportion_repeating_customers
#
# Notes:
# - proportion_repeating_customers should be stored as a decimal
#   proportion such as 0.35 rather than 35
# - new customer proportion is calculated here as:
#   1 - proportion_repeating_customers

mix_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/new_vs_repeat_customer_mix.csv"

if (file.exists(mix_file)) {
  mix_df <- read.csv(mix_file)
  mix_df$month_day <- as.Date(mix_df$month_day, format = "%Y-%m-%d")
  mix_df <- mix_df[order(mix_df$month_day), ]
  mix_df$new_customer_proportion <- 1 - mix_df$proportion_repeating_customers

  stacked_df <- rbind(
    data.frame(
      month_day = mix_df$month_day,
      customer_type = "New",
      proportion = mix_df$new_customer_proportion
    ),
    data.frame(
      month_day = mix_df$month_day,
      customer_type = "Repeat",
      proportion = mix_df$proportion_repeating_customers
    )
  )

  customer_mix_plot <- ggplot(
    stacked_df,
    aes(x = month_day, y = proportion, fill = customer_type)
  ) +
    geom_col(position = "fill") +
    scale_x_date(
      date_breaks = "2 months",
      date_labels = "%b %Y",
      expand = expansion(mult = c(0.02, 0.04))
    ) +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_manual(values = c("New" = "steelblue", "Repeat" = "darkorange")) +
    labs(
      title = "Monthly New vs Repeat Customer Mix",
      x = "Month",
      y = "Proportion",
      fill = "Customer Type"
    ) +
    base_theme

  print(customer_mix_plot)
} else {
  message("Export the customer mix SQL result to graph_materials/csv/new_vs_repeat_customer_mix.csv before running this section.")
}
