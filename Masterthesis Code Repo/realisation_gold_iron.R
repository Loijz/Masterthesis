setwd("C:/PATH")

library(tidyverse)
library(lubridate)

# gold price chart
gold_plot <- realisation_gold_iron_monthly %>%
  filter(Commodity == "Gold") %>%
  ggplot(aes(x = Date, y = Price)) +
  geom_line(color = "gold3", linewidth = 1.2) +
  labs(
    title = "Gold Realized Prices (2015-2025)",
    subtitle = "Monthly spot prices",
    x = "Date",
    y = "Price (USD per )"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "gray40")
  ) +
  scale_x_datetime(date_breaks = "1 year", date_labels = "%Y")

gold_plot

ggsave("gold_realized_prices.png", 
       plot = gold_plot,
       width = 10, height = 6, dpi = 300)

# iron ore price chart
iron_plot <- realisation_gold_iron_monthly %>%
  filter(Commodity == "Iron Ore") %>%
  ggplot(aes(x = Date, y = Price)) +
  geom_line(color = "darkgrey", linewidth = 1.2) +
  labs(
    title = "Iron Ore Realized Prices (2015-2025)",
    subtitle = "Monthly spot prices",
    x = "Date",
    y = "Price (USD per dry metric ton)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "gray40")
  ) +
  scale_x_datetime(date_breaks = "1 year", date_labels = "%Y")

iron_plot

ggsave("iron_ore_realized_prices.png", 
       plot = iron_plot,
       width = 10, height = 6, dpi = 300)

# Combined plot for comparison
combined_plot <- realisation_gold_iron_monthly %>%
  ggplot(aes(x = Date, y = Price, color = Commodity)) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~Commodity, scales = "free_y", ncol = 1) +
  scale_color_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Realized Commodity Prices (2015-2025)",
    subtitle = "Monthly spot prices - Note: different y-axis scales",
    x = "Date",
    y = "Price"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "none"
  ) +
  scale_x_datetime(date_breaks = "2 years", date_labels = "%Y")

combined_plot

ggsave("combined_realized_prices.png", 
       plot = combined_plot,
       width = 10, height = 8, dpi = 300)