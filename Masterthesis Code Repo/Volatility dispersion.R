library(ggplot2)
library(dplyr)
library(kableExtra)

setwd("C:/PATH")

# Volatility vs Dispersion scatter
fig_9_7_3a <- base_data %>%
  ggplot(aes(x = Rolling_Volatility_3m, y = Dispersion_CV_Balanced, color = Indicator)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  facet_wrap(~Indicator, ncol = 1, scales = "free") +
  labs(title = "Figure: Market Volatility vs. Forecast Dispersion",
       subtitle = "Iron Ore: positive relationship; Gold: negative relationship (2016-2025)",
       x = "Rolling Volatility (3-month, %)",
       y = "Dispersion (CV %)",
       color = "Commodity") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"),
        strip.background = element_rect(fill = "gray95"))

fig_9_7_3a

ggsave("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/fig_9_7_3a_volatility_dispersion.png",
       fig_9_7_3a, width = 10, height = 8, dpi = 300, bg = "white")

# Gold only: Pre vs Post 2022
fig_9_7_3b <- base_data %>%
  filter(Indicator == "Gold") %>%
  mutate(Period_Group = ifelse(year(Period) < 2022, "Pre-2022 (2016-2021)", "Post-2022 (2022-2025)")) %>%
  ggplot(aes(x = Rolling_Volatility_3m, y = Dispersion_CV_Balanced, color = Period_Group)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Pre-2022 (2016-2021)" = "steelblue", 
                                "Post-2022 (2022-2025)" = "coral")) +
  labs(title = "Figure: Gold Volatility-Dispersion Relationship Over Time",
       subtitle = "Negative relationship weakens substantially post-2022",
       x = "Rolling Volatility (3-month, %)",
       y = "Dispersion (CV %)",
       color = "Period") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"))

fig_9_7_3b

ggsave("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/fig_9_7_3b_gold_volatility_temporal.png",
       fig_9_7_3b, width = 10, height = 6, dpi = 300, bg = "white")




# Create volatility quintiles for Gold
table_9_7_3_data <- base_data %>%
  filter(Indicator == "Gold") %>%
  mutate(
    Volatility_Quintile = ntile(Rolling_Volatility_3m, 5),
    Volatility_Group = case_when(
      Volatility_Quintile == 1 ~ "Q1 (Lowest)",
      Volatility_Quintile == 2 ~ "Q2",
      Volatility_Quintile == 3 ~ "Q3",
      Volatility_Quintile == 4 ~ "Q4",
      Volatility_Quintile == 5 ~ "Q5 (Highest)"
    )
  ) %>%
  group_by(Volatility_Group) %>%
  summarise(
    Mean_Volatility = mean(Rolling_Volatility_3m, na.rm = TRUE),
    Mean_Dispersion = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD_Dispersion = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

# Create formatted table
table_9_7_3 <- table_9_7_3_data %>%
  kbl(digits = 2,
      caption = "Table: Gold Dispersion by Volatility Quintile",
      col.names = c("Volatility Quintile", "Mean Volatility (%)", "Mean Dispersion (CV %)", "SD", "N"),
      booktabs = TRUE,
      align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_9_7_3_data), background = "#FFFFFF") %>%
  add_footnote("Note: Volatility quintiles based on 3-month rolling standard deviation of gold price returns. Dispersion decreases monotonically from lowest to highest volatility quintile, confirming negative relationship. This pattern reflects safe-haven convergence during volatile periods, though effect weakened substantially post-2022.",
               notation = "none")

table_9_7_3

table_9_7_3 %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_9_7_3_volatility_quintiles.png",
             zoom = 3, density = 300)



# Iron Ore: Pre vs Post 2022
fig_9_7_3c <- base_data %>%
  filter(Indicator == "Iron Ore") %>%
  mutate(Period_Group = ifelse(year(Period) < 2022, "Pre-2022 (2016-2021)", "Post-2022 (2022-2025)")) %>%
  ggplot(aes(x = Rolling_Volatility_3m, y = Dispersion_CV_Balanced, color = Period_Group)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Pre-2022 (2016-2021)" = "steelblue", 
                                "Post-2022 (2022-2025)" = "coral")) +
  labs(title = "Figure: Iron Ore Volatility-Dispersion Relationship Over Time",
       subtitle = "Positive relationship weakens substantially post-2022",
       x = "Rolling Volatility (3-month, %)",
       y = "Dispersion (CV %)",
       color = "Period") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"))

fig_9_7_3c

ggsave("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/fig_9_7_3c_iron_volatility_temporal.png",
       fig_9_7_3c, width = 10, height = 6, dpi = 300, bg = "white")


# Create volatility quintiles for Iron Ore
table_9_7_4_data <- base_data %>%
  filter(Indicator == "Iron Ore") %>%
  mutate(
    Volatility_Quintile = ntile(Rolling_Volatility_3m, 5),
    Volatility_Group = case_when(
      Volatility_Quintile == 1 ~ "Q1 (Lowest)",
      Volatility_Quintile == 2 ~ "Q2",
      Volatility_Quintile == 3 ~ "Q3",
      Volatility_Quintile == 4 ~ "Q4",
      Volatility_Quintile == 5 ~ "Q5 (Highest)"
    )
  ) %>%
  group_by(Volatility_Group) %>%
  summarise(
    Mean_Volatility = mean(Rolling_Volatility_3m, na.rm = TRUE),
    Mean_Dispersion = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD_Dispersion = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

# Create formatted table
table_9_7_4 <- table_9_7_4_data %>%
  kbl(digits = 2,
      caption = "Table: Iron Ore Dispersion by Volatility Quintile",
      col.names = c("Volatility Quintile", "Mean Volatility (%)", "Mean Dispersion (CV %)", "SD", "N"),
      booktabs = TRUE,
      align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_9_7_4_data), background = "#FFFFFF") %>%
  add_footnote("Note: Volatility quintiles based on 3-month rolling standard deviation of iron ore price returns. Dispersion shows positive relationship with volatility pre-2022, consistent with industrial commodity uncertainty during supply-demand imbalances. However, this relationship collapsed post-2022 when traditional forecasting relationships broke down.",
               notation = "none")

table_9_7_4

table_9_7_4 %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_9_7_4_iron_volatility_quintiles.png",
             zoom = 3, density = 300)

# Optional: Print summary statistics for comparison
cat("\n=== IRON ORE VOLATILITY-DISPERSION CORRELATION ===\n")
base_data %>%
  filter(Indicator == "Iron Ore") %>%
  summarise(
    Overall = cor(Rolling_Volatility_3m, Dispersion_CV_Balanced, use = "complete.obs"),
    Pre_2022 = cor(Rolling_Volatility_3m[year(Period) < 2022], 
                   Dispersion_CV_Balanced[year(Period) < 2022], 
                   use = "complete.obs"),
    Post_2022 = cor(Rolling_Volatility_3m[year(Period) >= 2022], 
                    Dispersion_CV_Balanced[year(Period) >= 2022], 
                    use = "complete.obs")
  ) %>%
  print()




################## volatility analysis ####################




# Function to calculate correlation with confidence
cor_with_ci <- function(x, y) {
  test <- cor.test(x, y, method = "pearson")
  return(list(
    cor = test$estimate,
    p_value = test$p.value,
    ci_lower = test$conf.int[1],
    ci_upper = test$conf.int[2]
  ))
}

# Calculate correlations for all groups
correlation_analysis <- data.frame(
  Dataset = character(),
  Period = character(),
  Correlation = numeric(),
  P_value = numeric(),
  N = numeric(),
  stringsAsFactors = FALSE
)

# Overall (Both Commodities)
overall_pre <- base_data %>% filter(year(Period) < 2022)
overall_post <- base_data %>% filter(year(Period) >= 2022)

correlation_analysis <- rbind(correlation_analysis,
                              data.frame(
                                Dataset = "Overall (Both)",
                                Period = "Overall",
                                Correlation = cor(base_data$Rolling_Volatility_3m, base_data$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(base_data$Rolling_Volatility_3m, base_data$Dispersion_CV_Balanced)$p.value,
                                N = nrow(base_data)
                              ),
                              data.frame(
                                Dataset = "Overall (Both)",
                                Period = "Pre-2022",
                                Correlation = cor(overall_pre$Rolling_Volatility_3m, overall_pre$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(overall_pre$Rolling_Volatility_3m, overall_pre$Dispersion_CV_Balanced)$p.value,
                                N = nrow(overall_pre)
                              ),
                              data.frame(
                                Dataset = "Overall (Both)",
                                Period = "Post-2022",
                                Correlation = cor(overall_post$Rolling_Volatility_3m, overall_post$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(overall_post$Rolling_Volatility_3m, overall_post$Dispersion_CV_Balanced)$p.value,
                                N = nrow(overall_post)
                              )
)

# Gold
gold_data <- base_data %>% filter(Indicator == "Gold")
gold_pre <- gold_data %>% filter(year(Period) < 2022)
gold_post <- gold_data %>% filter(year(Period) >= 2022)

correlation_analysis <- rbind(correlation_analysis,
                              data.frame(
                                Dataset = "Gold",
                                Period = "Overall",
                                Correlation = cor(gold_data$Rolling_Volatility_3m, gold_data$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(gold_data$Rolling_Volatility_3m, gold_data$Dispersion_CV_Balanced)$p.value,
                                N = nrow(gold_data)
                              ),
                              data.frame(
                                Dataset = "Gold",
                                Period = "Pre-2022",
                                Correlation = cor(gold_pre$Rolling_Volatility_3m, gold_pre$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(gold_pre$Rolling_Volatility_3m, gold_pre$Dispersion_CV_Balanced)$p.value,
                                N = nrow(gold_pre)
                              ),
                              data.frame(
                                Dataset = "Gold",
                                Period = "Post-2022",
                                Correlation = cor(gold_post$Rolling_Volatility_3m, gold_post$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(gold_post$Rolling_Volatility_3m, gold_post$Dispersion_CV_Balanced)$p.value,
                                N = nrow(gold_post)
                              )
)

# Iron Ore
iron_data <- base_data %>% filter(Indicator == "Iron Ore")
iron_pre <- iron_data %>% filter(year(Period) < 2022)
iron_post <- iron_data %>% filter(year(Period) >= 2022)

correlation_analysis <- rbind(correlation_analysis,
                              data.frame(
                                Dataset = "Iron Ore",
                                Period = "Overall",
                                Correlation = cor(iron_data$Rolling_Volatility_3m, iron_data$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(iron_data$Rolling_Volatility_3m, iron_data$Dispersion_CV_Balanced)$p.value,
                                N = nrow(iron_data)
                              ),
                              data.frame(
                                Dataset = "Iron Ore",
                                Period = "Pre-2022",
                                Correlation = cor(iron_pre$Rolling_Volatility_3m, iron_pre$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(iron_pre$Rolling_Volatility_3m, iron_pre$Dispersion_CV_Balanced)$p.value,
                                N = nrow(iron_pre)
                              ),
                              data.frame(
                                Dataset = "Iron Ore",
                                Period = "Post-2022",
                                Correlation = cor(iron_post$Rolling_Volatility_3m, iron_post$Dispersion_CV_Balanced, use = "complete.obs"),
                                P_value = cor.test(iron_post$Rolling_Volatility_3m, iron_post$Dispersion_CV_Balanced)$p.value,
                                N = nrow(iron_post)
                              )
)

# Calculate change from pre to post
change_summary <- correlation_analysis %>%
  filter(Period != "Overall") %>%
  select(Dataset, Period, Correlation, N) %>%
  tidyr::pivot_wider(names_from = Period, values_from = c(Correlation, N)) %>%
  mutate(
    Change = `Correlation_Post-2022` - `Correlation_Pre-2022`,
    Pct_Change = (Change / abs(`Correlation_Pre-2022`)) * 100
  )

# Fisher's Z transformation test for correlation difference
# Function to test if two correlations are significantly different
test_cor_difference <- function(r1, n1, r2, n2) {
  # Fisher Z transformation
  z1 <- 0.5 * log((1 + r1) / (1 - r1))
  z2 <- 0.5 * log((1 + r2) / (1 - r2))
  
  # Standard error of difference
  se_diff <- sqrt(1/(n1 - 3) + 1/(n2 - 3))
  
  # Z statistic
  z_stat <- (z1 - z2) / se_diff
  
  # P-value (two-tailed)
  p_value <- 2 * (1 - pnorm(abs(z_stat)))
  
  return(data.frame(z_statistic = z_stat, p_value = p_value))
}

# Test for each dataset
test_results <- data.frame(
  Dataset = c("Overall (Both)", "Gold", "Iron Ore"),
  stringsAsFactors = FALSE
)

for(i in 1:3) {
  dataset_name <- test_results$Dataset[i]
  
  pre_data <- correlation_analysis %>% filter(Dataset == dataset_name, Period == "Pre-2022")
  post_data <- correlation_analysis %>% filter(Dataset == dataset_name, Period == "Post-2022")
  
  test <- test_cor_difference(
    pre_data$Correlation, pre_data$N,
    post_data$Correlation, post_data$N
  )
  
  test_results$Z_statistic[i] <- test$z_statistic
  test_results$P_value[i] <- test$p_value
}

# Combine everything into final table
final_table <- change_summary %>%
  left_join(test_results, by = "Dataset") %>%
  select(Dataset, 
         `Correlation_Pre-2022`, `N_Pre-2022`,
         `Correlation_Post-2022`, `N_Post-2022`,
         Change, Z_statistic, P_value)

# Print results
cat("\n=== VOLATILITY-DISPERSION CORRELATIONS ===\n\n")
print(correlation_analysis %>% 
        mutate(across(where(is.numeric), ~round(., 3))))

cat("\n\n=== CHANGE FROM PRE TO POST-2022 ===\n\n")
print(final_table %>% 
        mutate(across(where(is.numeric), ~round(., 3))))


table_volatility_correlation <- final_table %>%
  mutate(
    Sig = case_when(
      P_value < 0.001 ~ "***",
      P_value < 0.01 ~ "**",
      P_value < 0.05 ~ "*",
      P_value < 0.1 ~ ".",
      TRUE ~ ""
    ),
    Change_Sig = paste0(sprintf("%.3f", Change), Sig)
  ) %>%
  select(Dataset, 
         `Correlation_Pre-2022`, `N_Pre-2022`,
         `Correlation_Post-2022`, `N_Post-2022`,
         Change_Sig, Z_statistic, P_value) %>%
  kbl(digits = 3,
      caption = "Table: Volatility-Dispersion Correlation Change (Pre vs Post-2022)",
      col.names = c("Dataset", "Correlation", "N", "Correlation", "N", 
                    "Change", "Z-stat", "p-value"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", "r", "r", "r", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(final_table), background = "#FFFFFF") %>%
  add_header_above(c(" " = 1, "Pre-2022 (2016-2021)" = 2, "Post-2022 (2022-2025)" = 2, 
                     "Test of Difference" = 3),
                   background = "#FFFFFF") %>%
  footnote(general = "*** p < 0.001, ** p < 0.01, * p < 0.05, . p < 0.1. Fisher's Z transformation test for difference between correlations. Negative correlations for gold indicate safe-haven convergence (higher volatility → lower dispersion). Positive correlations for iron ore indicate uncertainty effect (higher volatility → higher dispersion).")

table_volatility_correlation

table_volatility_correlation %>%
  save_kable("table_volatility_correlation_change.png",
             zoom = 3, density = 300)
