WITH flight_revenue AS (
    SELECT
        flight_key,
        SUM(ticket_price_usd)      AS ticket_revenue_usd,
        SUM(ancillary_revenue_usd) AS ancillary_revenue_usd
    FROM {{ ref('fact_bookings') }}
    GROUP BY flight_key
)

SELECT
    -- Identifiants
    f.flight_id,
    f.flight_date,
    f.aircraft_type,
    f.flight_status,
    r.route_id,
    r.origin_airport_code || ' → ' || r.destination_airport_code AS route_label,
    r.route_type,

    -- Capacité & trafic
    f.seat_capacity,
    f.passenger_count,
    f.delay_min,
    f.actual_block_hours,

    -- Coûts
    f.exact_fuel_cost_usd,
    f.total_operating_cost_usd,

    -- Revenus
    COALESCE(b.ticket_revenue_usd, 0)                                       AS ticket_revenue_usd,
    COALESCE(b.ancillary_revenue_usd, 0)                                    AS ancillary_revenue_usd,
    COALESCE(b.ticket_revenue_usd, 0) + COALESCE(b.ancillary_revenue_usd, 0) AS gross_revenue_usd,

    -- KPIs calculés
    ROUND(
        (COALESCE(b.ticket_revenue_usd, 0) + COALESCE(b.ancillary_revenue_usd, 0))
        - f.total_operating_cost_usd, 2
    )                                                                        AS contribution_margin_usd,

    CASE
        WHEN f.seat_capacity > 0
        THEN ROUND(f.passenger_count * 100.0 / f.seat_capacity, 1)
        ELSE NULL
    END                                                                      AS load_factor_pct,

    -- Yield = revenue / passager
    CASE
        WHEN f.passenger_count > 0
        THEN ROUND(
            (COALESCE(b.ticket_revenue_usd, 0) + COALESCE(b.ancillary_revenue_usd, 0))
            / f.passenger_count, 2)
        ELSE NULL
    END                                                                      AS yield_per_passenger_usd,

    -- Flags
    CASE WHEN f.flight_status = 'Delayed' THEN 1 ELSE 0 END                 AS is_delayed,
    CASE WHEN f.flight_status = 'Cancelled' THEN 1 ELSE 0 END               AS is_cancelled

FROM {{ ref('fact_flight_performance') }} f
LEFT JOIN {{ ref('dim_routes') }} r
    ON f.route_key = r.route_key
LEFT JOIN flight_revenue b
    ON f.flight_key = b.flight_key
