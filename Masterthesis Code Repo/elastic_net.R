library(glmnet)
library(ggplot2)
library(tidyr)
library(dplyr)
library(kableExtra)



setwd("C:/PATH")

# Fit elastic net across full lambda sequence using X_balanced
elastic_path <- glmnet(
  x = X_balanced,  # Your existing matrix with time trend
  y = y_balanced,  # Your existing y vector
  alpha = 0.5,
  standardize = TRUE
)


coef_matrix <- as.matrix(coef(elastic_path))


coef_df <- as.data.frame(t(coef_matrix[-1, ]))  # Remove intercept row
coef_df$lambda <- elastic_path$lambda

# Reshape for plotting
coef_long <- coef_df %>%
  pivot_longer(cols = -lambda,
               names_to = "Variable",
               values_to = "Coefficient") %>%
  mutate(
    # Clean variable names
    Variable = case_when(
      Variable == "Time_Numeric" ~ "Time Trend",
      Variable == "Time_Horizon_Months" ~ "Time Horizon",
      Variable == "Difficulty_Penalty_Normalized" ~ "Difficulty Penalty",
      Variable == "Rolling_Volatility_3m" ~ "Volatility (3m)",
      Variable == "N_Forecasters_Balanced" ~ "Number of Forecasters",
      TRUE ~ Variable
    )
  )

# Create coefficient path plot
coef_path_plot <- ggplot(coef_long, aes(x = log(lambda), y = Coefficient, color = Variable)) +
  geom_line(linewidth = 1.0, alpha = 0.6) +
  geom_vline(xintercept = log(elastic_balanced$lambda.min), 
             linetype = "dashed", color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "gray50") +
  annotate("text", x = log(elastic_balanced$lambda.min), y = max(coef_long$Coefficient) * -0.45,
           label = "Optimal Lambda", color = "red", hjust = -0.05, fontface = "bold") +
  labs(
    title = "Elastic Net Coefficient Path",
    subtitle = "Predictors shrinkage with increasing penalty (Lambda)",
    x = "log(Lambda) - Regularization Strength",
    y = "Coefficient Value",
    color = "Variable"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14),
    panel.background = element_rect(fill = "white", color = "black"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.grid.major = element_line(color = "gray90")
  ) +
  scale_color_manual(values = c(
    "Time Trend" = "red",
    "Time Horizon" = "blue",
    "Difficulty Penalty" = "purple",
    "Volatility (3m)" = "darkgreen",
    "Number of Forecasters" = "orange"
  ))

coef_path_plot

ggsave("figure_coefficient_path_elastic_net.png",
       plot = coef_path_plot,
       width = 10, height = 6, dpi = 300, bg = "white")

# Summary table: Coefficients at different lambda values
lambda_comparison <- data.frame(
  Lambda = c("OLS", "Optimal CV", "Large Lambda"),
  Time_Trend = c(
    coef(elastic_path, s = min(elastic_path$lambda))[2],
    coef(elastic_balanced, s = "lambda.min")[2],
    0
  ),
  Difficulty = c(
    coef(elastic_path, s = min(elastic_path$lambda))[4],
    coef(elastic_balanced, s = "lambda.min")[4],
    0
  ),
  Volatility = c(
    coef(elastic_path, s = min(elastic_path$lambda))[5],
    coef(elastic_balanced, s = "lambda.min")[5],
    0
  )
)

print("=== Coefficient Comparison Across Lambda Values ===")
print(lambda_comparison)

# comparison table
table_lambda_comparison <- lambda_comparison %>%
  mutate(across(where(is.numeric), ~round(., 3))) %>%
  kbl(caption = "Table: How Coefficients Shrink with Lambda",
      col.names = c("Penalty Level", "Time Trend", "Difficulty", "Volatility"),
      align = c("l", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:3, background = "#FFFFFF") %>%
  row_spec(2, bold = TRUE, background = "#ffffcc") %>%
  footnote(general = " OLS (no penalty). Optimal Lambda selected via 10-fold cross-validation. Lambda = infinte shrinks all coefficients to zero.")

table_lambda_comparison

save_kable(table_lambda_comparison,
           "table_lambda_coefficient_shrinkage.png",
           zoom = 2)






##### Caluclation of R2 #####
# For gold model
pred_gold <- predict(elastic_gold, newx = X_gold, s = "lambda.min")
r2_gold <- cor(y_gold, pred_gold)^2

# For iron ore model
pred_iron <- predict(elastic_iron, newx = X_iron, s = "lambda.min")
r2_iron <- cor(y_iron, pred_iron)^2



# PRE-2022 MODELS
# Filter to pre-2022
base_data_pre <- base_data %>%
  filter(year(Period) < 2022)

# Gold pre-2022
base_data_pre_gold <- base_data_pre %>% filter(Indicator == "Gold")
X_pre_gold <- base_data_pre_gold %>%
  select(Time_Horizon_Months, Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()
y_pre_gold <- base_data_pre_gold$Dispersion_CV_Balanced

elastic_pre_gold <- cv.glmnet(x = X_pre_gold, y = y_pre_gold,
                              alpha = 0.5, nfolds = 10, standardize = TRUE)

pred_pre_gold <- predict(elastic_pre_gold, newx = X_pre_gold, s = "lambda.min")
r2_pre_gold <- cor(y_pre_gold, pred_pre_gold)^2

cat("Gold Pre-2022 R²:", round(r2_pre_gold, 3), "\n")

# Iron Ore pre-2022
base_data_pre_iron <- base_data_pre %>% filter(Indicator == "Iron Ore")
X_pre_iron <- base_data_pre_iron %>%
  select(Time_Horizon_Months, Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()
y_pre_iron <- base_data_pre_iron$Dispersion_CV_Balanced

elastic_pre_iron <- cv.glmnet(x = X_pre_iron, y = y_pre_iron,
                              alpha = 0.5, nfolds = 10, standardize = TRUE)

pred_pre_iron <- predict(elastic_pre_iron, newx = X_pre_iron, s = "lambda.min")
r2_pre_iron <- cor(y_pre_iron, pred_pre_iron)^2

cat("Iron Ore Pre-2022 R²:", round(r2_pre_iron, 3), "\n")


# POST-2022 MODELS
# Filter to post-2022
base_data_post <- base_data %>%
  filter(year(Period) >= 2022)

# Gold post-2022
base_data_post_gold <- base_data_post %>% filter(Indicator == "Gold")
X_post_gold <- base_data_post_gold %>%
  select(Time_Horizon_Months, Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()
y_post_gold <- base_data_post_gold$Dispersion_CV_Balanced

elastic_post_gold <- cv.glmnet(x = X_post_gold, y = y_post_gold,
                               alpha = 0.5, nfolds = 10, standardize = TRUE)

pred_post_gold <- predict(elastic_post_gold, newx = X_post_gold, s = "lambda.min")
r2_post_gold <- cor(y_post_gold, pred_post_gold)^2

cat("Gold Post-2022 R²:", round(r2_post_gold, 3), "\n")

# Iron Ore post-2022
base_data_post_iron <- base_data_post %>% filter(Indicator == "Iron Ore")
X_post_iron <- base_data_post_iron %>%
  select(Time_Horizon_Months, Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()
y_post_iron <- base_data_post_iron$Dispersion_CV_Balanced

elastic_post_iron <- cv.glmnet(x = X_post_iron, y = y_post_iron,
                               alpha = 0.5, nfolds = 10, standardize = TRUE)

pred_post_iron <- predict(elastic_post_iron, newx = X_post_iron, s = "lambda.min")

#model collapse
if(length(unique(pred_post_iron)) == 1) {
  r2_post_iron <- NA
  cat("Iron Ore Post-2022 R²: Cannot calculate (model collapse - all predictions identical)\n")
} else {
  r2_post_iron <- cor(y_post_iron, pred_post_iron)^2
  cat("Iron Ore Post-2022 R²:", round(r2_post_iron, 3), "\n")
}


# SUMMARY TABLE
r2_summary <- data.frame(
  Commodity = c("Gold", "Iron Ore"),
  Pre_2022 = c(r2_pre_gold, r2_pre_iron),
  Post_2022 = c(r2_post_gold, r2_post_iron),
  Change = c(r2_post_gold - r2_pre_gold, 
             ifelse(is.na(r2_post_iron), NA, r2_post_iron - r2_pre_iron))
)

print("\n=== R² SUMMARY ===")
print(r2_summary)




r2_plot_data <- r2_summary %>%
  pivot_longer(cols = c(Pre_2022, Post_2022),
               names_to = "Period",
               values_to = "R_squared") %>%
  mutate(Period = ifelse(Period == "Pre_2022", "Pre-2022", "Post-2022"))

r2_plot <- ggplot(r2_plot_data, aes(x = Period, y = R_squared, 
                                    color = Commodity, group = Commodity)) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 4) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Model Explanatory Power: Pre vs Post-2022",
       subtitle = "R² measures how well model explains forecast dispersion",
       x = "Period",
       y = "R² (Explained Variance)") +
  ylim(0, 0.5) +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA))

r2_plot

ggsave("figure_r2_comparison.png",
       plot = r2_plot,
       width = 8, height = 6, dpi = 300, bg = "white")




#### DF #####
# R2 summary table
r2_table <- r2_summary %>%
  mutate(
    Pre_2022 = sprintf("%.3f", Pre_2022),
    Post_2022 = ifelse(is.na(Post_2022), "—", sprintf("%.3f", Post_2022)),
    Change = ifelse(is.na(Change), "—", sprintf("%.3f", Change)),
    Change_Interpretation = case_when(
      Commodity == "Gold" ~ "Improved",
      Commodity == "Iron Ore" ~ "Collapsed",
      TRUE ~ ""
    )
  )

# formatted table
table_r2_comparison <- r2_table %>%
  kbl(caption = "Table: Model Explanatory Power - Pre vs Post-2022",
      col.names = c("Commodity", "Pre-2022", "Post-2022", "Change", "Interpretation"),
      align = c("l", "r", "r", "r", "l"),
      booktabs = TRUE,
      escape = FALSE) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:2, background = "#FFFFFF") %>%
  add_header_above(c(" " = 1, "R² (Explained Variance)" = 3, " " = 1),
                   background = "#FFFFFF") %>%
  footnote(general = "R² measures proportion of variance in forecast dispersion explained by the model (time horizon, difficulty, volatility, forecaster count). Gold's model improved substantially post-2022 (R² = 0.152 → 0.413). Iron ore's model collapsed completely post-2022 (R² cannot be calculated as all coefficients shrunk to zero).")

table_r2_comparison

save_kable(table_r2_comparison,
           "table_r2_comparison_pre_post.png",
           zoom = 2)

# Simpler version without interpretation column
table_r2_simple <- r2_summary%>%
  mutate(
    Pre_2022 = sprintf("%.3f", Pre_2022),
    Post_2022 = ifelse(is.na(Post_2022), "—", sprintf("%.3f", Post_2022)),
    Change = ifelse(is.na(Change), "—", sprintf("+%.3f", Change))
  ) %>%
  kbl(caption = "Table: Model Explanatory Power (R²) - Pre vs Post-2022",
      col.names = c("Commodity", "Pre-2022 (2016-2021)", "Post-2022 (2022-2025)", "Change"),
      align = c("l", "r", "r", "r"),
      booktabs = TRUE) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:2, background = "#FFFFFF") %>%
  footnote(general = "R² represents proportion of variance in forecast dispersion explained by time horizon, difficulty penalty, volatility, and forecaster count. 
           — indicates model collapse (all coefficients → 0).")

table_r2_simple

save_kable(table_r2_simple,
           "table_r2_comparison_simple.png",
           zoom = 2)
