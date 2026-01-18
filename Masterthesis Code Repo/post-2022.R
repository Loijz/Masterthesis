library(glmnet)
library(kableextra)

setwd("C:/PATH")

# Filter to post-2022 data
base_data_post <- base_data %>%
  filter(year(Period) >= 2022)

# Check sample size
cat("Post-2022 observations:", nrow(base_data_post), "\n")

# Create matrices
X_post <- base_data_post %>%
  select(Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters_Balanced) %>%
  as.matrix()

y_post <- base_data_post$Dispersion_CV_Balanced

# Fit pooled model
set.seed(123)

elastic_post <- cv.glmnet(
  x = X_post,
  y = y_post,
  alpha = 0.5,
  nfolds = 10,
  standardize = TRUE
)

# View results
cat("\n=== POST-2022 POOLED MODEL ===\n")
print(coef(elastic_post, s = "lambda.min"))

# Calculate R²
pred_post <- predict(elastic_post, newx = X_post, s = "lambda.min")
r2_post <- cor(y_post, pred_post)^2

cat("\n=== MODEL FIT ===\n")
cat("Post-2022 R²:", round(r2_post, 3), "\n")

# Split by commodity for post-2022
base_data_post_gold <- base_data_post %>% filter(Indicator == "Gold")
base_data_post_iron <- base_data_post %>% filter(Indicator == "Iron Ore")

cat("\nPost-2022 Gold observations:", nrow(base_data_post_gold), "\n")
cat("Post-2022 Iron Ore observations:", nrow(base_data_post_iron), "\n")

# Gold post-2022
X_post_gold <- base_data_post_gold %>%
  select(Time_Horizon_Months, Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()
y_post_gold <- base_data_post_gold$Dispersion_CV_Balanced

elastic_post_gold <- cv.glmnet(x = X_post_gold, y = y_post_gold,
                               alpha = 0.5, nfolds = 10, standardize = TRUE)

# Iron Ore post-2022
X_post_iron <- base_data_post_iron %>%
  select(Time_Horizon_Months, Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()
y_post_iron <- base_data_post_iron$Dispersion_CV_Balanced

elastic_post_iron <- cv.glmnet(x = X_post_iron, y = y_post_iron,
                               alpha = 0.5, nfolds = 10, standardize = TRUE)

# Results
cat("\n=== POST-2022 GOLD ===\n")
print(coef(elastic_post_gold, s = "lambda.min"))
pred_post_gold <- predict(elastic_post_gold, newx = X_post_gold, s = "lambda.min")
r2_post_gold <- cor(y_post_gold, pred_post_gold)^2
cat("R²:", round(r2_post_gold, 3), "\n")

cat("\n=== POST-2022 IRON ORE ===\n")
print(coef(elastic_post_iron, s = "lambda.min"))
pred_post_iron <- predict(elastic_post_iron, newx = X_post_iron, s = "lambda.min")
r2_post_iron <- cor(y_post_iron, pred_post_iron)^2
cat("R²:", round(r2_post_iron, 3), "\n")


saveRDS(elastic_post, "elastic_post.rds")
saveRDS(elastic_post_gold, "elastic_post_gold.rds")
saveRDS(elastic_post_iron, "elastic_post_iron.rds")











library(kableExtra)

# Create post-2022 table
post2022_results <- data.frame(
  Variable = c("Time Horizon (months)",
               "Difficulty Penalty (0-1)",
               "Rolling Volatility (3-month)",
               "Number of Forecasters",
               "",
               "Observations",
               "R²"),
  Pooled = c(
    "0.047",
    "-5.057",
    "0.377",
    "-0.670",
    "",
    "299",
    "0.215"
  ),
  Gold = c(
    "0.210",
    "0.000",
    "-0.016",
    "1.352",
    "",
    "140",
    "0.413"
  ),
  `Iron Ore` = c(
    "0.000",
    "0.000",
    "0.000",
    "0.000",
    "",
    "159",
    "—"
  ),
  check.names = FALSE
)

# Create formatted table
table_9_6 <- post2022_results %>%
  kbl(caption = "Table: Post-2022 Period Model Results (2022-2025)",
      col.names = c("Variable", "Pooled", "Gold", "Iron Ore"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(post2022_results), background = "#FFFFFF") %>%
  row_spec(5, hline_after = TRUE) %>%
  add_header_above(c(" " = 1, "Dependent Variable: Dispersion (CV %)" = 3),
                   background = "#FFFFFF") %>%
  add_footnote("Note: Elastic net regression estimated on 2022-2025 subsample. ",
               notation = "none")

table_9_6

table_9_6 %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_9_6_post2022.png",
             zoom = 3, density = 300)





# Create comprehensive comparison table
comparison_pre_post <- data.frame(
  Variable = rep(c("Time Horizon", "Difficulty Penalty", "Volatility", "N Forecasters", "R²"), 2),
  Period = c(rep("Pre-2022", 5), rep("Post-2022", 5)),
  Gold = c(
    0.089, 0.000, -0.086, -0.099, 0.152,
    0.210, 0.000, -0.016, 1.352, 0.413
  ),
  `Iron Ore` = c(
    0.052, 1.591, 0.109, 2.351, 0.265,
    0.000, 0.000, 0.000, 0.000, NA
  ),
  check.names = FALSE
)

# Reshape for side-by-side comparison
table_9_7_data <- data.frame(
  Variable = c("Time Horizon (months)", "Difficulty Penalty (0-1)",
               "Rolling Volatility", "Number of Forecasters", "", "R²"),
  Gold_Pre = c("0.089", "0.000", "-0.086", "-0.099", "", "0.152"),
  Gold_Post = c("0.210", "0.000", "-0.016", "1.352", "", "0.413"),
  Iron_Pre = c("0.052", "1.591", "0.109", "2.351", "", "0.265"),
  Iron_Post = c("0.000", "0.000", "0.000", "0.000", "", "—")
)

table_9_7 <- table_9_7_data %>%
  kbl(caption = "Table: Pre-2022 vs. Post-2022 Coefficient Comparison",
      col.names = c("Variable", "Pre-2022", "Post-2022", "Pre-2022", "Post-2022"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_9_7_data), background = "#FFFFFF") %>%
  row_spec(5, hline_after = TRUE) %>%
  add_header_above(c(" " = 1, "Gold" = 2, "Iron Ore" = 2),
                   background = "#FFFFFF") %>%
  add_footnote("Note: Elastic net coefficients comparing 2016-2021 vs 2022-2025 periods. ",
               notation = "none")

table_9_7

table_9_7 %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_9_7_pre_post_comparison.png",
             zoom = 3, density = 300)


# Check difficulty variation for gold vs iron ore
base_data %>%
  group_by(Indicator) %>%
  summarise(
    Mean_Difficulty = mean(Difficulty_Penalty_Normalized),
    SD_Difficulty = sd(Difficulty_Penalty_Normalized),
    Min_Difficulty = min(Difficulty_Penalty_Normalized),
    Max_Difficulty = max(Difficulty_Penalty_Normalized),
    Range = Max_Difficulty - Min_Difficulty
  )

# Check correlation between difficulty and dispersion by commodity
base_data %>%
  group_by(Indicator) %>%
  summarise(
    Cor_Difficulty_Dispersion = cor(Difficulty_Penalty_Normalized, 
                                    Dispersion_CV_Balanced, 
                                    use = "complete.obs")
  )





#### OLS on iron ore ####

# OLS for Iron Ore Post-2022
lm_iron_post <- lm(Dispersion_CV_Balanced ~ Time_Horizon_Months + 
                     Difficulty_Penalty_Normalized + 
                     Rolling_Volatility_3m + 
                     N_Forecasters_Balanced,
                   data = base_data_post_iron)

# View results
summary(lm_iron_post)

# Check if model is valid
cat("\n=== DIAGNOSTICS ===\n")
cat("N observations:", nrow(base_data_post_iron), "\n")
cat("R-squared:", round(summary(lm_iron_post)$r.squared, 3), "\n")
cat("Adjusted R-squared:", round(summary(lm_iron_post)$adj.r.squared, 3), "\n")
cat("F-statistic p-value:", 
    round(pf(summary(lm_iron_post)$fstatistic[1], 
             summary(lm_iron_post)$fstatistic[2], 
             summary(lm_iron_post)$fstatistic[3], 
             lower.tail = FALSE), 4), "\n")

# Plot residuals
par(mfrow = c(2, 2))
plot(lm_iron_post)
par(mfrow = c(1, 1))

# Compare with elastic net
cat("\n=== COMPARISON ===\n")
cat("Elastic Net R²: Cannot calculate (all coef = 0)\n")
cat("OLS R²:", round(summary(lm_iron_post)$r.squared, 3), "\n")

# Check for multicollinearity
library(car)
vif_results <- vif(lm_iron_post)
cat("\nVIF (multicollinearity check):\n")
print(vif_results)




library(kableExtra)
library(broom)

# Extract coefficients and statistics
lm_table <- tidy(lm_iron_post) %>%
  mutate(
    # Add significance stars
    Sig = case_when(
      p.value < 0.001 ~ "***",
      p.value < 0.01 ~ "**",
      p.value < 0.05 ~ "*",
      p.value < 0.1 ~ ".",
      TRUE ~ ""
    ),
    # Combine estimate with stars
    Coefficient = paste0(sprintf("%.3f", estimate), Sig),
    `Std. Error` = sprintf("%.3f", std.error),
    `t-value` = sprintf("%.3f", statistic),
    `p-value` = sprintf("%.3f", p.value)
  ) %>%
  select(term, Coefficient, `Std. Error`, `t-value`, `p-value`)

# Rename variables
lm_table <- lm_table %>%
  mutate(
    term = case_when(
      term == "(Intercept)" ~ "Intercept",
      term == "Time_Horizon_Months" ~ "Time Horizon (months)",
      term == "Difficulty_Penalty_Normalized" ~ "Difficulty Penalty (0-1)",
      term == "Rolling_Volatility_3m" ~ "Rolling Volatility (3-month)",
      term == "N_Forecasters_Balanced" ~ "Number of Forecasters",
      TRUE ~ term
    )
  )

# Add model statistics rows
model_stats <- data.frame(
  term = c("", "Observations", "R²", "Adjusted R²", "F-statistic", "F p-value"),
  Coefficient = c("", 
                  as.character(nobs(lm_iron_post)),
                  sprintf("%.3f", summary(lm_iron_post)$r.squared),
                  sprintf("%.3f", summary(lm_iron_post)$adj.r.squared),
                  sprintf("%.3f", summary(lm_iron_post)$fstatistic[1]),
                  sprintf("%.3f", pf(summary(lm_iron_post)$fstatistic[1],
                                     summary(lm_iron_post)$fstatistic[2],
                                     summary(lm_iron_post)$fstatistic[3],
                                     lower.tail = FALSE))),
  `Std. Error` = "",
  `t-value` = "",
  `p-value` = "",
  check.names = FALSE
)

# Combine
lm_table_full <- bind_rows(lm_table, model_stats)

library(kableExtra)

# Create formatted table
table_iron_post_ols <- lm_table_full %>%
  kbl(caption = "Table: OLS Regression - Iron Ore Post-2022 (2022-2025)",
      col.names = c("Variable", "Coefficient", "Std. Error", "t-value", "p-value"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(lm_table_full), background = "#FFFFFF") %>%
  row_spec(6, hline_after = TRUE) %>%
  add_header_above(c(" " = 1, "Dependent Variable: Dispersion (CV %)" = 4),
                   background = "#FFFFFF") %>%
  kableExtra::add_footnote(
    "*** p < 0.001, ** p < 0.01, * p < 0.05, . p < 0.1. Ordinary least squares regression. Residual standard error: 4.207 on 154 degrees of freedom.",
    notation = "none"
  )

# Display
table_iron_post_ols

# Save
table_iron_post_ols %>%
  save_kable("table_iron_post_ols.png", zoom = 2)
