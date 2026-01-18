library(tidyverse)
library(kableExtra)
library(dplyr)

setwd("C:/PATH")



############# Placebo Test ##############



# Function to test structural break at any year
placebo_test <- function(data, break_year) {
  
  # Calculate pre/post means for this placebo year
  gold_pre <- data %>% 
    filter(Indicator == "Gold", Year < break_year) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  gold_post <- data %>% 
    filter(Indicator == "Gold", Year >= break_year) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  iron_pre <- data %>% 
    filter(Indicator == "Iron Ore", Year < break_year) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  iron_post <- data %>% 
    filter(Indicator == "Iron Ore", Year >= break_year) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  # Calculate differences
  gold_diff <- gold_post - gold_pre
  iron_diff <- iron_post - iron_pre
  
  # Calculate percentage changes
  gold_pct_change <- (gold_diff / gold_pre) * 100
  iron_pct_change <- (iron_diff / iron_pre) * 100
  
  # T-tests for each commodity
  gold_ttest <- t.test(
    data %>% filter(Indicator == "Gold", Year >= break_year) %>% pull(Dispersion_CV),
    data %>% filter(Indicator == "Gold", Year < break_year) %>% pull(Dispersion_CV)
  )
  
  iron_ttest <- t.test(
    data %>% filter(Indicator == "Iron Ore", Year >= break_year) %>% pull(Dispersion_CV),
    data %>% filter(Indicator == "Iron Ore", Year < break_year) %>% pull(Dispersion_CV)
  )
  
  return(tibble(
    Break_Year = break_year,
    Gold_Diff = gold_diff,
    Gold_Pct_Change = gold_pct_change,
    Gold_pvalue = gold_ttest$p.value,
    Iron_Diff = iron_diff,
    Iron_Pct_Change = iron_pct_change,
    Iron_pvalue = iron_ttest$p.value
  ))
}

# Test all years in sample
year_range <- seq(2017, 2024)

placebo_results <- map_df(year_range, ~placebo_test(model_data_balanced, .x))

# indicator for break year and significance stars
placebo_results <- placebo_results %>%
  mutate(
    Is_Actual_Break = ifelse(Break_Year == 2022, "2022 (Actual)", "Placebo"),
    
    # stars to p-values
    Gold_pvalue_sig = case_when(
      Gold_pvalue < 0.001 ~ paste0(formatC(Gold_pvalue, format = "e", digits = 2), "***"),
      Gold_pvalue < 0.01 ~ paste0(formatC(Gold_pvalue, format = "e", digits = 2), "**"),
      Gold_pvalue < 0.05 ~ paste0(formatC(Gold_pvalue, format = "e", digits = 2), "*"),
      TRUE ~ formatC(Gold_pvalue, format = "e", digits = 2)
    ),
    
    Iron_pvalue_sig = case_when(
      Iron_pvalue < 0.001 ~ paste0(formatC(Iron_pvalue, format = "e", digits = 2), "***"),
      Iron_pvalue < 0.01 ~ paste0(formatC(Iron_pvalue, format = "e", digits = 2), "**"),
      Iron_pvalue < 0.05 ~ paste0(formatC(Iron_pvalue, format = "e", digits = 2), "*"),
      TRUE ~ formatC(Iron_pvalue, format = "e", digits = 2)
    )
  )

print(placebo_results)


placebo_table <- placebo_results %>%
  select(Break_Year, Is_Actual_Break, 
         Gold_Diff, Gold_Pct_Change, Gold_pvalue_sig,
         Iron_Diff, Iron_Pct_Change, Iron_pvalue_sig) %>%
  mutate(
    Gold_Diff = round(Gold_Diff, 2),
    Gold_Pct_Change = paste0(sprintf("%.1f", Gold_Pct_Change), "%"),
    Iron_Diff = round(Iron_Diff, 2),
    Iron_Pct_Change = paste0(sprintf("%.1f", Iron_Pct_Change), "%")
  )

placebo_table_formatted <- placebo_table %>%
  kbl(caption = "Table 11.2: Placebo Structural Break Test",
      col.names = c("Break Year", "Type", 
                    "Diff", "% Change", "p-value",
                    "Diff", "% Change", "p-value"),
      align = c("c", "c", "r", "r", "r", "r", "r", "r"),
      escape = FALSE) %>%
  kable_styling(bootstrap_options = c("condensed"),
                full_width = FALSE) %>%
  add_header_above(c(" " = 2, "Gold" = 3, "Iron Ore" = 3),
                   background = "#FFFFFF") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(placebo_table), background = "#FFFFFF") %>%
  row_spec(which(placebo_table$Is_Actual_Break == "2022 (Actual)"), 
           bold = TRUE, background = "#ffffcc") %>%  # Highlight 2022
  footnote(general = "*** p < 0.001, ** p < 0.01, * p < 0.05. Diff = change in mean CV (percentage points). % Change = percentage increase from pre-break mean. Each row tests whether treating that year as a structural break yields significant dispersion increase.")

placebo_table_formatted

save_kable(placebo_table_formatted, 
           "table_11_2_placebo_test.png",
           zoom = 2)

# Visualize placebo test results
placebo_plot <- placebo_results %>%
  pivot_longer(cols = c(Gold_Diff, Iron_Diff), 
               names_to = "Commodity", 
               values_to = "Difference") %>%
  mutate(Commodity = str_remove(Commodity, "_Diff")) %>%
  ggplot(aes(x = Break_Year, y = Difference, color = Commodity, shape = Is_Actual_Break)) +
  geom_point(size = 4, alpha = 0.8) +
  geom_line(alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  scale_shape_manual(values = c("2022 (Actual)" = 17, "Placebo" = 16)) +
  labs(title = "Placebo Structural Break Test",
       subtitle = "Magnitude of dispersion change for different break years",
       x = "Hypothetical Break Year",
       y = "Change in Mean Dispersion (Post minus Pre)",
       shape = "Break Type") +
  theme_minimal() +
  theme(legend.position = "bottom",
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA))

placebo_plot

ggsave("figure_11_2_placebo_test.png", 
       plot = placebo_plot, 
       width = 10, height = 6, dpi = 300, bg = "white")




# Check sample sizes 
sample_check <- map_df(year_range, function(break_year) {
  tibble(
    Break_Year = break_year,
    Gold_N_Pre = model_data_balanced %>% 
      filter(Indicator == "Gold", Year < break_year) %>% 
      nrow(),
    Gold_N_Post = model_data_balanced %>% 
      filter(Indicator == "Gold", Year >= break_year) %>% 
      nrow(),
    Iron_N_Pre = model_data_balanced %>% 
      filter(Indicator == "Iron Ore", Year < break_year) %>% 
      nrow(),
    Iron_N_Post = model_data_balanced %>% 
      filter(Indicator == "Iron Ore", Year >= break_year) %>% 
      nrow()
  )
})

print(sample_check)

# Check means used for percentage calculation
mean_check <- map_df(year_range, function(break_year) {
  tibble(
    Break_Year = break_year,
    Gold_Mean_Pre = model_data_balanced %>% 
      filter(Indicator == "Gold", Year < break_year) %>% 
      pull(Dispersion_CV) %>% 
      mean(na.rm = TRUE),
    Iron_Mean_Pre = model_data_balanced %>% 
      filter(Indicator == "Iron Ore", Year < break_year) %>% 
      pull(Dispersion_CV) %>% 
      mean(na.rm = TRUE)
  )
})

print(mean_check)




# Filter to balanced years 2018 - 2023 to prevent wrong numbers for not enough datasets from 2016
placebo_results_reliable <- placebo_results %>%
  filter(Break_Year >= 2018, Break_Year <= 2024)

# Create formatted table
placebo_table_rel <- placebo_results_reliable %>%
  select(Break_Year, Is_Actual_Break, 
         Gold_Diff, Gold_Pct_Change, Gold_pvalue_sig,
         Iron_Diff, Iron_Pct_Change, Iron_pvalue_sig) %>%
  mutate(
    Gold_Diff = round(Gold_Diff, 2),
    Gold_Pct_Change = paste0(sprintf("%.1f", Gold_Pct_Change), "%"),
    Iron_Diff = round(Iron_Diff, 2),
    Iron_Pct_Change = paste0(sprintf("%.1f", Iron_Pct_Change), "%")
  )

placebo_table_formatted_rel <- placebo_table_rel %>%
  kbl(caption = "Table: Placebo Structural Break Test",
      col.names = c("Break Year", "Type", 
                    "Diff", "% Change", "p-value",
                    "Diff", "% Change", "p-value"),
      align = c("c", "c", "r", "r", "r", "r", "r", "r"),
      escape = FALSE) %>%
  kable_styling(bootstrap_options = c("condensed"),
                full_width = FALSE) %>%
  add_header_above(c(" " = 2, "Gold" = 3, "Iron Ore" = 3),
                   background = "#FFFFFF") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(placebo_table_rel), background = "#FFFFFF") %>%  # FIXED
  row_spec(which(placebo_table_rel$Is_Actual_Break == "2022 (Actual)"),  # FIXED
           bold = TRUE, background = "#ffffcc") %>%
  footnote(general = "*** p < 0.001, ** p < 0.01, * p < 0.05. Diff = change in mean CV (percentage points). % Change = percentage increase from pre-break mean. Each row tests whether treating that year as a structural break yields significant dispersion increase.")

placebo_table_formatted_rel

save_kable(placebo_table_formatted_rel,  # FIXED - save the right object
           "table_11_2_placebo_test.png",
           zoom = 2)

# Visualize placebo test results
placebo_plot_rel <- placebo_results_reliable %>%
  pivot_longer(cols = c(Gold_Diff, Iron_Diff), 
               names_to = "Commodity", 
               values_to = "Difference") %>%
  mutate(Commodity = str_remove(Commodity, "_Diff")) %>%
  ggplot(aes(x = Break_Year, y = Difference, color = Commodity, shape = Is_Actual_Break)) +
  geom_point(size = 4, alpha = 0.8) +
  geom_line(alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  scale_shape_manual(values = c("2022 (Actual)" = 17, "Placebo" = 16)) +
  labs(title = "Placebo Structural Break Test",
       subtitle = "Magnitude of dispersion change for different break years",
       x = "Hypothetical Break Year",
       y = "Change in Mean Dispersion (Post minus Pre)",
       shape = "Break Type") +
  theme_minimal() +
  theme(legend.position = "bottom",
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA))

placebo_plot_rel

ggsave("figure_11_2_placebo_rel_test.png", 
       plot = placebo_plot_rel, 
       width = 10, height = 6, dpi = 300, bg = "white")
