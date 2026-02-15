-- ============================================
-- ADVANCED MARKETING ANALYTICS SQL QUERIES
-- Demonstrating senior-level analytical thinking
-- ============================================

-- ============================================
-- 2. DATA QUALITY CHECKS
-- ============================================

-- Check for NULL values across all critical fields
SELECT 
    'facebook_ads' as source_table,
    COUNT(*) as total_rows,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) as null_dates,
    SUM(CASE WHEN cost IS NULL THEN 1 ELSE 0 END) as null_cost,
    SUM(CASE WHEN conversions IS NULL THEN 1 ELSE 0 END) as null_conversions,
    SUM(CASE WHEN cost < 0 THEN 1 ELSE 0 END) as negative_cost,
    SUM(CASE WHEN conversions < 0 THEN 1 ELSE 0 END) as negative_conversions
FROM facebook_ads

UNION ALL

SELECT 
    'google_ads',
    COUNT(*),
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN cost IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN conversions IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN cost < 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN conversions < 0 THEN 1 ELSE 0 END)
FROM google_ads

UNION ALL

SELECT 
    'tiktok_ads',
    COUNT(*),
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN cost IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN conversions IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN cost < 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN conversions < 0 THEN 1 ELSE 0 END)
FROM tiktok_ads;

-- Date range validation
SELECT 
    platform,
    MIN(date) as earliest_date,
    MAX(date) as latest_date,
    COUNT(DISTINCT date) as unique_days,
    MAX(date)::date - MIN(date)::date + 1 as expected_days,
    COUNT(DISTINCT date) - (MAX(date)::date - MIN(date)::date + 1) as missing_days
FROM unified_ads_core
GROUP BY platform;

-- ============================================
-- 3. PLATFORM PERFORMANCE ANALYSIS
-- ============================================

-- Platform efficiency metrics with statistical measures
WITH platform_daily_metrics AS (
    SELECT 
        platform,
        date,
        SUM(cost) as daily_cost,
        SUM(conversions) as daily_conversions,
        SUM(clicks) as daily_clicks,
        SUM(impressions) as daily_impressions,
        CASE 
            WHEN SUM(conversions) > 0 
            THEN SUM(cost) / SUM(conversions) 
            ELSE NULL 
        END as daily_cpa
    FROM unified_ads_core
    GROUP BY platform, date
),
platform_stats AS (
    SELECT 
        platform,
        -- Aggregated metrics
        SUM(daily_cost) as total_cost,
        SUM(daily_conversions) as total_conversions,
        SUM(daily_clicks) as total_clicks,
        SUM(daily_impressions) as total_impressions,
        
        -- Performance metrics
        AVG(daily_cpa) as avg_cpa,
        STDDEV(daily_cpa) as stddev_cpa,
        MIN(daily_cpa) as best_cpa,
        MAX(daily_cpa) as worst_cpa,
        
        -- Consistency score (Coefficient of Variation)
        CASE 
            WHEN AVG(daily_cpa) > 0 
            THEN (STDDEV(daily_cpa) / AVG(daily_cpa)) * 100 
            ELSE NULL 
        END as cpa_volatility_pct,
        
        -- Conversion rate
        (SUM(daily_conversions)::float / NULLIF(SUM(daily_clicks), 0)) * 100 as conversion_rate,
        
        -- Click-through rate
        (SUM(daily_clicks)::float / NULLIF(SUM(daily_impressions), 0)) * 100 as ctr
        
    FROM platform_daily_metrics
    GROUP BY platform
)
SELECT 
    platform,
    total_cost,
    total_conversions,
    avg_cpa,
    stddev_cpa,
    cpa_volatility_pct,
    conversion_rate,
    ctr,
    -- Efficiency score (lower is better)
    RANK() OVER (ORDER BY avg_cpa) as cpa_rank,
    -- Consistency score (lower volatility is better)
    RANK() OVER (ORDER BY cpa_volatility_pct) as consistency_rank,
    -- Overall performance score
    (RANK() OVER (ORDER BY avg_cpa) + RANK() OVER (ORDER BY cpa_volatility_pct)) / 2.0 as overall_score
FROM platform_stats
ORDER BY overall_score;

-- ============================================
-- 4. CAMPAIGN PERFORMANCE ANALYSIS
-- ============================================

-- Top and bottom performing campaigns with context
WITH campaign_metrics AS (
    SELECT 
        campaign_name,
        platform,
        SUM(cost) as total_cost,
        SUM(conversions) as total_conversions,
        SUM(clicks) as total_clicks,
        SUM(impressions) as total_impressions,
        
        -- Derived metrics
        SUM(cost) / NULLIF(SUM(conversions), 0) as cpa,
        (SUM(conversions)::float / NULLIF(SUM(clicks), 0)) * 100 as conversion_rate,
        (SUM(clicks)::float / NULLIF(SUM(impressions), 0)) * 100 as ctr,
        SUM(cost) / NULLIF(SUM(clicks), 0) as cpc,
        
        -- Activity metrics
        COUNT(DISTINCT date) as days_active,
        MIN(date) as first_active,
        MAX(date) as last_active
        
    FROM unified_ads_core
    GROUP BY campaign_name, platform
    HAVING SUM(conversions) > 0  -- Only campaigns with conversions
),
campaign_benchmarks AS (
    SELECT 
        platform,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cpa) as median_cpa,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cpa) as p75_cpa,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cpa) as p25_cpa
    FROM campaign_metrics
    GROUP BY platform
)
SELECT 
    cm.campaign_name,
    cm.platform,
    cm.total_cost,
    cm.total_conversions,
    cm.cpa,
    cm.conversion_rate,
    cm.ctr,
    cm.days_active,
    
    -- Benchmark comparison
    cb.median_cpa as platform_median_cpa,
    ((cm.cpa - cb.median_cpa) / NULLIF(cb.median_cpa, 0)) * 100 as cpa_vs_median_pct,
    
    -- Performance category
    CASE 
        WHEN cm.cpa <= cb.p25_cpa THEN 'Top 25%'
        WHEN cm.cpa <= cb.median_cpa THEN 'Above Average'
        WHEN cm.cpa <= cb.p75_cpa THEN 'Below Average'
        ELSE 'Bottom 25%'
    END as performance_tier
    
FROM campaign_metrics cm
JOIN campaign_benchmarks cb ON cm.platform = cb.platform
ORDER BY cm.total_conversions DESC
LIMIT 20;

-- ============================================
-- 5. TIME-BASED PATTERNS ANALYSIS
-- ============================================

-- Day of week performance analysis
WITH daily_performance AS (
    SELECT 
        EXTRACT(DOW FROM date) as day_of_week,
        CASE EXTRACT(DOW FROM date)
            WHEN 0 THEN 'Sunday'
            WHEN 1 THEN 'Monday'
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
        END as day_name,
        platform,
        SUM(cost) as cost,
        SUM(conversions) as conversions,
        SUM(cost) / NULLIF(SUM(conversions), 0) as cpa
    FROM unified_ads_core
    GROUP BY 1, 2, 3
)
SELECT 
    day_of_week,
    day_name,
    platform,
    cost,
    conversions,
    cpa,
    RANK() OVER (PARTITION BY platform ORDER BY cpa) as cpa_rank
FROM daily_performance
ORDER BY day_of_week, platform;

-- Week-over-week trend analysis
WITH weekly_metrics AS (
    SELECT 
        DATE_TRUNC('week', date) as week_start,
        platform,
        SUM(cost) as weekly_cost,
        SUM(conversions) as weekly_conversions,
        SUM(cost) / NULLIF(SUM(conversions), 0) as weekly_cpa
    FROM unified_ads_core
    GROUP BY 1, 2
),
weekly_trends AS (
    SELECT 
        week_start,
        platform,
        weekly_cost,
        weekly_conversions,
        weekly_cpa,
        LAG(weekly_cpa) OVER (PARTITION BY platform ORDER BY week_start) as prev_week_cpa,
        LAG(weekly_conversions) OVER (PARTITION BY platform ORDER BY week_start) as prev_week_conversions
    FROM weekly_metrics
)
SELECT 
    week_start,
    platform,
    weekly_cost,
    weekly_conversions,
    weekly_cpa,
    prev_week_cpa,
    
    -- Week-over-week changes
    CASE 
        WHEN prev_week_cpa IS NOT NULL 
        THEN ((weekly_cpa - prev_week_cpa) / NULLIF(prev_week_cpa, 0)) * 100 
    END as cpa_change_pct,
    
    CASE 
        WHEN prev_week_conversions IS NOT NULL 
        THEN ((weekly_conversions - prev_week_conversions) / NULLIF(prev_week_conversions, 0)) * 100 
    END as conversion_change_pct,
    
    -- Trend indicator
    CASE 
        WHEN weekly_cpa < prev_week_cpa THEN 'Improving'
        WHEN weekly_cpa > prev_week_cpa THEN 'Worsening'
        ELSE 'Stable'
    END as trend
    
FROM weekly_trends
WHERE prev_week_cpa IS NOT NULL
ORDER BY week_start DESC, platform;

-- ============================================
-- 6. BUDGET ALLOCATION OPTIMIZATION
-- ============================================

-- Calculate optimal budget allocation based on efficiency
WITH platform_efficiency AS (
    SELECT 
        platform,
        SUM(cost) as current_spend,
        SUM(conversions) as current_conversions,
        SUM(cost) / NULLIF(SUM(conversions), 0) as cpa,
        
        -- Calculate efficiency score (inverse of CPA, normalized)
        1.0 / NULLIF(SUM(cost) / NULLIF(SUM(conversions), 0), 0) as efficiency_score
        
    FROM unified_ads_core
    GROUP BY platform
),
total_metrics AS (
    SELECT 
        SUM(current_spend) as total_budget,
        SUM(efficiency_score) as total_efficiency
    FROM platform_efficiency
)
SELECT 
    pe.platform,
    pe.current_spend,
    pe.current_conversions,
    pe.cpa,
    
    -- Current allocation
    (pe.current_spend / tm.total_budget * 100)::numeric(10,2) as current_allocation_pct,
    
    -- Optimal allocation based on efficiency
    (pe.efficiency_score / tm.total_efficiency * 100)::numeric(10,2) as optimal_allocation_pct,
    
    -- Recommended budget change
    ((pe.efficiency_score / tm.total_efficiency * tm.total_budget) - pe.current_spend)::numeric(10,2) as recommended_budget_change,
    
    -- Projected impact
    (((pe.efficiency_score / tm.total_efficiency * tm.total_budget) / NULLIF(pe.cpa, 0)) - pe.current_conversions)::numeric(10,2) as projected_conversion_increase
    
FROM platform_efficiency pe
CROSS JOIN total_metrics tm
ORDER BY optimal_allocation_pct DESC;

-- ============================================
-- 7. PERFORMANCE INDEXES
-- ============================================

-- Create indexes for dashboard performance
CREATE INDEX idx_unified_platform ON unified_ads_core(platform);
CREATE INDEX idx_unified_date ON unified_ads_core(date);
CREATE INDEX idx_unified_campaign ON unified_ads_core(campaign_name);
CREATE INDEX idx_unified_platform_date ON unified_ads_core(platform, date);

-- ============================================
-- 8. VERIFICATION QUERIES
-- ============================================

-- Final data verification
SELECT 
    'Unified Table Stats' as check_type,
    COUNT(*) as total_rows,
    COUNT(DISTINCT platform) as platforms,
    COUNT(DISTINCT campaign_name) as campaigns,
    COUNT(DISTINCT date) as unique_dates,
    SUM(cost) as total_spend,
    SUM(conversions) as total_conversions,
    MIN(date) as data_start,
    MAX(date) as data_end
FROM unified_ads_core;

-- Platform distribution check
SELECT 
    platform,
    COUNT(*) as row_count,
    COUNT(DISTINCT campaign_name) as campaign_count,
    SUM(cost) as total_spend,
    SUM(conversions) as total_conversions,
    AVG(cpa) as avg_cpa
FROM unified_ads_core
GROUP BY platform
ORDER BY platform;
