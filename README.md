# Problem Set 1 - Group 4  
**Understanding and Predicting Wages: Evidence from Bogotá**

This repository corresponds to the **solution of Group 4** for **Problem Set 1** of the course *Big Data and Machine Learning for Applied Economics*.  
Our work focuses on **predicting wages using linear regression models** based on data of the GEIH 2018 collected in Bogotá.   

---

## 📂 Repository structure  

The repository follows the required template and includes the following folders:  

- **document/**  
  Contains the final document *Understanding and Predicting Wages. Evidence from Bogotá.* in PDF format: `PS1_G4_Final.pdf`.
  All tables and figures included in the document are referenced from the `views` folder.  

- **scripts/**  
  Contains all project scripts:  
  - `scrape.py`: script used to perform the **scraping** of the dataset.  
  - `PS1_G4_Final_Code.Rmd`: main code that runs the full workflow, from loading the data to producing the analysis. This script takes inputs from the `stores` folder.  

- **stores/**  
  Contains the datasets used in the project:  
  - `raw/`: holds the original scraped files (`page1.csv` to `page10.csv`), which correspond to the ten pages obtained during the scraping process.  
  - `data.csv`: merged dataset containing the 32,177 observations (all ten pages combined), which serves as the main input for the final script (`PS1_G4_Final_Code.Rmd`).
  - `dictionary.csv`, `labels.csv`: auxiliary files describing the variables.  
  - `db_clean1.csv`: cleaned dataset generated during processing.  

- **views/**  
  Contains all **tables, figures, and images** included in the final document.  

---

## ⚙️ Instructions to replicate  

1. **Clone this repository**  
   ```bash
   git clone https://github.com/jrconstain/PS1_Group4.git
   cd PS1_Group4
   ```

2. **Install dependencies**  
   Make sure you have R, RStudio (or equivalent), and Python (for scraping) installed.  
   - R packages: `tidyverse`, `knitr`, `ggplot2`  
   - Python packages: `requests`, `pandas`, `selenium`, `beautifulsoup4`  

3. **Run the scraping**  
   - Execute `scripts/scrape.py` to generate the initial dataset.  

4. **Run the full analysis**  
   - Open and run `scripts/PS1_G4_Final_Code.Rmd` to reproduce all results, which will be stored in `stores/` and `views/`.  

---

## 📑 Final document  

The main document is located in the `document/` folder:  
- `PS1_G4_Final.pdf`: *Understanding and Predicting Wages. Evidence from Bogotá.*  

This file includes the theoretical framework, methodology, results, and conclusions of the project.  

---

## 📌 Notes  

- The dataset `data.csv` in `stores` corresponds to a merge of all the ten scraped pages.  
- Other files in `stores/` allow tracing the cleaning, coding, and analysis workflow.  
- This repository follows the structure and recommendations of the **Problem Set Template Repository** for the course.  
