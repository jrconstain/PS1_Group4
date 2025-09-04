install.packages("pacman")
install.packages("visdata")
p_load(visdat, #Visualización de data
       rio, # Import/export data.
       tidyverse, # Tidy-data.
       stargazer, # Descriptive statistics.
       gt, # Descriptive statistics.
       gtsummary,
       caret, # For predictive model assessment.
       gridExtra, # Arrange plots.
       skimr,# Summarize data.
       readr, #File search
       dplyr,
       tidyr,
       explore,
       )


# Carga el archivo CSV seleccionado
db <- read_csv(file.choose())
db <- as_tibble(db) |> # tibble: dataframe con características adicionales compatibles con tidyverse

#Selección de las variables de interés
db_clean = db %>% select(y_ingLab_m,y_ingLab_m_ha,y_salary_m,y_salarySec_m,sex,age,maxEducLevel,college,oficio,p6210, p6210s1, p6240,relab,formal, ocu, dsi,totalHoursWorked)

#Indicamos quienes tienen un salario reportado
db_clean <- db_clean |>
  mutate(
    bin_ingLab_m     = ifelse(y_ingLab_m > 0, 1, 0),
    bin_ingLab_m_ha  = ifelse(y_ingLab_m_ha > 0, 1, 0)
  )

# Validación: todo el que tenga ingreso salarial debe tener ingreso salarial por hora
ftable(db_clean$bin_ingLab_m, db_clean$bin_ingLab_m_ha)

# Filtrar menores de 18 años y personas que no reciben salario
db_clean <- db_clean |>
  filter(age > 18, bin_ingLab_m == 1, bin_ingLab_m_ha == 1)

#Eliminar variables de control
db_clean = db_clean %>% select(y_ingLab_m,y_ingLab_m_ha,y_salary_m,y_salarySec_m,sex,age,maxEducLevel,college,oficio,p6210, p6210s1, p6240,relab,formal, ocu, dsi,totalHoursWorked)
# Renombrar las variables para que tengan un patrón común

db_clean <- db_clean %>%
  rename(
    bin_male = sex,
    Total_salary = y_ingLab_m,
    Total_hour_salary = y_ingLab_m_ha) 

# Dimensiones y head de nuestros datos iniciales de trabajo
dim(db_clean)
head(db_clean)

# Variables de verificación
db_clean <- db_clean %>% 
        filter(db_clean$totalHoursWorked>0) %>%
        mutate(Log_Total_hour_salary=log(db_clean$Total_hour_salary))

# Valores faltantes en variables de interés
  cat("Valores faltantes nivel educativo:", sum(is.na(db_clean$maxEducLevel)), "\n") # cuantos na hay en maxEducLevel
  cat("Valores faltantes oficio:", sum(is.na(db_clean$oficio )), "\n") # cuantos na hay en
  cat("Valores faltantes formalidad:", sum(is.na(db_clean$formal)), "\n") # cuantos na hay en

# Valores faltantes en variables de interés
  cat("Valores faltantes nivel educativo:", sum(is.na(db_clean$maxEducLevel)), "\n") # cuantos na hay en maxEducLevel
  cat("Valores faltantes oficio:", sum(is.na(db_clean$oficio )), "\n") # cuantos na hay en
  cat("Valores faltantes formalidad:", sum(is.na(db_clean$formal)), "\n") # cuantos na hay en

# si maxEducLevel es na pone 1, si no lo deja como está
  db_clean <- db_clean |> mutate(maxEducLevel = ifelse(is.na(maxEducLevel) == TRUE, 1 , maxEducLevel))

#Data Exploration 
explore(db_clean)

#Missing values
db_miss <- skim(db_clean) %>% select(skim_variable, n_missing)
Nobs <- nrow(db_clean) 
db_miss<- db_miss %>% mutate(p_missing= n_missing/Nobs)
head(db_miss)
db_miss <- db_miss %>% arrange(-n_missing)
### Keep only variables with missing 
db_miss<- db_miss %>% filter(n_missing!= 0)
head(db_miss, 3)
#Solamente el salario secundario cuenta con missing values.
vis_dat(db_clean)

#Validar outliers en horas
low <- mean(db_clean$totalHoursWorked) - 2 * sd(db_clean$totalHoursWorked)
up <- mean(db_clean$totalHoursWorked) + 2 * sd(db_clean$totalHoursWorked)

db_clean <- db_clean %>% 
  mutate(out_totalHoursWorked = ifelse(test = (totalHoursWorked < low | totalHoursWorked > up), 
                                       yes = 1,
                                       no = 0))
db_outliers <- db_clean %>% 
  filter(out_totalHoursWorked==1)

#Validar outliers en ingreso
low_y <- mean(db_clean$Total_salary) - 2 * sd(db_clean$Total_salary)
up_y <- mean(db_clean$Total_salary) + 2 * sd(db_clean$Total_salary)

db_clean <- db_clean %>% 
  mutate(out_Total_salary = ifelse(test = (Total_salary < low_y | Total_salary > up_y), 
                                       yes = 1,
                                       no = 0))
db_outliersy <- db_clean %>% 
  filter(out_Total_salary==1)
