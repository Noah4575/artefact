-- Read directly from your synthetic output and starter dataset
WITH base_customers AS (
    SELECT * FROM read_csv_auto('final_synthetic_reviews.csv')
)

SELECT 
    -- Create a surrogate key
    md5(customer_id) as customer_key,
    customer_id,
    customer_segment,
    loyalty_tier,
    preferred_channel,
    sentiment_score,
    CASE 
        WHEN sentiment_score >= 0.5 THEN 'Delighted'
        WHEN sentiment_score <= -0.2 THEN 'At-Risk'
        ELSE 'Neutral' 
    END as sentiment_category
FROM base_customers