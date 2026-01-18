library(glmnet)
library
library(kableExtra)

setwd("C:/PATH")

# Split data by commodity
base_data_gold <- base_data %>% filter(Indicator == "Gold")
base_data_iron <- base_data %>% filter(Indicator == "Iron Ore")

# Create matrices for Gold
X_gold <- base_data_gold %>%
  select(Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters_Balanced) %>%
  as.matrix()

y_gold <- base_data_gold$Dispersion_CV_Balanced

# Create matrices for Iron Ore
X_iron <- base_data_iron %>%
  select(Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters_Balanced) %>%
  as.matrix()

y_iron <- base_data_iron$Dispersion_CV_Balanced

# Check dimensions
cat("Gold: X rows =", nrow(X_gold), ", y length =", length(y_gold), "\n")
cat("Iron Ore: X rows =", nrow(X_iron), ", y length =", length(y_iron), "\n")

# Fit commodity-specific models
set.seed(123)

elastic_gold <- cv.glmnet(
  x = X_gold,
  y = y_gold,
  alpha = 0.5,
  nfolds = 10,
  standardize = TRUE
)

elastic_iron <- cv.glmnet(
  x = X_iron,
  y = y_iron,
  alpha = 0.5,
  nfolds = 10,
  standardize = TRUE
)

# results
cat("\n=== GOLD MODEL ===\n")
print(coef(elastic_gold, s = "lambda.min"))

cat("\n=== IRON ORE MODEL ===\n")
print(coef(elastic_iron, s = "lambda.min"))

# Calculate R2
pred_gold <- predict(elastic_gold, newx = X_gold, s = "lambda.min")
r2_gold <- cor(y_gold, pred_gold)^2

pred_iron <- predict(elastic_iron, newx = X_iron, s = "lambda.min")
r2_iron <- cor(y_iron, pred_iron)^2

cat("\n=== MODEL FIT ===\n")
cat("Gold R²:", round(r2_gold, 3), "\n")
cat("Iron Ore R²:", round(r2_iron, 3), "\n")

# Save models
saveRDS(elastic_gold, "elastic_gold.rds")
saveRDS(elastic_iron, "elastic_iron.rds")




# comparison table
commodity_results <- data.frame(
  Variable = c("Time Horizon (months)",
               "Difficulty Penalty (0-1)",
               "Rolling Volatility (3-month)",
               "Number of Forecasters",
               "",
               "Observations",
               "R²"),
  Gold = c(
    "0.133",
    "1.175",
    "-0.158",
    "0.283",
    "",
    as.character(length(y_gold)),
    "0.213"
  ),
  `Iron Ore` = c(
    "0.050",
    "2.817",
    "0.123",
    "1.245",
    "",
    as.character(length(y_iron)),
    "0.107"
  ),
  check.names = FALSE
)


table_9_4 <- commodity_results %>%
  kbl(caption = "Table 9.4: Commodity-Specific Model Results (Elastic Net)",
      col.names = c("Variable", "Gold", "Iron Ore"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(commodity_results), background = "#FFFFFF") %>%
  row_spec(5, hline_after = TRUE) %>%
  add_header_above(c(" " = 1, "Dependent Variable: Dispersion (CV %)" = 2),
                   background = "#FFFFFF")


table_9_4

table_9_4 %>%
  save_kable("table_9_4_commodity_specific.png",
             zoom = 3, density = 300)







library(ggplot2)
library(tidyr)

# Create comparison data
coef_comparison <- data.frame(
  Variable = c("Time Horizon", "Difficulty Penalty", "Volatility", "N Forecasters"),
  Gold = c(0.133, 1.175, -0.158, 0.283),
  `Iron Ore` = c(0.050, 2.817, 0.123, 1.245),
  check.names = FALSE
)

# Reshape for plotting
coef_long <- coef_comparison %>%
  pivot_longer(cols = c(Gold, `Iron Ore`), 
               names_to = "Commodity", 
               values_to = "Coefficient")

# Create comparison plot
fig_9_4 <- ggplot(coef_long, aes(x = Variable, y = Coefficient, fill = Commodity)) +
  geom_col(position = "dodge", alpha = 0.8, width = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  coord_flip() +
  scale_fill_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(title = "Figure 9.4: Coefficient Comparison by Commodity",
       subtitle = "Elastic net regression results (without time trend)",
       x = "Variable",
       y = "Coefficient",
       fill = "Commodity") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major.x = element_line(color = "gray90"))

fig_9_4

ggsave("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/fig_9_4_commodity_comparison.png",
       fig_9_4, width = 8, height = 5, dpi = 300, bg = "white")
