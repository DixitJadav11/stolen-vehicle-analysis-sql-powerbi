# stolen-vehicle-analysis-sql-powerbi
SQL + Power BI project to analyze vehicle theft trends by type, region, and time.

# 🚓 Stolen Vehicle Analysis using SQL Server & Power BI

This project analyzes stolen vehicle data using SQL Server and presents interactive insights through Power BI dashboards. The goal is to identify theft patterns and support data-driven decisions for law enforcement and public awareness.

---

## 🎯 Objectives

- Analyze vehicle theft patterns by region, type, color, and time
- Segment vehicles by model age and make type
- Identify high-risk regions and trends
- Present key insights using an interactive Power BI dashboard

---

## 🛠️ Tools & Technologies

- **SQL Server** (Data cleaning, transformation, analysis)
- **Power BI** (Dashboard creation & visualization)

---

## 🗃️ Dataset Structure

- `locations.csv` → Region, country, population, density  
- `stolen_vehicles.csv` → Vehicle type, year, color, theft date  
- `make_details.csv` → Make name and type  

Imported using `BULK INSERT` in SQL Server.

---

## 🧹 SQL Highlights

- ✅ Cleaned malformed dates & standardized datatypes
- ✅ Created **triggers** to log vehicle inserts
- ✅ Used **CTEs**, **views**, and **window functions** for insights
- ✅ Segmented vehicles by age and analyzed theft frequency
- ✅ Identified time-based and regional theft trends

---

## 📈 Key Insights

- 🔹 Vehicle theft is higher in **high-population regions**
- 🔹 Theft is more frequent on **weekdays** (>70%)
- 🔹 Vehicles from **2001–2017** are most targeted
- 🔹 **Black and white** cars are the most stolen colors
- 🔹 **Standard vehicles** dominate theft incidents
- 🔹 Some regions show **increasing theft trends** month-over-month

---

## 📊 Power BI Dashboard

An interactive dashboard was built in Power BI to visually present:
- Total thefts by region and type
- Time-series trend analysis
- Most targeted colors and makes
- Heatmaps by population density and theft count

> 📌 Note: Power BI file included (`.pbix`). View with Power BI Desktop.

---

## 👨‍💻 Author

**Dixit Jadav**  
🎓 Data Scientist & Analyst  
🔗 [LinkedIn](https://www.linkedin.com/in/dixit-jadav)

---

## 📁 Project Structure

├── SQL_Project_stolen_vehicle.sql
├── PowerBI_Report_SQL_Project.pbix
└── README.md


## 💡 Future Scope

- Add predictive analytics using Python or ML models  
- Embed dashboard to a web app using Power BI Embedded  
- Integrate alert system using SQL triggers + email automation  


