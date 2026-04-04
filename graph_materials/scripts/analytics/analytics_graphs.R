library(ggplot2)

base_theme <- theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold")
  )

print_side_by_side <- function(left_plot, right_plot, widths = c(3, 1)) {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(
    nrow = 1,
    ncol = 2,
    widths = grid::unit(widths, "null")
  )))
  print(left_plot, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(right_plot, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
}

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

# ============================================================
# Q5. Revenue Concentration Across Customers, Sellers, and Products
# ============================================================
# Export the SQL summary result for the concentration chart to:
# graph_materials/csv/revenue_concentration_summary.csv
#
# Expected columns:
# - entity_type
# - top_5_prop
# - top_10_prop
# - top_20_prop
#
# Notes:
# - each proportion should be stored as a decimal such as 0.27
# - this section plots cumulative revenue share captured by top contributors

concentration_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/revenue_concentration_summary.csv"

if (file.exists(concentration_file)) {
  concentration_df <- read.csv(concentration_file)

  concentration_plot_df <- rbind(
    data.frame(
      entity_type = concentration_df$entity_type,
      top_n_group = "Top 5%",
      revenue_share = concentration_df$top_5_prop
    ),
    data.frame(
      entity_type = concentration_df$entity_type,
      top_n_group = "Top 10%",
      revenue_share = concentration_df$top_10_prop
    ),
    data.frame(
      entity_type = concentration_df$entity_type,
      top_n_group = "Top 20%",
      revenue_share = concentration_df$top_20_prop
    )
  )

  concentration_plot_df$entity_type <- factor(
    concentration_plot_df$entity_type,
    levels = c("Customers", "Sellers", "Products")
  )

  concentration_plot_df$top_n_group <- factor(
    concentration_plot_df$top_n_group,
    levels = c("Top 5%", "Top 10%", "Top 20%")
  )

  concentration_theme <- theme_minimal() +
    theme(
      axis.text.x = element_text(face = "bold"),
      plot.title = element_text(face = "bold"),
      legend.title = element_text(face = "bold"),
      legend.position = "top"
    )

  concentration_plot <- ggplot(
    concentration_plot_df,
    aes(x = top_n_group, y = revenue_share, color = entity_type, group = entity_type)
  ) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 3) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray60") +
    scale_y_continuous(labels = scales::percent) +
    scale_color_manual(
      values = c(
        "Customers" = "steelblue",
        "Sellers" = "firebrick",
        "Products" = "darkgreen"
      )
    ) +
    labs(
      title = "Top-N Revenue Contribution by Entity Type",
      x = "Top Contributor Group",
      y = "Cumulative Revenue Share",
      color = "Entity Type"
    ) +
    concentration_theme

  print(concentration_plot)
} else {
  message("Export the concentration SQL result to graph_materials/csv/revenue_concentration_summary.csv before running this section.")
}

# ============================================================
# 02 Customer Behaviour
# ============================================================

# Q1. How many orders does a typical customer place?
customer_orders_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/customer_orders_distribution.csv"

if (file.exists(customer_orders_file)) {
  customer_orders_df <- read.csv(customer_orders_file)

  customer_orders_plot <- ggplot(customer_orders_df, aes(x = total_orders)) +
    geom_histogram(binwidth = 1, fill = "steelblue", color = "white", boundary = 0.5) +
    scale_x_continuous(breaks = seq(1, max(customer_orders_df$total_orders), by = 1)) +
    labs(
      title = "Customer Order Count Distribution",
      x = "Delivered Orders per Customer",
      y = "Number of Customers"
    ) +
    base_theme

  customer_orders_boxplot <- ggplot(customer_orders_df, aes(y = total_orders)) +
    geom_boxplot(fill = "steelblue", alpha = 0.8, outlier.color = "firebrick") +
    labs(
      title = "Boxplot",
      x = NULL,
      y = "Delivered Orders per Customer"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      plot.title = element_text(face = "bold", hjust = 0.5)
    )

  print_side_by_side(customer_orders_plot, customer_orders_boxplot)
} else {
  message("Export the customer order distribution SQL result to graph_materials/csv/customer_orders_distribution.csv before running this section.")
}

# Q2. What share of customers purchase only once versus more than once?
customer_share_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/customer_repeat_share.csv"

if (file.exists(customer_share_file)) {
  customer_share_df <- read.csv(customer_share_file)
  customer_share_df$group_label <- "Customers"
  customer_share_df$customer_type <- factor(
    customer_share_df$customer_type,
    levels = c("One-time", "Repeat")
  )

  customer_share_plot <- ggplot(
    customer_share_df,
    aes(x = group_label, y = customer_proportion, fill = customer_type)
  ) +
    geom_col(position = "fill", width = 0.6) +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_manual(values = c("One-time" = "steelblue", "Repeat" = "darkorange")) +
    labs(
      title = "Customer Share: One-time vs Repeat",
      x = NULL,
      y = "Proportion of Customers",
      fill = "Customer Type"
    ) +
    base_theme +
    theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

  print(customer_share_plot)
} else {
  message("Export the customer share SQL result to graph_materials/csv/customer_repeat_share.csv before running this section.")
}

# Q3. How long does it typically take for a customer to place a second order?
second_order_gap_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/second_order_gap_days.csv"

if (file.exists(second_order_gap_file)) {
  second_order_gap_df <- read.csv(second_order_gap_file)

  second_order_gap_plot <- ggplot(second_order_gap_df, aes(x = days_to_second_order)) +
    geom_histogram(binwidth = 10, fill = "darkgreen", color = "white", boundary = 0) +
    labs(
      title = "Days Until Second Order",
      x = "Days Between First and Second Delivered Order",
      y = "Number of Customers"
    ) +
    base_theme

  second_order_gap_boxplot <- ggplot(second_order_gap_df, aes(y = days_to_second_order)) +
    geom_boxplot(fill = "darkgreen", alpha = 0.8, outlier.color = "firebrick") +
    labs(
      title = "Boxplot",
      x = NULL,
      y = "Days Between First and Second Delivered Order"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      plot.title = element_text(face = "bold", hjust = 0.5)
    )

  print_side_by_side(second_order_gap_plot, second_order_gap_boxplot)
} else {
  message("Export the second-order gap SQL result to graph_materials/csv/second_order_gap_days.csv before running this section.")
}

# Q4. Do repeat customers spend more per order than one-time customers?
order_value_comparison_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/repeat_vs_one_time_order_value.csv"

if (file.exists(order_value_comparison_file)) {
  order_value_comparison_df <- read.csv(order_value_comparison_file)
  order_value_comparison_df$customer_type <- factor(
    order_value_comparison_df$customer_type,
    levels = c("One-time", "Repeat")
  )

  order_value_comparison_plot <- ggplot(
    order_value_comparison_df,
    aes(x = customer_type, y = avg_order_value, fill = customer_type)
  ) +
    geom_col(width = 0.6, show.legend = FALSE) +
    scale_fill_manual(values = c("One-time" = "steelblue", "Repeat" = "darkorange")) +
    labs(
      title = "Average Order Value: One-time vs Repeat Customers",
      x = "Customer Type",
      y = "Average Order Value"
    ) +
    base_theme

  print(order_value_comparison_plot)
} else {
  message("Export the order value comparison SQL result to graph_materials/csv/repeat_vs_one_time_order_value.csv before running this section.")
}

# Q5. Do repeat customers buy more items per order than one-time customers?
items_comparison_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/repeat_vs_one_time_items.csv"

if (file.exists(items_comparison_file)) {
  items_comparison_df <- read.csv(items_comparison_file)
  items_comparison_df$customer_type <- factor(
    items_comparison_df$customer_type,
    levels = c("One-time", "Repeat")
  )

  items_comparison_plot <- ggplot(
    items_comparison_df,
    aes(x = customer_type, y = avg_items_per_order, fill = customer_type)
  ) +
    geom_col(width = 0.6, show.legend = FALSE) +
    scale_fill_manual(values = c("One-time" = "steelblue", "Repeat" = "darkorange")) +
    labs(
      title = "Average Items per Order: One-time vs Repeat Customers",
      x = "Customer Type",
      y = "Average Items per Order"
    ) +
    base_theme

  print(items_comparison_plot)
} else {
  message("Export the items comparison SQL result to graph_materials/csv/repeat_vs_one_time_items.csv before running this section.")
}

# ============================================================
# 03 RFM Analysis
# ============================================================

rfm_segment_file <- "D:/Data Engineering/olist-sql-business-intelligence/graph_materials/csv/rfm_segment_summary.csv"

if (file.exists(rfm_segment_file)) {
  rfm_df <- read.csv(rfm_segment_file)

  segment_levels <- c(
    "Champions",
    "Loyalists",
    "Potential / New",
    "Needs Attention",
    "At Risk",
    "Hibernating"
  )

  segment_colors <- c(
    "Champions" = "#1b9e77",
    "Loyalists" = "#66a61e",
    "Potential / New" = "#7570b3",
    "Needs Attention" = "#e6ab02",
    "At Risk" = "#d95f02",
    "Hibernating" = "#b22222"
  )

  rfm_df$segment <- factor(rfm_df$segment, levels = segment_levels)
  rfm_df <- rfm_df[order(rfm_df$segment), ]

  rfm_customer_plot <- ggplot(rfm_df, aes(x = segment, y = total_customers, fill = segment)) +
    geom_col(width = 0.7, show.legend = FALSE) +
    scale_fill_manual(values = segment_colors) +
    labs(
      title = "Customer Count by RFM Segment",
      x = "RFM Segment",
      y = "Total Customers"
    ) +
    base_theme

  rfm_revenue_plot <- ggplot(rfm_df, aes(x = segment, y = total_revenue, fill = segment)) +
    geom_col(width = 0.7, show.legend = FALSE) +
    scale_fill_manual(values = segment_colors) +
    labs(
      title = "Revenue by RFM Segment",
      x = "RFM Segment",
      y = "Total Revenue"
    ) +
    base_theme

  rfm_avg_revenue_plot <- ggplot(rfm_df, aes(x = segment, y = avg_revenue, fill = segment)) +
    geom_col(width = 0.7, show.legend = FALSE) +
    scale_fill_manual(values = segment_colors) +
    labs(
      title = "Average Revenue per Customer by RFM Segment",
      x = "RFM Segment",
      y = "Average Revenue per Customer"
    ) +
    base_theme

  rfm_share_df <- rbind(
    data.frame(
      segment = rfm_df$segment,
      metric_type = "Customer Share",
      share = rfm_df$cust_prop
    ),
    data.frame(
      segment = rfm_df$segment,
      metric_type = "Order Share",
      share = rfm_df$orders_prop
    ),
    data.frame(
      segment = rfm_df$segment,
      metric_type = "Revenue Share",
      share = rfm_df$rev_prop
    )
  )

  rfm_share_df$metric_type <- factor(
    rfm_share_df$metric_type,
    levels = c("Customer Share", "Order Share", "Revenue Share")
  )

  rfm_share_plot <- ggplot(
    rfm_share_df,
    aes(x = metric_type, y = share, fill = segment)
  ) +
    geom_col(position = "fill", width = 0.7) +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_manual(values = segment_colors) +
    labs(
      title = "Customer, Order, and Revenue Share by RFM Segment",
      x = NULL,
      y = "Proportion",
      fill = "RFM Segment"
    ) +
    base_theme +
    theme(
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      legend.position = "top"
    )

  print(rfm_customer_plot)
  print(rfm_revenue_plot)
  print(rfm_avg_revenue_plot)
  print(rfm_share_plot)
} else {
  message("Export the RFM segment summary SQL result to graph_materials/csv/rfm_segment_summary.csv before running this section.")
}
