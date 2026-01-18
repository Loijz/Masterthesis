library(tidyverse)
library(boot)

# Using model_data_balanced


# Bootstrap function
boot_stats <- function(data, indices) {
  # Resample the data
  d <- data[indices, ]
  
  # Calculate mean dispersion by period and commodity
  gold_pre <- d %>% 
    filter(Indicator == "Gold", Year < 2022) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  gold_post <- d %>% 
    filter(Indicator == "Gold", Year >= 2022) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  iron_pre <- d %>% 
    filter(Indicator == "Iron Ore", Year < 2022) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  iron_post <- d %>% 
    filter(Indicator == "Iron Ore", Year >= 2022) %>% 
    pull(Dispersion_CV) %>% 
    mean(na.rm = TRUE)
  
  # Calculate differences (structural break magnitude)
  gold_diff <- gold_post - gold_pre
  iron_diff <- iron_post - iron_pre
  
  # Return vector of statistics
  return(c(gold_pre, gold_post, gold_diff, 
           iron_pre, iron_post, iron_diff))
}

# Run bootstrap with 1000 replications
set.seed(42)  # For reproducibility
boot_results <- boot(
  data = model_data_balanced,  # Your main dataset
  statistic = boot_stats,
  R = 1000,  # 1000 bootstrap samples
  parallel = "multicore",  # Use multiple cores if available
  ncpus = 4
)

# Extract bootstrap confidence intervals
boot_ci_gold_pre <- boot.ci(boot_results, index = 1, type = "perc")
boot_ci_gold_post <- boot.ci(boot_results, index = 2, type = "perc")
boot_ci_gold_diff <- boot.ci(boot_results, index = 3, type = "perc")
boot_ci_iron_pre <- boot.ci(boot_results, index = 4, type = "perc")
boot_ci_iron_post <- boot.ci(boot_results, index = 5, type = "perc")
boot_ci_iron_diff <- boot.ci(boot_results, index = 6, type = "perc")

# Create results table
bootstrap_table <- tibble(
  Metric = c(
    "Gold: Mean Dispersion Pre-2022",
    "Gold: Mean Dispersion Post-2022",
    "Gold: Structural Break Magnitude",
    "Iron Ore: Mean Dispersion Pre-2022",
    "Iron Ore: Mean Dispersion Post-2022",
    "Iron Ore: Structural Break Magnitude"
  ),
  Observed = c(
    boot_results$t0[1],
    boot_results$t0[2],
    boot_results$t0[3],
    boot_results$t0[4],
    boot_results$t0[5],
    boot_results$t0[6]
  ),
  CI_Lower = c(
    boot_ci_gold_pre$percent[4],
    boot_ci_gold_post$percent[4],
    boot_ci_gold_diff$percent[4],
    boot_ci_iron_pre$percent[4],
    boot_ci_iron_post$percent[4],
    boot_ci_iron_diff$percent[4]
  ),
  CI_Upper = c(
    boot_ci_gold_pre$percent[5],
    boot_ci_gold_post$percent[5],
    boot_ci_gold_diff$percent[5],
    boot_ci_iron_pre$percent[5],
    boot_ci_iron_post$percent[5],
    boot_ci_iron_diff$percent[5]
  )
) %>%
  mutate(across(where(is.numeric), ~round(., 3)))

print(bootstrap_table)




bootstrap_table_formatted <- bootstrap_table %>%
  kbl(caption = "Table 11.1: Bootstrap Confidence Intervals (1000 replications)",
      col.names = c("Metric", "Observed Value", "95% CI Lower", "95% CI Upper"),
      align = c("l", "r", "r", "r")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:6, background = "#FFFFFF") %>%
  row_spec(c(3, 6), bold = TRUE)  # Highlight structural break rows

bootstrap_table_formatted


save_kable(bootstrap_table_formatted, 
           "table_11_1_bootstrap_ci.png",
           zoom = 2)

# Visualize bootstrap distributions
bootstrap_df <- tibble(
  gold_diff = boot_results$t[, 3],
  iron_diff = boot_results$t[, 6]
) %>%
  pivot_longer(everything(), names_to = "Commodity", values_to = "Difference") %>%
  mutate(Commodity = ifelse(Commodity == "gold_diff", "Gold", "Iron Ore"))

bootstrap_plot <- ggplot(bootstrap_df, aes(x = Difference, fill = Commodity)) +
  geom_histogram(alpha = 0.6, bins = 50, position = "identity") +
  geom_vline(xintercept = boot_results$t0[3], 
             linetype = "dashed", color = "#F8766D", linewidth = 1) +
  geom_vline(xintercept = boot_results$t0[6], 
             linetype = "dashed", color = "#00BFC4", linewidth = 1) +
  labs(title = "Bootstrap Distribution of Structural Break Magnitude",
       subtitle = "1000 resamples with replacement",
       x = "Change in Mean Dispersion (Post-2022 minus Pre-2022)",
       y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "bottom")

bootstrap_plot

ggsave("figure_11_1_bootstrap_distribution.png", 
       plot = bootstrap_plot, 
       width = 10, height = 6, dpi = 300)
