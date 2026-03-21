# Olist SQL Business Intelligence

End-to-end SQL analysis of 100k+ real Brazilian e-commerce orders  
across 6 business themes: business performance, customer behaviour,  
seller quality, product intelligence, logistics, and payments.  
Built with Microsoft SQL Server.

---

## Project Status
🔄 In Progress — EDA Phase

---

## Analytical Perspective & Key Assumptions

> **Read this before interpreting any metrics or revenue figures in this project.**

### Perspective
This analysis is conducted from the perspective of **Olist as the marketplace operator**. All metrics, interpretations, and recommendations are framed around what Olist — as the platform — can influence, incentivize, or act upon. The goal is to provide actionable business intelligence to help Olist maximise platform revenue, identify growth opportunities across product categories and regions, and improve seller and customer retention.

### GMV Definition
GMV is defined as **total customer payment value per delivered order, inclusive of freight**. This aligns with how Olist calculated commission during the dataset period (September 2016 – October 2018).

| Metric | Definition | Source Column(s) |
|---|---|---|
| GMV | Total customer payment value per delivered order, inclusive of freight | `payment_value` (payments table) |
| Olist Estimated Revenue | GMV × effective commission rate (~20% midpoint) | Derived |
| Freight Value | Shipping cost component, included in GMV | `freight_value` (order_items table) |
| Pure Product Value | Item price declared by seller, excluding freight | `price` (order_items table) |

### Commission Rate
Olist's commission during the dataset period covered partner marketplace fees (~18%) plus Olist's own operational margin (3%–5%), resulting in an effective total rate of approximately **19%–23% of GMV (product + freight combined)**. A conservative midpoint of **~20%** is used in this analysis where commission estimation is required.

> ⚠️ The commonly cited **10% commission figure** found in Kaggle notebooks and community analyses is likely a significant underestimate and does not appear to be supported by Olist's official documentation. It should not be used for revenue estimation.

### Commission Model Changed in February 2021 (Post-Dataset)
Olist restructured their fee model after the dataset period ended. From February 16, 2021 onwards, commission applies to **product value only** (freight excluded), and a tiered structure was introduced. This project does not apply the post-2021 model, as the dataset pre-dates that change.

### Scope
Analysis covers **confirmed and successfully delivered orders only**. Cancelled, unavailable, or undelivered orders are excluded from all revenue and GMV calculations.

---

## Dataset
- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Size:** 100k+ orders across 9 tables
- **Period:** September 2016 to October 2018
- **Context:** Olist is a Brazilian marketplace connecting small businesses to customers nationwide

---

## Tools
- Microsoft SQL Server
- Git / GitHub

---

## Project Structure
| Folder | Purpose |
|---|---|
| 01_eda | Database exploration and data quality checks |
| 02_analytics | Business themed analysis across 6 themes |
| 03_reports | Consolidated customer, product and seller reports |
| 04_validation | Cross checks to verify numbers are correct |

---

## Findings
*To be updated upon completion of analysis phase.*

---

## References
- Olist. (n.d.). *Comissão e frete: As 3 regras que você precisa saber.* https://blog.olist.com/3-regras-comissao-e-frete-olist/
- Bling Blog. (2022, March 7). *Nova regra de comissão e frete do Olist.* https://blog.bling.com.br/nova-regra-de-comissao-e-frete-do-olist-como-funciona-e-quais-sao-as-vantagens/
- Chen, D., Sakia, S., & Olist. (2018). *Brazilian E-Commerce Public Dataset by Olist* [Dataset]. Kaggle. https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

---

## Author
Nguyen Duong  
[GitHub](https://github.com/steven2512) · [LinkedIn](https://www.linkedin.com/in/nguyenduong251202/)