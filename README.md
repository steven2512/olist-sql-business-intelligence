# Olist SQL Business Intelligence

End-to-end SQL analysis of 100k+ real Brazilian e-commerce orders  
across 6 business themes: business performance, customer behaviour,  
seller quality, product intelligence, logistics, and payments.  
Built with Microsoft SQL Server.

---

## Project Status
In Progress - EDA Phase

---

## Assumptions and Definitions

> Read this before interpreting any figures in this project.

**Perspective:** All analysis is framed around what Olist as the marketplace operator can influence, incentivise, or act upon.

**GMV / Revenue:** Throughout this project, GMV is defined as total customer payment value per delivered order, inclusive of freight. GMV and revenue are used interchangeably. Source column: `payment_value` (payments table).

**Commission rate:** During the dataset period (Sep 2016 to Oct 2018), Olist's commission covered partner marketplace fees (~18%) plus its own operational margin (3% to 5%), applied to the full order value including freight. This project uses a conservative midpoint of **~20%** as the effective commission rate.

> The 10% figure commonly cited in Kaggle notebooks is not supported by Olist's official documentation and is not used here.

**Scope:** Confirmed and successfully delivered orders only. Cancelled, unavailable, or undelivered orders are excluded from all calculations.

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