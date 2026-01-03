# IJC437 Data Visualisation Project  
## Business Births, Deaths and Labour Market Dynamics in Yorkshire (2018–2023)

### Overview

This project explores regional business dynamics in England using official ONS and Nomis data.  
I examine how **business birth and death rates** in *Yorkshire and The Humber* compare with the **North East** and **West Midlands** between 2018 and 2023, and whether these dynamics are associated with regional labour market levels.

This project forms part of my IJC437 Data Visualisation coursework and demonstrates practical skills in:

- data wrangling in R (tidyverse)
- exploratory data analysis
- economic interpretation of official statistics
- visual communication of insights

---

## 📌 Research questions

1. **How do business birth and death rates in Yorkshire and The Humber compare with other English regions between 2018 and 2023?**

2. **To what extent are business births, deaths, and net change associated with regional labour market (employment) levels?**

---

## 🧭 Data sources

- **ONS Business Demography** tables, 2018–2023  
  – business births, business deaths by region

- **Nomis labour market statistics**  
  – employment counts for:
  - Yorkshire and The Humber  
  - North East  
  - West Midlands  

Both datasets were cleaned and combined in R.

---

## 🔎 Methods (what I did)

- imported raw Excel data in R using `readxl`
- cleaned and standardised region and year labels
- aggregated births and deaths to **region–year level**
- merged with regional employment data from Nomis
- calculated:
  - births per 100,000 employed
  - deaths per 100,000 employed
  - **net change** = births − deaths
- produced:
  - summary statistics
  - time-series plots
  - correlation analysis
  - a simple linear regression for Yorkshire

All analysis is reproducible in the R script in this repository.

---

## 📊 Key findings

### ⭐ Regional comparison (2018–2023 averages)

Mean net business creation per 100,000 employed:

| Region | Mean births | Mean deaths | **Mean net change** |
|--------|-------------|-------------|----------------------|
| North East | 855 | 774 | **+80.8** |
| West Midlands | 1122 | 1079 | **+42.9** |
| **Yorkshire and The Humber** | 939 | 848 | **+91.3** |

**Interpretation**

- Yorkshire and The Humber recorded the **strongest net business growth** of the three regions
- West Midlands had the **highest churn** (high births and high deaths)
- North East had the **lowest birth rates**, but still positive net growth

---

### 🔗 Association with labour market levels

Correlation between labour levels and business dynamics:

| Region | Births vs labour | Deaths vs labour | Net change vs labour |
|--------|------------------|------------------|----------------------|
| North East | −0.18 | +0.51 | **−0.61** |
| West Midlands | −0.49 | −0.02 | **−0.39** |
| **Yorkshire and The Humber** | +0.10 | **+0.87** | **−0.82** |

**Interpretation**

- In Yorkshire:
  - business **deaths increase strongly** when labour levels are higher  
  - net business change is **strongly negative when employment is higher**
- Across regions overall:
  - there is **no universal positive link** between empl
