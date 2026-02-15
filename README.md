---
title: Marketing Analytics Dashboard - Improvado Assignment
emoji: 📊
colorFrom: blue
colorTo: purple
sdk: streamlit
sdk_version: 1.31.0
app_file: dashboard_app_final.py
pinned: false
license: mit
---


# Multi-Channel Advertising Performance Dashboard

**Senior Marketing Analyst Technical Assignment - Improvado**

🔗 **Live Dashboard:** `https://huggingface.co/spaces/panda-greg/marketing-analytics-improvado-tech-assignment`

---

## 📊 Executive Summary

Cross-channel advertising analytics dashboard unifying **Facebook, Google, and TikTok** data (330 records across 3 platforms) with AI-powered insights and strategic recommendations.

### Key Deliverables:
✅ Unified PostgreSQL data model  
✅ AI-generated actionable insights with quantified impact  
✅ Interactive Streamlit dashboard  
✅ Advanced SQL with window functions, CTEs, statistical analysis  

---

## 💡 Data-Driven Insights

### Finding #1: Platform CPA Efficiency
**Facebook delivers 31% lower CPA** ($7.64 vs TikTok's $11.00)

**Recommendation:** Shift $8,633/month from TikTok to Facebook  
**Impact:** +110 conversions/month (8.2% increase)

### Finding #2: Budget Allocation Gap
**TikTok:** 57% budget → 50.5% conversions (-6.5% efficiency gap)  
**Facebook:** 14% budget → 17.9% conversions (+3.9% efficiency gap)

**Action:** Reallocate based on performance, not historical spending

### Finding #3: Top Campaign
**"Influencer_Collab" (TikTok):** 2,653 conversions at $9.92 CPA

**Recommendation:** Scale budget 25-50%

---

## 🤖 AI Productivity Demonstration

**Traditional approach:** 24 hours  
**AI-powered:** 6 hours (**4x faster**)

- SQL query generation: **3 hours → 20 minutes**
- Statistical analysis: **4 hours → 15 minutes**  
- Dashboard development: **6 hours → 3 hours**
- Insight generation: **3 hours → 45 minutes**

---

## 🛠️ Technical Stack

**Database:** PostgreSQL (Supabase)  
**Backend:** Python 3.11+, SQLAlchemy  
**Frontend:** Streamlit + Plotly  
**AI Tools:** Claude AI for analytics acceleration

### Why Streamlit vs Looker/Tableau?
- Demonstrates SQL expertise (all logic in database)
- Enables AI integration
- Faster delivery for assignment
- Transferable BI principles

---

## 🔍 Advanced SQL Examples

### Platform Efficiency with Window Functions
```sql
WITH platform_metrics AS (
    SELECT platform, SUM(cost) as spend, SUM(conversions) as conv
    FROM unified_ads_core GROUP BY platform
)
SELECT 
    platform,
    ROUND((conv::numeric / spend * 1000)::numeric, 2) as efficiency_score,
    RANK() OVER (ORDER BY conv::numeric / spend DESC) as rank
FROM platform_metrics;
```

### Budget Optimization with CTEs
```sql
WITH totals AS (
    SELECT SUM(cost) as total_spend, SUM(conversions) as total_conv
    FROM unified_ads_core
)
SELECT 
    platform,
    ROUND((SUM(cost) / (SELECT total_spend FROM totals) * 100)::numeric, 1) as budget_share,
    ROUND((SUM(conversions) / (SELECT total_conv FROM totals) * 100)::numeric, 1) as conv_share,
    ROUND((conv_share - budget_share)::numeric, 1) as efficiency_gap
FROM unified_ads_core
GROUP BY platform;
```

*Full SQL script with 5 analytical queries: `marketing_analytics_sql.sql`*

---

## 📊 Dashboard Features

- **AI Executive Summary:** One-line cross-platform insight
- **Budget Recommendations:** Data-driven reallocation with expected impact  
- **Efficiency Matrix:** CPA vs Conversion Rate scatter plot
- **Top Campaigns:** Actionable scale/pause recommendations
- **Trend Analysis:** Daily performance with platform comparison

---

## 🚀 Quick Start

```bash
# Install
pip install -r requirements.txt

# Configure database
cp .streamlit/secrets.toml.template .streamlit/secrets.toml
# Add your Supabase credentials

# Run
streamlit run dashboard_app_final.py
```

---

## 📁 Files

- `dashboard_app_final.py` - Main application
- `marketing_analytics_sql.sql` - Complete SQL script
- `requirements.txt` - Dependencies
- `README.md` - Documentation

---

## 🎯 Demonstrates

✅ Advanced SQL (window functions, CTEs, LAG, NTILE)  
✅ BI principles (transferable to Looker/Tableau/Power BI)  
✅ AI productivity (4x time savings)  
✅ Business impact focus (quantified recommendations)  
✅ Client-ready delivery (clear, actionable insights)

---

*Built for Improvado Technical Assignment | AI-Powered Analytics*