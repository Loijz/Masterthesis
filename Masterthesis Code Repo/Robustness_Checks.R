


library(tidyverse)
library(car)  # For VIF
library(lmtest)  # For Breusch-Pagan test
library(kableExtra)



setwd("C:/PATH")



#Check for Heteroskedasticity and Multicollinearity
# Since glmnet doesn't provide residuals directly, we need to extract predictions
# and calculate residuals manually

### 11.3.1 Multicollinearity (VIF) ###

# For VIF, we need to run OLS regression (not elastic net)
# VIF tests correlation among predictors, not specific to elastic net

# Balanced Panel VIF
model_vif_data <- model_data_balanced %>%
  distinct(Period, Indicator, Publication_Quarter, .keep_all = TRUE) %>%
  filter(!is.na(Dispersion_CV_Balanced),
         !is.na(Rolling_Volatility_3m))

# Run OLS for VIF calculation
ols_balanced <- lm(Dispersion_CV_Balanced ~ Time_Numeric + Time_Horizon_Months + 
                     Difficulty_Penalty_Normalized + Rolling_Volatility_3m + 
                     N_Forecasters_Balanced,
                   data = model_vif_data)

# Calculate VIF
vif_balanced <- vif(ols_balanced)

# Gold-specific VIF
ols_gold <- lm(Dispersion_CV_Balanced ~ Time_Numeric + Time_Horizon_Months + 
                 Difficulty_Penalty_Normalized + Rolling_Volatility_3m + 
                 N_Forecasters_Balanced,
               data = model_data_gold)

vif_gold <- vif(ols_gold)

# Iron ore-specific VIF
ols_iron <- lm(Dispersion_CV_Balanced ~ Time_Numeric + Time_Horizon_Months + 
                 Difficulty_Penalty_Normalized + Rolling_Volatility_3m + 
                 N_Forecasters_Balanced,
               data = model_data_iron)

vif_iron <- vif(ols_iron)

# Create VIF comparison table
vif_table <- tibble(
  Variable = names(vif_balanced),
  Balanced_Panel = round(vif_balanced, 2),
  Gold = round(vif_gold, 2),
  Iron_Ore = round(vif_iron, 2)
)

print("VIF Results:")
print(vif_table)

# Interpretation guide
cat("\nVIF Interpretation:\n")
cat("VIF < 5: No multicollinearity concern\n")
cat("5 ≤ VIF < 10: Moderate multicollinearity\n")
cat("VIF ≥ 10: High multicollinearity (problematic)\n\n")

# Format table
vif_table_formatted <- vif_table %>%
  kbl(caption = "Table 11.3: Variance Inflation Factors (VIF)",
      col.names = c("Variable", "Balanced Panel", "Gold", "Iron Ore"),
      align = c("l", "r", "r", "r")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(vif_table), background = "#FFFFFF")

vif_table_formatted

save_kable(vif_table_formatted, 
           "table_11_3_vif.png",
           zoom = 2)

### Heteroskedasticity (Breusch-Pagan Test) ###

# Breusch-Pagan test for balanced panel
bp_balanced <- bptest(ols_balanced)

# Breusch-Pagan test for gold
bp_gold <- bptest(ols_gold)

# Breusch-Pagan test for iron ore
bp_iron <- bptest(ols_iron)

# heteroskedasticity results table
hetero_table <- tibble(
  Model = c("Balanced Panel", "Gold Only", "Iron Ore Only"),
  BP_Statistic = c(bp_balanced$statistic, bp_gold$statistic, bp_iron$statistic),
  p_value = c(bp_balanced$p.value, bp_gold$p.value, bp_iron$p.value),
  Conclusion = c(
    ifelse(bp_balanced$p.value < 0.05, "Heteroskedasticity Present", "Homoskedastic"),
    ifelse(bp_gold$p.value < 0.05, "Heteroskedasticity Present", "Homoskedastic"),
    ifelse(bp_iron$p.value < 0.05, "Heteroskedasticity Present", "Homoskedastic")
  )
) %>%
  mutate(across(c(BP_Statistic, p_value), ~round(., 4)))

print("Breusch-Pagan Test Results:")
print(hetero_table)






# Create heteroskedasticity results table
hetero_table <- tibble(
  Model = c("Balanced Panel", "Gold Only", "Iron Ore Only"),
  BP_Statistic = c(
    round(bp_balanced$statistic, 2),
    round(bp_gold$statistic, 2),
    round(bp_iron$statistic, 2)
  ),
  df = c(
    bp_balanced$parameter,
    bp_gold$parameter,
    bp_iron$parameter
  ),
  p_value = c(
    format(bp_balanced$p.value, scientific = TRUE, digits = 3),
    format(bp_gold$p.value, scientific = TRUE, digits = 3),
    format(bp_iron$p.value, scientific = TRUE, digits = 3)
  ),
  Result = c(
    ifelse(bp_balanced$p.value < 0.05, "Heteroskedastic", "Homoskedastic"),
    ifelse(bp_gold$p.value < 0.05, "Heteroskedastic", "Homoskedastic"),
    ifelse(bp_iron$p.value < 0.05, "Heteroskedastic", "Homoskedastic")
  )
)

print("Breusch-Pagan Test Results:")
print(hetero_table)

# Format table
hetero_table_formatted <- hetero_table %>%
  kbl(caption = "Table 11.4: Breusch-Pagan Test for Heteroskedasticity",
      col.names = c("Model", "BP Statistic", "df", "p-value", "Result"),
      align = c("l", "r", "r", "r", "c")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:3, background = "#FFFFFF") %>%
  add_footnote("H0: Homoskedasticity (constant variance). p < 0.05 indicates heteroskedasticity.",
               notation = "none")

hetero_table_formatted

save_kable(hetero_table_formatted, 
           "table_11_4_heteroskedasticity.png",
           zoom = 2)


cat("\nInterpretation:\n")
cat("H0: Homoskedasticity (constant variance)\n")
cat("H1: Heteroskedasticity (non-constant variance)\n")
cat("If p < 0.05: Reject H0 → Heteroskedasticity present\n\n")

# Format table
hetero_table_formatted <- hetero_table %>%
  kbl(caption = "Table 11.4: Breusch-Pagan Test for Heteroskedasticity",
      col.names = c("Model", "BP Statistic", "p-value", "Conclusion"),
      align = c("l", "r", "r", "l")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(hetero_table), background = "#FFFFFF")

hetero_table_formatted

save_kable(hetero_table_formatted, 
           "table_11_4_heteroskedasticity.png",
           zoom = 2)

### Residual Plots ###

# Extract residuals and fitted values from OLS models

# Balanced panel residual plot
resid_plot_balanced <- ggplot(data.frame(
  Fitted = fitted(ols_balanced),
  Residuals = residuals(ols_balanced)
), aes(x = Fitted, y = Residuals)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  labs(title = "Residuals vs Fitted: Balanced Panel",
       x = "Fitted Values",
       y = "Residuals") +
  theme_minimal()

resid_plot_balanced

ggsave("figure_11_3_residuals_balanced.png", 
       plot = resid_plot_balanced,
       width = 8, height = 6, dpi = 300)

# Gold residual plot
resid_plot_gold <- ggplot(data.frame(
  Fitted = fitted(ols_gold),
  Residuals = residuals(ols_gold)
), aes(x = Fitted, y = Residuals)) +
  geom_point(alpha = 0.5, color = "gold4") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  labs(title = "Residuals vs Fitted: Gold",
       x = "Fitted Values",
       y = "Residuals") +
  theme_minimal()

resid_plot_gold

ggsave("figure_11_4_residuals_gold.png", 
       plot = resid_plot_gold,
       width = 8, height = 6, dpi = 300)

# Iron ore residual plot
resid_plot_iron <- ggplot(data.frame(
  Fitted = fitted(ols_iron),
  Residuals = residuals(ols_iron)
), aes(x = Fitted, y = Residuals)) +
  geom_point(alpha = 0.5, color = "darkgrey") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  labs(title = "Residuals vs Fitted: Iron Ore",
       x = "Fitted Values",
       y = "Residuals") +
  theme_minimal()

resid_plot_iron

ggsave("figure_11_5_residuals_iron.png", 
       plot = resid_plot_iron,
       width = 8, height = 6, dpi = 300)





# diagnostic summary table 
diagnostic_summary <- tibble(
  Test = c("Multicollinearity (Max VIF)", 
           "Heteroskedasticity (BP p-value)",
           "Model Assumptions"),
  Balanced_Panel = c(
    round(max(vif_balanced), 3),
    round(bp_balanced$p.value, 4),
    ifelse(max(vif_balanced) < 5 & bp_balanced$p.value >= 0.05, "✓ Satisfied", "⚠ Violated")
  ),
  Gold = c(
    round(max(vif_gold), 3),
    round(bp_gold$p.value, 4),
    ifelse(max(vif_gold) < 5 & bp_gold$p.value >= 0.05, "✓ Satisfied", "⚠ Violated")
  ),
  Iron_Ore = c(
    round(max(vif_iron), 3),
    round(bp_iron$p.value, 4),
    ifelse(max(vif_iron) < 5 & bp_iron$p.value >= 0.05, "✓ Satisfied", "⚠ Violated")
  )
)

print("Diagnostic Summary:")
print(diagnostic_summary)

# Format as nice table
diagnostic_summary_formatted <- diagnostic_summary %>%
  kbl(caption = "Table 11.5: Diagnostic Test Summary",
      col.names = c("Test", "Balanced Panel", "Gold", "Iron Ore"),
      align = c("l", "c", "c", "c")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:3, background = "#FFFFFF") %>%
  row_spec(3, bold = TRUE)  # Highlight conclusion row

diagnostic_summary_formatted

save_kable(diagnostic_summary_formatted, 
           "table_11_5_diagnostic_summary.png",
           zoom = 2)






# heteroskedasticity results table
hetero_table <- tibble(
  Model = c("Balanced Panel", "Gold Only", "Iron Ore Only"),
  BP_Statistic = c(
    round(bp_balanced$statistic, 2),
    round(bp_gold$statistic, 2),
    round(bp_iron$statistic, 2)
  ),
  df = c(
    bp_balanced$parameter,
    bp_gold$parameter,
    bp_iron$parameter
  ),
  p_value = c(
    format(bp_balanced$p.value, scientific = TRUE, digits = 3),
    format(bp_gold$p.value, scientific = TRUE, digits = 3),
    format(bp_iron$p.value, scientific = TRUE, digits = 3)
  ),
  Result = c(
    ifelse(bp_balanced$p.value < 0.05, "Heteroskedastic", "Homoskedastic"),
    ifelse(bp_gold$p.value < 0.05, "Heteroskedastic", "Homoskedastic"),
    ifelse(bp_iron$p.value < 0.05, "Heteroskedastic", "Homoskedastic")
  )
)

print("Breusch-Pagan Test Results:")
print(hetero_table)

# Format table
hetero_table_formatted <- hetero_table %>%
  kbl(caption = "Table: Breusch-Pagan Test for Heteroskedasticity",
      col.names = c("Model", "BP Statistic", "df", "p-value", "Result"),
      align = c("l", "r", "r", "r", "c")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:3, background = "#FFFFFF") %>%
  add_footnote("H0: Homoskedasticity (constant variance). p < 0.05 indicates heteroskedasticity.",
               notation = "none")

hetero_table_formatted

save_kable(hetero_table_formatted, 
           "table_11_4_heteroskedasticity.png",
           zoom = 2)
