install.packages("pacman")
library(pacman)

p_load(rio, # Import/export data.
       tidyverse, # Tidy-data.
       stargazer, # Descriptive statistics.
       gt, # Descriptive statistics.
       gtsummary,
       caret, # For predictive model assessment.
       gridExtra, # Arrange plots.
       skimr,# Summarize data.
       readr #File search
)

# Abre una ventana para seleccionar el archivo
archivo <- file.choose()

# Carga el archivo CSV seleccionado
db <- read_csv(archivo)

db <- read_csv("data.csv")
db <- as_tibble(db) |> # tibble: dataframe con características adicionales compatibles con tidyverse
  rename(bin_male = sex) # renombrar variable
# Indicamos quienes tienen un salario reportado
db <- db |>
  mutate(
    bin_ingLab_m     = ifelse(y_ingLab_m > 0, 1, 0),
    bin_ingLab_m_ha  = ifelse(y_ingLab_m_ha > 0, 1, 0)
  )

# Validación: todo el que tenga ingreso salarial debe tener ingreso salarial por hora
ftable(db$bin_ingLab_m, db$bin_ingLab_m_ha)
# Filtrar menores de 18 años y personas que no reciben salario
db <- db |>
  filter(age > 18, bin_ingLab_m == 1, bin_ingLab_m_ha == 1)

db_clean= db %>% select(y_salary_m_hu,y_salary_m,y_salarySec_m,bin_male,age,maxEducLevel,college,oficio, p6240,relab,formal, ocu, dsi, hoursWorkUsual, hoursWorkActualSecondJob)



db_clean <- db_clean %>%
  rename(hoursWorkActualPrimaryJob=hoursWorkUsual)%>%
  mutate(y_salarySec_m_hu = y_salarySec_m / (hoursWorkActualSecondJob * (30 / 7))) 
# Dimensiones y head de nuestros datos iniciales de trabajo
dim(db_clean)
head(db_clean)

#despivoteo


library(dplyr)
library(tidyr)

# Renombrar las variables para que tengan un patrón común

db_clean <- db_clean %>%
  rename(
    salary_m_prim = y_salary_m,
    salary_hu_prim = y_salary_m_hu,
    hours_prim = hoursWorkActualPrimaryJob,
    salary_m_sec = y_salarySec_m,
    salary_hu_sec = y_salarySec_m_hu,
    hours_sec = hoursWorkActualSecondJob
  ) %>%
  mutate(id = seq_len(n()))



# Despivotear usando patrón más robusto
db_long <- db_clean %>%
  pivot_longer(
    cols = matches("_(prim|sec)$"),
    names_to = c("variable", "tipo_empleo"),
    names_pattern = "(.*)_(prim|sec)"
  ) %>%
  pivot_wider(
    names_from = variable,
    values_from = value
  )%>% filter(db_long$salary_m>0) 
db_long <-db_long%>% filter(db_long$hours>0)%>% mutate(checksalaryhours=db_long$salary_m/(db_long$hours*(30/7)))


    
# Valores faltantes en variables de interés
cat("Valores faltantes nivel educativo:", sum(is.na(db_long$maxEducLevel)), "\n") # cuantos na hay en maxEducLevel
cat("Valores faltantes oficio:", sum(is.na(db_long$oficio )), "\n") # cuantos na hay en
cat("Valores faltantes formalidad:", sum(is.na(db_long$formal)), "\n") # cuantos na hay en

# Valores faltantes en variables de interés
  cat("Valores faltantes nivel educativo:", sum(is.na(db_long$maxEducLevel)), "\n") # cuantos na hay en maxEducLevel
cat("Valores faltantes oficio:", sum(is.na(db_long$oficio )), "\n") # cuantos na hay en
cat("Valores faltantes formalidad:", sum(is.na(db_long$formal)), "\n") # cuantos na hay en
 # si maxEducLevel es na pone 1, si no lo deja como está
  db_long <- db_long |> mutate(maxEducLevel = ifelse(is.na(maxEducLevel) == TRUE, 1 , maxEducLevel))
# Binwidth para y_ingLab_m
bw_m <- 3.5 * sd(db_long$y_ingLab_m, na.rm = TRUE) / length(na.omit(db_long$y_ingLab_m))^(1/3)
bw_m <- round(bw_m, 2)

# Binwidth para y_ingLab_m_ha
bw_m_ha <- 3.5 * sd(db_long$y_ingLab_m_ha, na.rm = TRUE) / length(na.omit(db_long$y_ingLab_m_ha))^(1/3)
bw_m_ha <- round(bw_m_ha, 2)

hist_m <- ggplot(db_long, aes(x = y_ingLab_m)) +
  geom_histogram(aes(y = after_stat(count) / sum(after_stat(count))),
                 binwidth = bw_m, fill = "#3a5e8cFF", color = "white", alpha = 0.8,
                 na.rm = TRUE, linewidth = 0.2) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.05))) +
  scale_x_continuous(expand = expansion(mult = c(0, 0)), limits = c(0, NA)) +
  geom_vline(aes(xintercept = mean(y_ingLab_m, na.rm = TRUE)), color = "red", linetype = "dashed") +
  geom_vline(aes(xintercept = median(y_ingLab_m, na.rm = TRUE)), color = "green", linetype = "dashed") +
  labs(x = "Ingreso Laboral Mensual", y = "Frecuencia relativa (%)") +
  theme_classic()

hist_m_ha <- ggplot(db_long, aes(x = y_ingLab_m_ha)) +
  geom_histogram(aes(y = after_stat(count) / sum(after_stat(count))),
                 binwidth = bw_m_ha, fill = "#3a5e8cFF", color = "white", alpha = 0.8,
                 na.rm = TRUE, linewidth = 0.2) +
  scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.05))) +
  scale_x_continuous(expand = expansion(mult = c(0, 0)), limits = c(0, NA)) +
  geom_vline(aes(xintercept = mean(y_ingLab_m_ha, na.rm = TRUE)), color = "red", linetype = "dashed") +
  geom_vline(aes(xintercept = median(y_ingLab_m_ha, na.rm = TRUE)), color = "green", linetype = "dashed") +
  labs(x = "Ingreso Laboral Horas Ajustadas", y = "Frecuencia relativa (%)") +
  theme_classic()

grid.arrange(hist_m, hist_m_ha, nrow = 2)
box_m <- ggplot(db_long, aes(y = y_ingLab_m)) +
  geom_boxplot(fill = "#3a5e8cFF", color = "black", na.rm = TRUE) +
  coord_flip() +
  labs(y = "Ingreso Laboral Mensual") +
  theme_classic()

box_m_ha <- ggplot(db_long, aes(y = y_ingLab_m_ha)) +
  geom_boxplot(fill = "#3a5e8cFF", color = "black", na.rm = TRUE) +
  coord_flip() +
  labs(y = "Ingreso Laboral Horas Ajustadas") +
  theme_classic()

grid.arrange(box_m, box_m_ha, nrow = 2)
skimr::skim(db_long[, c("y_ingLab_m", "y_ingLab_m_ha")])
