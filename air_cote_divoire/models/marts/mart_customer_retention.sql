WITH booking_counts AS (
    -- Nombre de bookings par client pour calculer le repeat behavior
    SELECT
        customer_key,
        COUNT(booking_id)                          AS total_bookings_lifetime,
        MIN(booking_date)                          AS first_booking_date,
        MAX(booking_date)                          AS last_booking_date,
        SUM(ticket_price_usd)                      AS lifetime_ticket_revenue_usd,
        SUM(ancillary_revenue_usd)                 AS lifetime_ancillary_revenue_usd,
        SUM(ticket_price_usd + ancillary_revenue_usd) AS lifetime_revenue_usd
    FROM {{ ref('fact_bookings') }}
    GROUP BY customer_key
),

flight_delays AS (
    -- Nombre de vols delayed expérimentés par client
    SELECT
        b.customer_key,
        COUNT(CASE WHEN f.flight_status = 'Delayed' THEN 1 END) AS delayed_flights_experienced,
        COUNT(f.flight_id)                                        AS total_flights_taken,
        AVG(f.delay_min)                                          AS avg_delay_min_experienced
    FROM {{ ref('fact_bookings') }} b
    LEFT JOIN {{ ref('fact_flight_performance') }} f
        ON b.flight_key = f.flight_key
    GROUP BY b.customer_key
)

SELECT
    -- Dimension client
    c.customer_id,
    c.customer_segment,
    c.loyalty_tier,
    c.preferred_channel,
    c.sentiment_score,
    c.sentiment_category,

    -- Comportement booking
    bc.total_bookings_lifetime,
    bc.first_booking_date,
    bc.last_booking_date,
    bc.lifetime_revenue_usd,
    bc.lifetime_ticket_revenue_usd,
    bc.lifetime_ancillary_revenue_usd,

    -- Repeat behavior
    CASE
        WHEN bc.total_bookings_lifetime > 1 THEN 1 ELSE 0
    END                                                         AS is_repeat_customer,

    -- Revenu moyen par booking
    ROUND(bc.lifetime_revenue_usd / NULLIF(bc.total_bookings_lifetime, 0), 2)
                                                                AS avg_revenue_per_booking_usd,

    -- Expérience opérationnelle
    fd.total_flights_taken,
    fd.delayed_flights_experienced,
    ROUND(fd.avg_delay_min_experienced, 1)                      AS avg_delay_min_experienced,
    CASE
        WHEN fd.total_flights_taken > 0
        THEN ROUND(fd.delayed_flights_experienced * 100.0 / fd.total_flights_taken, 1)
        ELSE NULL
    END                                                         AS personal_delay_rate_pct,

    -- Scoring risque de churn
    -- Logique : sentiment négatif + delays élevés + client premium = priorité haute
    CASE
        WHEN c.sentiment_score <= -0.2
             AND fd.delayed_flights_experienced >= 2
             AND c.loyalty_tier IN ('Gold', 'Platinum')         THEN 'Critical'
        WHEN c.sentiment_score <= -0.2
             AND c.loyalty_tier IN ('Gold', 'Platinum')         THEN 'High'
        WHEN c.sentiment_score <= -0.2                          THEN 'Medium'
        WHEN c.sentiment_score BETWEEN -0.2 AND 0.1            THEN 'Low'
        ELSE 'Safe'
    END                                                         AS churn_risk_level

FROM {{ ref('dim_customers') }} c
LEFT JOIN booking_counts bc
    ON c.customer_key = bc.customer_key
LEFT JOIN flight_delays fd
    ON c.customer_key = fd.customer_key
