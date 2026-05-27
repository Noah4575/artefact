-- Matrice de décision finale agrégée par route
-- Combine profitabilité, opérations et sentiment client
-- Chaque ligne = 1 route, avec tous les signaux pour décider où investir

WITH route_financials AS (
    SELECT
        f.route_key,
        COUNT(DISTINCT f.flight_id)                                          AS total_flights,
        SUM(f.seat_capacity)                                                 AS total_seats,
        SUM(f.passenger_count)                                               AS total_passengers,
        SUM(f.total_operating_cost_usd)                                      AS total_operating_cost_usd,
        SUM(f.exact_fuel_cost_usd)                                           AS total_fuel_cost_usd,
        AVG(f.delay_min)                                                     AS avg_delay_min,
        SUM(CASE WHEN f.flight_status = 'Delayed' THEN 1 ELSE 0 END)        AS delayed_flights,
        SUM(CASE WHEN f.flight_status = 'Cancelled' THEN 1 ELSE 0 END)      AS cancelled_flights
    FROM {{ ref('fact_flight_performance') }} f
    GROUP BY f.route_key
),

route_revenue AS (
    SELECT
        f.route_key,
        SUM(b.ticket_price_usd)                                              AS total_ticket_revenue_usd,
        SUM(b.ancillary_revenue_usd)                                         AS total_ancillary_revenue_usd,
        COUNT(b.booking_id)                                                  AS total_bookings,
        SUM(CASE WHEN b.booking_channel IN ('Mobile App', 'Web') THEN 1 ELSE 0 END)
                                                                             AS digital_bookings,
        AVG(b.ticket_price_usd)                                              AS avg_ticket_price_usd
    FROM {{ ref('fact_bookings') }} b
    LEFT JOIN {{ ref('fact_flight_performance') }} f
        ON b.flight_key = f.flight_key
    GROUP BY f.route_key
),

route_sentiment AS (
    SELECT
        fp.route_key,
        AVG(c.sentiment_score)                                               AS avg_sentiment_score,
        SUM(CASE WHEN c.sentiment_category = 'At-Risk' THEN 1 ELSE 0 END)   AS at_risk_customers,
        SUM(CASE WHEN c.loyalty_tier IN ('Gold', 'Platinum') THEN 1 ELSE 0 END)
                                                                             AS premium_customers
    FROM {{ ref('fact_bookings') }} b
    LEFT JOIN {{ ref('dim_customers') }} c
        ON b.customer_key = c.customer_key
    LEFT JOIN {{ ref('fact_flight_performance') }} fp
        ON b.flight_key = fp.flight_key
    GROUP BY fp.route_key
)

SELECT
    r.route_id,
    r.origin_airport_code || ' → ' || r.destination_airport_code            AS route_label,
    r.route_type,

    -- Volume & capacité
    rf.total_flights,
    rf.total_seats,
    rf.total_passengers,
    ROUND(rf.total_passengers * 100.0 / NULLIF(rf.total_seats, 0), 1)       AS avg_load_factor_pct,

    -- Revenus
    COALESCE(rv.total_ticket_revenue_usd, 0)                                AS total_ticket_revenue_usd,
    COALESCE(rv.total_ancillary_revenue_usd, 0)                             AS total_ancillary_revenue_usd,
    COALESCE(rv.total_ticket_revenue_usd, 0)
        + COALESCE(rv.total_ancillary_revenue_usd, 0)                       AS total_gross_revenue_usd,

    -- Coûts & marge
    rf.total_operating_cost_usd,
    ROUND(
        (COALESCE(rv.total_ticket_revenue_usd, 0) + COALESCE(rv.total_ancillary_revenue_usd, 0))
        - rf.total_operating_cost_usd, 2
    )                                                                        AS total_margin_usd,

    -- Yield
    ROUND(rv.avg_ticket_price_usd, 2)                                       AS avg_ticket_price_usd,

    -- Opérations
    ROUND(rf.avg_delay_min, 1)                                              AS avg_delay_min,
    rf.delayed_flights,
    rf.cancelled_flights,
    ROUND(rf.delayed_flights * 100.0 / NULLIF(rf.total_flights, 0), 1)      AS delay_rate_pct,
    ROUND(rf.cancelled_flights * 100.0 / NULLIF(rf.total_flights, 0), 1)    AS cancellation_rate_pct,

    -- Canal
    rv.total_bookings,
    rv.digital_bookings,
    ROUND(rv.digital_bookings * 100.0 / NULLIF(rv.total_bookings, 0), 1)    AS digital_adoption_rate_pct,

    -- Sentiment & rétention
    ROUND(rs.avg_sentiment_score, 2)                                        AS avg_sentiment_score,
    rs.at_risk_customers,
    rs.premium_customers,

    -- Décision stratégique automatique
    CASE
        WHEN ROUND(rf.total_passengers * 100.0 / NULLIF(rf.total_seats, 0), 1) >= 80
             AND (COALESCE(rv.total_ticket_revenue_usd, 0) + COALESCE(rv.total_ancillary_revenue_usd, 0)
                  - rf.total_operating_cost_usd) > 0
             AND ROUND(rf.delayed_flights * 100.0 / NULLIF(rf.total_flights, 0), 1) < 25
        THEN 'GROW — High demand, profitable, reliable'

        WHEN (COALESCE(rv.total_ticket_revenue_usd, 0) + COALESCE(rv.total_ancillary_revenue_usd, 0)
              - rf.total_operating_cost_usd) > 0
             AND rs.premium_customers > 0
             AND ROUND(rf.delayed_flights * 100.0 / NULLIF(rf.total_flights, 0), 1) >= 25
        THEN 'DEFEND — Profitable but operationally at risk'

        WHEN (COALESCE(rv.total_ticket_revenue_usd, 0) + COALESCE(rv.total_ancillary_revenue_usd, 0)
              - rf.total_operating_cost_usd) <= 0
        THEN 'REVIEW — Unprofitable route'

        ELSE 'MONITOR — Watch and optimize'
    END                                                                      AS strategic_decision

FROM {{ ref('dim_routes') }} r
LEFT JOIN route_financials rf ON r.route_key = rf.route_key
LEFT JOIN route_revenue rv    ON r.route_key = rv.route_key
LEFT JOIN route_sentiment rs  ON r.route_key = rs.route_key
