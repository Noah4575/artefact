WITH base_flights AS (
    SELECT * FROM read_csv_auto('air_cote_divoire_starter_dataset.xlsx - Flights.csv')
)

SELECT 
    md5(flight_id) as flight_key,
    md5(route_id) as route_key,
    flight_id,
    flight_date::DATE as flight_date,
    aircraft_type,
    flight_status,
    seat_capacity,
    passenger_count,
    delay_min,
    -- Placeholder for your Fleet Cost Ledger logic
    (actual_block_minutes / 60.0) as actual_block_hours,
    (actual_block_minutes * 85) as exact_fuel_cost_usd, 
    (actual_block_minutes * 120) as total_operating_cost_usd 
FROM base_flights