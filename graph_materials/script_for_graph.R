library(ggplot2)

df <- read.csv("order_value.csv", header = FALSE)  # no header in file
colnames(df) <- c("order_value")                   # name it yourself

ggplot(df, aes(x = order_value)) +
  geom_histogram(binwidth = 100, fill = "steelblue", color = "white") +
  scale_x_continuous(
    breaks = seq(0, 10000, by = 500),   # tick every 500
    limits = c(0, 5000)                 # zoom in — most orders are here
  ) +
  labs(
    title = "Distribution of Order Values",
    x = "Order Total Value (BRL)",
    y = "Count"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # readable labels