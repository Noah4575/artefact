WITH base_flights AS (
    SELECT * FROM {{ ref('Flights') }}
),

flight_passengers AS (
    SELECT 
        flight_id,
        COUNT(booking_id) AS passenger_count
    FROM {{ ref('Bookings') }}
    GROUP BY 1
)

SELECT 
    md5(f.flight_id) as flight_key,
    md5(f.route_id) as route_key,
    f.flight_id,
    f.flight_date::DATE as flight_date,
    f.aircraft_type,
    f.flight_status,
    f.seat_capacity,
    COALESCE(p.passenger_count, 0) as passenger_count,
    f.delay_min,
    
    -- On garde les heures telles quelles si besoin de précision (ex: 2.5 heures)
    f.actual_block_hours,
    
    -- On calcule les minutes et on les transforme en ENTIER (INT) pour enlever les décimales
    CAST(f.actual_block_hours * 60 AS INT) as actual_block_minutes,
    
    -- Calculs des coûts (DuckDB gérera les arrondis financiers automatiquement si besoin)
    (f.actual_block_hours * 60 * 85) as exact_fuel_cost_usd, 
    (f.actual_block_hours * 60 * 120) as total_operating_cost_usd 

FROM base_flights f
LEFT JOIN flight_passengers p 
    ON f.flight_id = p.flight_id