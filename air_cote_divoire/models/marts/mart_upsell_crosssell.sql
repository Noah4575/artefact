SELECT
    -- Dimensions de segmentation
    c.customer_segment,
    c.loyalty_tier,
    c.sentiment_category,
    b.fare_class,
    b.fare_family,
    b.booking_channel,

    -- Flags de canal
    CASE WHEN b.booking_channel IN ('Mobile App', 'Web') THEN 'Digital' ELSE 'Indirect' END
                                                                AS channel_type,

    -- Volume
    COUNT(b.booking_id)                                         AS total_bookings,
    COUNT(DISTINCT b.customer_key)                              AS unique_customers,

    -- Revenus
    SUM(b.ticket_price_usd)                                     AS total_ticket_revenue_usd,
    SUM(b.ancillary_revenue_usd)                                AS total_ancillary_revenue_usd,
    SUM(b.ticket_price_usd + b.ancillary_revenue_usd)           AS total_revenue_usd,
    SUM(b.bags_count)                                           AS total_bags_checked,

    -- KPIs upsell
    ROUND(
        SUM(b.ancillary_revenue_usd)
        / NULLIF(COUNT(b.booking_id), 0), 2
    )                                                           AS ancillary_yield_per_booking_usd,

    ROUND(
        SUM(b.ticket_price_usd + b.ancillary_revenue_usd)
        / NULLIF(COUNT(b.booking_id), 0), 2
    )                                                           AS total_revenue_per_booking_usd,

    -- Ancillary attach rate
    ROUND(
        SUM(CASE WHEN b.ancillary_revenue_usd > 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(b.booking_id), 0), 1
    )                                                           AS ancillary_attach_rate_pct,

    -- Bag attach rate
    ROUND(
        SUM(CASE WHEN b.bags_count > 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(b.booking_id), 0), 1
    )                                                           AS bag_attach_rate_pct,

    -- Digital adoption rate
    ROUND(
        SUM(CASE WHEN b.booking_channel IN ('Mobile App', 'Web') THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(b.booking_id), 0), 1
    )                                                           AS digital_adoption_rate_pct,

    -- Sentiment moyen du segment
    ROUND(AVG(c.sentiment_score), 2)                            AS avg_sentiment_score

FROM {{ ref('fact_bookings') }} b
LEFT JOIN {{ ref('dim_customers') }} c
    ON b.customer_key = c.customer_key
GROUP BY 1, 2, 3, 4, 5, 6, 7
