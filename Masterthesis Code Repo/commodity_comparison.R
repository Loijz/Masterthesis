library(dplyr)
library(kableExtra)

setwd("C:/PATH")

# Calculate comprehensive comparison statistics
commodity_comparison <- dispersion_balanced %>%
  group_by(Indicator) %>%
  summarise(
    N = n(),
    Mean = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    Min = min(Dispersion_CV_Balanced, na.rm = TRUE),
    Q25 = quantile(Dispersion_CV_Balanced, 0.25, na.rm = TRUE),
    Median = median(Dispersion_CV_Balanced, na.rm = TRUE),
    Q75 = quantile(Dispersion_CV_Balanced, 0.75, na.rm = TRUE),
    Max = max(Dispersion_CV_Balanced, na.rm = TRUE),
    Range = Max - Min,
    .groups = "drop"
  )

# T-test for difference in means
gold_cv <- dispersion_balanced %>% filter(Indicator == "Gold") %>% pull(Dispersion_CV_Balanced)
iron_cv <- dispersion_balanced %>% filter(Indicator == "Iron Ore") %>% pull(Dispersion_CV_Balanced)
t_test_commodity <- t.test(iron_cv, gold_cv)

cat("Commodity comparison t-test:\n")
cat("t =", round(t_test_commodity$statistic, 2), ", p =", 
    ifelse(t_test_commodity$p.value < 0.001, "<0.001", round(t_test_commodity$p.value, 3)), "\n")

# Calculate correlation
correlation_data <- dispersion_balanced %>%
  group_by(Period) %>%
  summarise(
    Gold_CV = mean(Dispersion_CV_Balanced[Indicator == "Gold"], na.rm = TRUE),
    Iron_CV = mean(Dispersion_CV_Balanced[Indicator == "Iron Ore"], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(Gold_CV) & !is.na(Iron_CV))

correlation <- cor(correlation_data$Gold_CV, correlation_data$Iron_CV, use = "complete.obs")
cat("Correlation between Gold and Iron Ore dispersion:", round(correlation, 3), "\n")


table_9_2 <- commodity_comparison %>%
  kbl(digits = 2,
      caption = "Table: Commodity Comparison - Dispersion Statistics",
      col.names = c("Commodity", "N", "Mean", "SD", "Min", "Q1", "Median", "Q3", "Max", "Range"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", rep("r", 9))) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(commodity_comparison), background = "#FFFFFF") %>%
  add_header_above(c(" " = 2, "Coefficient of Variation (%)" = 8),
                   background = "#FFFFFF") %>%
  footnote(general = paste0("T-test for difference in means: t = ", round(t_test_commodity$statistic, 2),
                            ", p < 0.001. Iron ore exhibits significantly higher dispersion than gold. ",
                            "Correlation between commodities: ρ = ", round(correlation, 2), ". ",
                            "Balanced panel of top 6 forecasters per commodity."),
           footnote_as_chunk = TRUE)


table_9_2

table_9_2 %>%
  save_kable("table_9_2_commodity_comparison.png",
             zoom = 3, density = 300)




# Side-by-side boxplot
fig_9_2a <- dispersion_balanced %>%
  ggplot(aes(x = Indicator, y = Dispersion_CV_Balanced, fill = Indicator)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
  scale_fill_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Figure: Distribution of Forecast Dispersion by Commodity",
       subtitle = "Balanced panel (2016-2025)",
       x = "Commodity",
       y = "Coefficient of Variation (%)") +
  theme_classic() +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major.y = element_line(color = "gray90"))

# Violin plot
fig_9_2b <- dispersion_balanced %>%
  ggplot(aes(x = Indicator, y = Dispersion_CV_Balanced, fill = Indicator)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.5, outlier.alpha = 0.5) +
  scale_fill_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Figure: Distribution of Forecast Dispersion by Commodity",
       subtitle = "Violin plot with embedded boxplot",
       x = "Commodity",
       y = "Coefficient of Variation (%)") +
  theme_classic() +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major.y = element_line(color = "gray90"))

# Overlapping density plots
fig_9_2c <- dispersion_balanced %>%
  ggplot(aes(x = Dispersion_CV_Balanced, fill = Indicator)) +
  geom_density(alpha = 0.6) +
  scale_fill_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Figure: Density Distribution of Forecast Dispersion",
       x = "Coefficient of Variation (%)",
       y = "Density",
       fill = "Commodity") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"))

# View options
fig_9_2a
fig_9_2b
fig_9_2c

# Save your preferred version
ggsave("fig_9_2_commodity_comparison.png",
       fig_9_2c,
       width = 8, height = 6, dpi = 300, bg = "white")

