-- creating a database
-- Overall summary
SELECT 
    COUNT(*) as total_reports,
    ROUND(AVG(number_health_problems), 2) as avg_health_problems,
    ROUND(AVG(number_product_problems), 2) as avg_product_problems,
    SUM(CASE WHEN nonuser_affected = 'Yes' THEN 1 ELSE 0 END) as nonuser_incidents,
    ROUND(SUM(CASE WHEN nonuser_affected = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as nonuser_percentage
FROM reports;

-- Product category breakdown
SELECT 
    CASE 
        WHEN tobacco_products LIKE '%Electronic cigarette%' THEN 'Vaping'
        WHEN tobacco_products LIKE '%Oral nicotine%' THEN 'Oral Nicotine'
        WHEN tobacco_products LIKE '%Cigarette%' THEN 'Cigarette'
        WHEN tobacco_products LIKE '%Cigar%' THEN 'Cigar'
        ELSE 'Other'
    END as product_category,
    COUNT(*) as report_count,
    ROUND(AVG(number_health_problems), 2) as avg_health_issues,
    ROUND(AVG(number_product_problems), 2) as avg_product_issues,
    SUM(CASE WHEN number_health_problems >= 5 THEN 1 ELSE 0 END) as severe_cases
FROM reports
GROUP BY product_category
ORDER BY report_count DESC;

-- Monthly reporting trends
SELECT 
    DATE_FORMAT(date_submitted, '%Y-%m') as report_month,
    COUNT(*) as monthly_reports,
    ROUND(AVG(number_health_problems), 2) as avg_health_issues,
    ROUND(AVG(number_product_problems), 2) as avg_product_issues
FROM reports
GROUP BY DATE_FORMAT(date_submitted, '%Y-%m')
ORDER BY report_month;


select * from reports;

-- Extract and count individual symptoms
WITH symptom_split AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(reported_health_problems, '/', n), '/', -1)) as symptom
    FROM reports
    CROSS JOIN (
        SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
        UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8
        UNION SELECT 9 UNION SELECT 10
    ) numbers
    WHERE reported_health_problems != 'No information provided'
    AND CHAR_LENGTH(reported_health_problems) - CHAR_LENGTH(REPLACE(reported_health_problems, '/', '')) >= n - 1
)
SELECT 
    symptom,
    COUNT(*) as frequency
FROM symptom_split
WHERE symptom != '' AND symptom IS NOT NULL
GROUP BY symptom
ORDER BY frequency DESC
LIMIT 15;

-- Similar extraction for product problems
WITH problem_split AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(reported_product_problems, '/', n), '/', -1)) as problem
    FROM reports
    CROSS JOIN (
        SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    ) numbers
    WHERE reported_product_problems != 'No information provided'
    AND CHAR_LENGTH(reported_product_problems) - CHAR_LENGTH(REPLACE(reported_product_problems, '/', '')) >= n - 1
)
SELECT 
    problem,
    COUNT(*) as frequency
FROM problem_split
WHERE problem != '' AND problem IS NOT NULL
GROUP BY problem
ORDER BY frequency DESC;


-- Health vs Product problems correlation
SELECT 
    number_health_problems,
    number_product_problems,
    COUNT(*) as case_count,
     CASE 
        WHEN tobacco_products LIKE '%Electronic cigarette%' THEN 'Vaping Products'
        WHEN tobacco_products LIKE '%Oral nicotine%' THEN 'Oral Nicotine'
        WHEN tobacco_products LIKE '%Cigarette%' AND tobacco_products NOT LIKE '%Roll-your-own%' THEN 'Cigarettes'
        WHEN tobacco_products LIKE '%Cigar%' OR tobacco_products LIKE '%Roll-your-own%' THEN 'Cigars & Roll-Your-Own'
        ELSE 'Other'
    END as product_category
FROM reports
WHERE number_health_problems > 0 AND number_product_problems > 0
GROUP BY product_category, number_health_problems, number_product_problems
ORDER BY case_count DESC;

select * from reports;

-- Health vs Product problems correlation
SELECT 
    number_health_problems,
    number_product_problems,
    COUNT(*) as case_count
FROM reports
WHERE number_health_problems > 0 AND number_product_problems > 0
GROUP BY number_health_problems, number_product_problems
ORDER BY case_count DESC;


-- Classify reports by severity
SELECT 
    CASE 
        WHEN number_health_problems = 0 THEN 'No Health Issues'
        WHEN number_health_problems BETWEEN 1 AND 2 THEN 'Minor'
        WHEN number_health_problems BETWEEN 3 AND 5 THEN 'Moderate'
        WHEN number_health_problems > 5 THEN 'Severe'
    END as severity_level,
    COUNT(*) as report_count,
    GROUP_CONCAT(DISTINCT 
        CASE 
            WHEN tobacco_products LIKE '%Electronic cigarette%' THEN 'Vaping'
            WHEN tobacco_products LIKE '%Oral nicotine%' THEN 'Oral'
            ELSE 'Traditional'
        END
    ) as product_types
FROM reports
GROUP BY severity_level
ORDER BY FIELD(severity_level, 'Severe', 'Moderate', 'Minor', 'No Health Issues');

-- Product type vs symptom category
SELECT 
    CASE 
        WHEN tobacco_products LIKE '%Electronic cigarette%' THEN 'Vaping'
        WHEN tobacco_products LIKE '%Oral nicotine%' THEN 'Oral Nicotine'
        ELSE 'Traditional'
    END as product_type,
    COUNT(*) as total_reports,
    SUM(CASE WHEN reported_health_problems LIKE '%cardiac%' OR reported_health_problems LIKE '%heart%' THEN 1 ELSE 0 END) as cardiovascular,
    SUM(CASE WHEN reported_health_problems LIKE '%lung%' OR reported_health_problems LIKE '%chest%' THEN 1 ELSE 0 END) as respiratory,
    SUM(CASE WHEN reported_health_problems LIKE '%depression%' OR reported_health_problems LIKE '%anxiety%' OR reported_health_problems LIKE '%suicid%' THEN 1 ELSE 0 END) as mental_health
FROM reports
GROUP BY product_type;