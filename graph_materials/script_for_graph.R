library(ggplot2)

df <- read.csv("day_of_week_for_orders.csv")

ggplot(df, aes(x = X2)) +
  geom_histogram(binwidth = 1, fill = "steelblue", color = "white") +
  labs(title = "Distribution of Orders by Day of Week", x = "Day of Week (1=Sun, 7=Sat)", y = "Frequency") +
  theme_minimal()


data <- read.csv("hour_of_day_orders.csv")

hist(data$X2,
     breaks = 23,
     main   = "Distribution of Orders by Hour of Day",
     xlab   = "Hour of Day (0 = Midnight, 23 = 11PM)",
     ylab   = "Frequency",
     col    = "steelblue",
     border = "white",
     xaxt   = "n")

axis(1, at = 0:23, labels = 0:23)