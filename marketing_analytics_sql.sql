-- ============================================
-- Marketing Analytics Assignment - SQL Script
-- Multi-Channel Advertising Data Integration
-- ============================================

-- Author: Grigory Yakushev
-- Date: February 2026
-- Purpose: Unify Facebook, Google, and TikTok advertising data for cross-platform analysis

-- ============================================
-- 1. DATA QUALITY CHECKS
-- ============================================

-- Check for NULL dates and data integrity
SELECT 
    'facebook_ads' as source_table,
    COUNT(*) as total_rows,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) as null_dates,
    SUM(CASE WHEN spend < 0 THEN 1 ELSE 0 END) as negative_spend,
    SUM(CASE WHEN conversions < 0 THEN 1 ELSE 0 END) as negative_conversions,
    MIN(date) as earliest_date,
    MAX(date) as latest_date
FROM facebook_ads

UNION ALL

SELECT 
    'google_ads',
    COUNT(*),
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN cost < 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN conversions < 0 THEN 1 ELSE 0 END),
    MIN(date),
    MAX(date)
FROM google_ads

UNION ALL

SELECT 
    'tiktok_ads',
    COUNT(*),
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN cost < 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN conversions < 0 THEN 1 ELSE 0 END),
    MIN(date),
    MAX(date)
FROM tiktok_ads;


-- ============================================
-- 2. CREATE UNIFIED ADVERTISING TABLE
-- ============================================

DROP TABLE IF EXISTS unified_ads_core CASCADE;

CREATE TABLE unified_ads_core AS
SELECT 
    'Facebook' as platform,
    date,
    campaign_name,
    spend as cost,  -- Standardize column name
    impressions,
    clicks,
    conversions,
    -- Calculate derived metrics with safe division
    CASE 
        WHEN impressions > 0 
        THEN ROUND((CAST(clicks AS numeric) / impressions * 100)::numeric, 2)
        ELSE 0 
    END as ctr,
    CASE 
        WHEN clicks > 0 
        THEN ROUND((CAST(spend AS numeric) / clicks)::numeric, 2)
        ELSE 0 
    END as cpc,
    CASE 
        WHEN conversions > 0 
        THEN ROUND((CAST(spend AS numeric) / conversions)::numeric, 2)
        ELSE 0 
    END as cpa
FROM facebook_ads
WHERE date IS NOT NULL  -- Ensure data quality
  AND spend >= 0        -- Filter invalid data
  AND conversions >= 0

UNION ALL

SELECT 
    'Google' as platform,
    date,
    campaign_name,
    cost,
    impressions,
    clicks,
    conversions,
    CASE WHEN impressions > 0 THEN ROUND((CAST(clicks AS numeric) / impressions * 100)::numeric, 2) ELSE 0 END as ctr,
    CASE WHEN clicks > 0 THEN ROUND((CAST(cost AS numeric) / clicks)::numeric, 2) ELSE 0 END as cpc,
    CASE WHEN conversions > 0 THEN ROUND((CAST(cost AS numeric) / conversions)::numeric, 2) ELSE 0 END as cpa
FROM google_ads
WHERE date IS NOT NULL
  AND cost >= 0
  AND conversions >= 0

UNION ALL

SELECT 
    'TikTok' as platform,
    date,
    campaign_name,
    cost,
    impressions,
    clicks,
    conversions,
    CASE WHEN impressions > 0 THEN ROUND((CAST(clicks AS numeric) / impressions * 100)::numeric, 2) ELSE 0 END as ctr,
    CASE WHEN clicks > 0 THEN ROUND((CAST(cost AS numeric) / clicks)::numeric, 2) ELSE 0 END as cpc,
    CASE WHEN conversions > 0 THEN ROUND((CAST(cost AS numeric) / conversions)::numeric, 2) ELSE 0 END as cpa
FROM tiktok_ads
WHERE date IS NOT NULL
  AND cost >= 0
  AND conversions >= 0;


-- ============================================
-- 3. CREATE PERFORMANCE INDEXES
-- ============================================

CREATE INDEX idx_unified_platform ON unified_ads_core(platform);
CREATE INDEX idx_unified_date ON unified_ads_core(date);
CREATE INDEX idx_unified_campaign ON unified_ads_core(campaign_name);
CREATE INDEX idx_unified_date_platform ON unified_ads_core(date, platform);  -- Composite index for common queries


-- ============================================
-- 4. VERIFICATION QUERIES
-- ============================================

-- Row counts by platform
SELECT 
    platform,
    COUNT(*) as row_count,
    COUNT(DISTINCT date) as distinct_dates,
    COUNT(DISTINCT campaign_name) as distinct_campaigns
FROM unified_ads_core
GROUP BY platform;

-- Basic performance metrics
SELECT 
    platform,
    ROUND(SUM(cost)::numeric, 2) as total_spend,
    SUM(conversions) as total_conversions,
    ROUND((SUM(cost) / NULLIF(SUM(conversions), 0))::numeric, 2) as avg_cpa,
    ROUND((SUM(clicks)::numeric / NULLIF(SUM(impressions), 0) * 100), 2) as avg_ctr
FROM unified_ads_core
GROUP BY platform
ORDER BY total_spend DESC;


-- ============================================
-- 5. ANALYTICAL QUERIES
-- ============================================

-- Query 1: Platform Efficiency Analysis
-- Identifies which platform delivers best ROI
WITH platform_metrics AS (
    SELECT 
        platform,
        SUM(cost) as total_spend,
        SUM(conversions) as total_conversions,
        SUM(clicks) as total_clicks,
        SUM(impressions) as total_impressions
    FROM unified_ads_core
    GROUP BY platform
)
SELECT 
    platform,
    total_spend,
    total_conversions,
    ROUND((CAST(total_conversions AS numeric) / total_spend * 1000)::numeric, 2) as efficiency_score,  -- Conversions per $1000
    ROUND((total_spend / NULLIF(total_conversions, 0))::numeric, 2) as cpa,
    ROUND((CAST(total_clicks AS numeric) / NULLIF(total_impressions, 0) * 100)::numeric, 2) as ctr,
    ROUND((CAST(total_conversions AS numeric) / NULLIF(total_clicks, 0) * 100)::numeric, 2) as conversion_rate,
    RANK() OVER (ORDER BY CAST(total_conversions AS numeric) / total_spend DESC) as efficiency_rank
FROM platform_metrics
ORDER BY efficiency_rank;


-- Query 2: Budget Allocation Recommendation
-- Compares actual budget share vs performance share
WITH totals AS (
    SELECT 
        SUM(cost) as total_spend,
        SUM(conversions) as total_conversions
    FROM unified_ads_core
),
platform_performance AS (
    SELECT 
        platform,
        SUM(cost) as platform_spend,
        SUM(conversions) as platform_conversions,
        ROUND((SUM(cost) / (SELECT total_spend FROM totals) * 100)::numeric, 1) as budget_share,
        ROUND((SUM(conversions) / (SELECT total_conversions FROM totals) * 100)::numeric, 1) as conversion_share
    FROM unified_ads_core
    GROUP BY platform
)
SELECT 
    platform,
    budget_share,
    conversion_share,
    ROUND((conversion_share - budget_share)::numeric, 1) as efficiency_gap,
    CASE 
        WHEN conversion_share - budget_share > 5 THEN 'INCREASE BUDGET'
        WHEN conversion_share - budget_share < -5 THEN 'DECREASE BUDGET'
        ELSE 'MAINTAIN'
    END as recommendation,
    -- Calculate suggested reallocation amount (based on 10% of total budget)
    CASE 
        WHEN conversion_share - budget_share > 5 
        THEN CONCAT('+$', ROUND(((SELECT total_spend FROM totals) * 0.1)::numeric, 0))
        WHEN conversion_share - budget_share < -5 
        THEN CONCAT('-$', ROUND(((SELECT total_spend FROM totals) * 0.1)::numeric, 0))
        ELSE '$0'
    END as suggested_change
FROM platform_performance
ORDER BY efficiency_gap DESC;


-- Query 3: Top Performing Campaigns
-- Identifies campaigns to scale vs pause
WITH campaign_performance AS (
    SELECT 
        campaign_name,
        platform,
        SUM(cost) as spend,
        SUM(conversions) as conversions,
        SUM(clicks) as clicks,
        ROUND((SUM(cost) / NULLIF(SUM(conversions), 0))::numeric, 2) as cpa,
        ROUND((SUM(conversions)::numeric / NULLIF(SUM(clicks), 0) * 100)::numeric, 2) as conversion_rate
    FROM unified_ads_core
    WHERE conversions > 0  -- Only campaigns with conversions
    GROUP BY campaign_name, platform
),
performance_quartiles AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY cpa) as cpa_quartile,
        AVG(cpa) OVER () as median_cpa
    FROM campaign_performance
)
SELECT 
    campaign_name,
    platform,
    spend,
    conversions,
    cpa,
    conversion_rate,
    CASE cpa_quartile
        WHEN 1 THEN 'SCALE - Top Performer'
        WHEN 2 THEN 'MAINTAIN - Above Average'
        WHEN 3 THEN 'OPTIMIZE - Below Average'
        WHEN 4 THEN 'PAUSE - Poor Performer'
    END as recommendation,
    ROUND((cpa / NULLIF(median_cpa, 0))::numeric, 2) as cpa_vs_median
FROM performance_quartiles
ORDER BY cpa_quartile, conversions DESC;


-- Query 4: Temporal Performance Analysis
-- Finds best days of week for each platform
SELECT 
    platform,
    TO_CHAR(date::date, 'Day') as day_of_week,
    EXTRACT(ISODOW FROM date::date) as dow_number,
    COUNT(DISTINCT date) as num_days,
    ROUND(AVG(cpa)::numeric, 2) as avg_cpa,
    ROUND(AVG(ctr)::numeric, 2) as avg_ctr,
    SUM(conversions) as total_conversions,
    ROUND(SUM(cost)::numeric, 2) as total_spend
FROM unified_ads_core
WHERE conversions > 0
GROUP BY platform, TO_CHAR(date::date, 'Day'), EXTRACT(ISODOW FROM date::date)
ORDER BY platform, dow_number;


-- Query 5: Performance Trend Analysis
-- Detects week-over-week changes
WITH weekly_performance AS (
    SELECT 
        platform,
        EXTRACT(WEEK FROM date::date) as week_number,
        EXTRACT(YEAR FROM date::date) as year,
        SUM(cost) as weekly_spend,
        SUM(conversions) as weekly_conversions,
        ROUND((SUM(cost) / NULLIF(SUM(conversions), 0))::numeric, 2) as weekly_cpa
    FROM unified_ads_core
    GROUP BY platform, EXTRACT(WEEK FROM date::date), EXTRACT(YEAR FROM date::date)
),
weekly_trends AS (
    SELECT 
        platform,
        week_number,
        year,
        weekly_cpa,
        LAG(weekly_cpa) OVER (PARTITION BY platform ORDER BY year, week_number) as prev_week_cpa,
        weekly_conversions,
        LAG(weekly_conversions) OVER (PARTITION BY platform ORDER BY year, week_number) as prev_week_conversions
    FROM weekly_performance
)
SELECT 
    platform,
    week_number,
    weekly_cpa,
    prev_week_cpa,
    ROUND(((weekly_cpa - prev_week_cpa) / NULLIF(prev_week_cpa, 0) * 100)::numeric, 1) as cpa_change_pct,
    weekly_conversions,
    CASE 
        WHEN ((weekly_cpa - prev_week_cpa) / NULLIF(prev_week_cpa, 0) * 100) < -10 THEN 'IMPROVING'
        WHEN ((weekly_cpa - prev_week_cpa) / NULLIF(prev_week_cpa, 0) * 100) > 10 THEN 'DEGRADING'
        ELSE 'STABLE'
    END as trend
FROM weekly_trends
WHERE prev_week_cpa IS NOT NULL
ORDER BY platform, week_number DESC;


-- ============================================
-- 6. DATA EXPORT FOR VISUALIZATION
-- ============================================

-- Export aggregated data for dashboard
SELECT 
    date::date as date,
    platform,
    SUM(cost) as daily_spend,
    SUM(conversions) as daily_conversions,
    SUM(clicks) as daily_clicks,
    SUM(impressions) as daily_impressions,
    ROUND(AVG(cpa)::numeric, 2) as avg_cpa,
    ROUND(AVG(ctr)::numeric, 2) as avg_ctr
FROM unified_ads_core
GROUP BY date, platform
ORDER BY date::date DESC, platform;