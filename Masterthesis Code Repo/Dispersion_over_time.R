library(ggplot2)
library(dplyr)
library(kableExtra)



setwd("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots")




dispersion_balanced <- model_data_balanced %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  summarise(
    Dispersion_CV_Balanced = sd(Value, na.rm = TRUE) / mean(Value, na.rm = TRUE) * 100,
    N_Forecasters_Balanced = n_distinct(Source),
    Mean_Forecast = mean(Value, na.rm = TRUE),
    .groups = "drop"
  )

# Dispersion over time 
fig_9_1 <- dispersion_balanced %>%
  ggplot(aes(x = Period, y = Dispersion_CV_Balanced, color = Indicator)) +
  geom_line(linewidth = 1, alpha = 0.6) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 1.2, alpha = 0.2) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Figure: Forecast Dispersion Over Time",
       subtitle = "Coefficient of variation (%) with LOESS smoothing",
       x = "Target Period",
       y = "Dispersion (CV %)",
       color = "Commodity") +
  theme_classic() +  
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"),  # Light gridlines
        panel.grid.minor = element_blank())


fig_9_1


ggsave("fig_9_1_dispersion_trends.png",
       fig_9_1, width = 10, height = 6, dpi = 300, bg = "white")


# Aggregate to one observation per Period-Indicator
dispersion_smoothed <- dispersion_balanced %>%
  group_by(Period, Indicator) %>%
  summarise(
    Dispersion_CV = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    .groups = "drop"
  )


fig_9_1_smooth <- dispersion_smoothed %>%
  ggplot(aes(x = Period, y = Dispersion_CV, color = Indicator)) +
  geom_line(linewidth = 1.2) +
  geom_smooth(method = "loess", span = 0.5, se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Figure: Forecast Dispersion Over Time",
       subtitle = "Coefficient of variation (%) averaged across forecast horizons",
       x = "Target Period",
       y = "Dispersion (CV %)",
       color = "Commodity") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"),
        panel.grid.minor = element_blank())

fig_9_1_smooth

ggsave("fig_9_1_dispersion_trends_smooth.png",
       fig_9_1_smooth, width = 10, height = 6, dpi = 300, bg = "white")

#Smoothing
fig_9_1_loess_3 <- dispersion_balanced %>%
  ggplot(aes(x = Period, y = Dispersion_CV_Balanced, color = Indicator)) +
  geom_line(linewidth = 1, alpha = 0.6) +
  geom_smooth(method = "loess", 
              span = 0.3,  # Smaller = less smooth (default is 0.75)
              se = TRUE, 
              linewidth = 1.2, 
              alpha = 0.2) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Figure 9.1: Forecast Dispersion Over Time",
       subtitle = "Coefficient of variation (%) with LOESS smoothing (span = 0.3)",
       x = "Target Period",
       y = "Dispersion (CV %)",
       color = "Commodity") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"),
        panel.grid.minor = element_blank())

ggsave("fig_9_1_dispersion_trends_smooth_03.png",
       fig_9_1_loess_3, width = 10, height = 6, dpi = 300, bg = "white")




# statistics by period
table_9_1_data <- dispersion_balanced %>%
  mutate(
    Year = year(Period),
    Period_Group = ifelse(Year < 2022, "Pre-2022 (2015-2021)", "Post-2022 (2022-2025)")
  ) %>%
  group_by(Indicator, Period_Group) %>%
  summarise(
    N = n(),
    Mean = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    Min = min(Dispersion_CV_Balanced, na.rm = TRUE),
    Max = max(Dispersion_CV_Balanced, na.rm = TRUE),
    .groups = "drop"
  )

# T-tests for significance
gold_pre <- dispersion_balanced %>% 
  filter(Indicator == "Gold", year(Period) < 2022) %>% 
  pull(Dispersion_CV_Balanced)

gold_post <- dispersion_balanced %>% 
  filter(Indicator == "Gold", year(Period) >= 2022) %>% 
  pull(Dispersion_CV_Balanced)

iron_pre <- dispersion_balanced %>% 
  filter(Indicator == "Iron Ore", year(Period) < 2022) %>% 
  pull(Dispersion_CV_Balanced)

iron_post <- dispersion_balanced %>% 
  filter(Indicator == "Iron Ore", year(Period) >= 2022) %>% 
  pull(Dispersion_CV_Balanced)

t_test_gold <- t.test(gold_post, gold_pre)
t_test_iron <- t.test(iron_post, iron_pre)

cat("Gold pre vs post: t =", round(t_test_gold$statistic, 2), 
    ", p =", round(t_test_gold$p.value, 3), "\n")
cat("Iron Ore pre vs post: t =", round(t_test_iron$statistic, 2), 
    ", p =", round(t_test_iron$p.value, 3), "\n")


table_9_1 <- table_9_1_data %>%
  kbl(digits = 2,
      caption = "Table: Dispersion Summary Statistics by Period",
      col.names = c("Commodity", "Period", "N", "Mean", "SD", "Min", "Max"),
      booktabs = TRUE) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE) %>%
  pack_rows("Gold", 1, 2) %>%
  pack_rows("Iron Ore", 3, 4) %>%
  footnote(general = "Dispersion measured as coefficient of variation (%). T-tests for difference in means: Gold (t=3.45, p<0.01), Iron Ore (t=1.62, p=0.11).",
           general_title = "Note:",
           footnote_as_chunk = TRUE)


table_9_1 %>%
  save_kable("table_9_1_period_summary.png",
             zoom = 3, density = 300)




####YEAR BY YEAR BREAKDOWN####
# More detailed: year-by-year
summary_by_year <- dispersion_balanced %>%
  mutate(Year = year(Period)) %>%
  group_by(Indicator, Year) %>%
  summarise(
    N_obs = n(),
    Mean_CV = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    Min_CV = min(Dispersion_CV_Balanced, na.rm = TRUE),
    Max_CV = max(Dispersion_CV_Balanced, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(Indicator, Year)

# View
print(summary_by_year)

# side-by-side comparison
summary_wide <- summary_by_year %>%
  select(Indicator, Year, Mean_CV, Max_CV) %>%
  pivot_wider(
    names_from = Indicator,
    values_from = c(Mean_CV, Max_CV),
    names_sep = "_"
  )

print(summary_wide)

table_yearly <- summary_wide %>%
  kbl(digits = 2,
      caption = "Table: Annual Dispersion Statistics (Balanced Panel)",
      col.names = c("Year", "Mean", "Max", "Mean", "Max"),
      booktabs = TRUE,
      align = c("c", "r", "r", "r", "r"),
      escape = FALSE) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%  # Pure white header
  row_spec(1:nrow(summary_wide), background = "#FFFFFF") %>%  # Pure white rows
  add_header_above(c(" " = 1, "Gold (CV %)" = 2, "Iron Ore (CV %)" = 2),
                   background = "#FFFFFF") %>%  # Pure white
  footnote(general = "Annual averages across all period-publication quarter combinations. Balanced panel includes top 6 forecasters per commodity.",
           general_title = "Note:",
           footnote_as_chunk = TRUE)

table_yearly


table_yearly %>%
  save_kable("table_9_X_annual_summary.png",
             zoom = 3, density = 300)



# Calculate pre/post 2022 statistics
pre_post_comparison <- dispersion_balanced %>%
  mutate(
    Year = year(Period),
    Period_Group = ifelse(Year < 2022, "Pre-2022 (2016-2021)", "Post-2022 (2022-2025)")
  ) %>%
  group_by(Indicator, Period_Group) %>%
  summarise(
    N = n(),
    Mean_CV = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD_CV = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    Min_CV = min(Dispersion_CV_Balanced, na.rm = TRUE),
    Max_CV = max(Dispersion_CV_Balanced, na.rm = TRUE),
    .groups = "drop"
  )

# View
print(pre_post_comparison)

# Calculate t-tests
gold_pre <- dispersion_balanced %>% 
  filter(Indicator == "Gold", year(Period) < 2022) %>% 
  pull(Dispersion_CV_Balanced)

gold_post <- dispersion_balanced %>% 
  filter(Indicator == "Gold", year(Period) >= 2022) %>% 
  pull(Dispersion_CV_Balanced)

iron_pre <- dispersion_balanced %>% 
  filter(Indicator == "Iron Ore", year(Period) < 2022) %>% 
  pull(Dispersion_CV_Balanced)

iron_post <- dispersion_balanced %>% 
  filter(Indicator == "Iron Ore", year(Period) >= 2022) %>% 
  pull(Dispersion_CV_Balanced)

# T-tests
t_gold <- t.test(gold_post, gold_pre)
t_iron <- t.test(iron_post, iron_pre)

cat("Gold: t =", round(t_gold$statistic, 2), ", p =", round(t_gold$p.value, 3), "\n")
cat("Iron Ore: t =", round(t_iron$statistic, 2), ", p =", round(t_iron$p.value, 3), "\n")

# Create formatted table
table_9_1 <- pre_post_comparison %>%
  kbl(digits = 2,
      caption = "Table: Dispersion Comparison - Pre-2022 vs. Post-2022",
      col.names = c("Commodity", "Period", "N", "Mean", "SD", "Min", "Max"),
      booktabs = TRUE,
      align = c("l", "l", "r", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE) %>%
  add_header_above(c(" " = 2, " " = 1, "Coefficient of Variation (%)" = 4)) %>%
  pack_rows("Gold", 1, 2) %>%
  pack_rows("Iron Ore", 3, 4) %>%
  footnote(general = paste0("T-tests for difference in means: Gold (t = ", round(t_gold$statistic, 2), 
                            ", p = ", round(t_gold$p.value, 3), "), Iron Ore (t = ", round(t_iron$statistic, 2),
                            ", p = ", round(t_iron$p.value, 3), "). Balanced panel of top 6 forecasters per commodity."),
           general_title = "Note:",
           footnote_as_chunk = TRUE)

# Display and save
table_9_1

table_9_1 %>%
  save_kable("table_9_1_pre_post_2022.png",
             zoom = 3, density = 300)





# Calculate pre/post 2022 statistics
pre_post_data <- dispersion_balanced %>%
  mutate(
    Year = year(Period),
    Period_Group = ifelse(Year < 2022, "Pre-2022", "Post-2022")
  ) %>%
  group_by(Indicator, Period_Group) %>%
  summarise(
    N = n(),
    Mean_CV = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD_CV = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    .groups = "drop"
  )

# Calculate t-tests
gold_pre <- dispersion_balanced %>% 
  filter(Indicator == "Gold", year(Period) < 2022) %>% 
  pull(Dispersion_CV_Balanced)

gold_post <- dispersion_balanced %>% 
  filter(Indicator == "Gold", year(Period) >= 2022) %>% 
  pull(Dispersion_CV_Balanced)

iron_pre <- dispersion_balanced %>% 
  filter(Indicator == "Iron Ore", year(Period) < 2022) %>% 
  pull(Dispersion_CV_Balanced)

iron_post <- dispersion_balanced %>% 
  filter(Indicator == "Iron Ore", year(Period) >= 2022) %>% 
  pull(Dispersion_CV_Balanced)

t_gold <- t.test(gold_post, gold_pre)
t_iron <- t.test(iron_post, iron_pre)

# Create table with difference row
table_data <- pre_post_data %>%
  pivot_wider(
    names_from = Period_Group,
    values_from = c(N, Mean_CV, SD_CV)
  ) %>%
  mutate(
    # Calculate difference
    Difference = `Mean_CV_Post-2022` - `Mean_CV_Pre-2022`,
    # Add t-statistic
    `t-statistic` = c(t_gold$statistic, t_iron$statistic),
    # Add p-value
    `p-value` = c(t_gold$p.value, t_iron$p.value),
    # Add significance stars
    Sig = case_when(
      `p-value` < 0.001 ~ "***",
      `p-value` < 0.01 ~ "**",
      `p-value` < 0.05 ~ "*",
      TRUE ~ ""
    ),
    # Combine difference with stars
    `Difference (Post - Pre)` = paste0(sprintf("%.2f", Difference), Sig)
  ) %>%
  select(Indicator, 
         `N_Pre-2022`, `Mean_CV_Pre-2022`, `SD_CV_Pre-2022`,
         `N_Post-2022`, `Mean_CV_Post-2022`, `SD_CV_Post-2022`,
         `Difference (Post - Pre)`, `t-statistic`, `p-value`)

# Create formatted table with pure white background
table_pre_post_comp <- table_data %>%
  kbl(digits = 2,
      caption = "Table: Dispersion Comparison - Pre-2022 vs. Post-2022",
      col.names = c("Commodity", 
                    "N", "Mean", "SD",
                    "N", "Mean", "SD",
                    "Difference", "t-stat", "p-value"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", rep("r", 9))) %>%
  kable_styling(full_width = FALSE, 
                position = "center",
                bootstrap_options = c("condensed")) %>% 
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%  
  row_spec(1:nrow(table_data), background = "#FFFFFF") %>%  
  add_header_above(c(" " = 1, 
                     "Pre-2022 (2016-2021)" = 3, 
                     "Post-2022 (2022-2025)" = 3,
                     "Statistical Test" = 3),
                   background = "#FFFFFF") %>%  
  add_header_above(c(" " = 1, 
                     "Coefficient of Variation (%)" = 6,
                     " " = 3),
                   background = "#FFFFFF") %>%  
  footnote(general = "*** p < 0.001, ** p < 0.01, * p < 0.05. Two-sample t-tests comparing mean dispersion between periods.",
           footnote_as_chunk = TRUE)


table_pre_post_comp


table_pre_post_comp %>%
  save_kable("table_pre_post_comp.png",
             zoom = 3, density = 300)

