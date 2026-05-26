WITH base_flights AS (
    SELECT DISTINCT route_id, origin, destination 
    FROM read_csv_auto('air_cote_divoire_starter_dataset.xlsx - Flights.csv')
)

SELECT 
    md5(route_id) as route_key,
    route_id,
    origin as origin_airport_code,
    destination as destination_airport_code,
    'Regional' as route_type -- Placeholder logic for your challenge
FROM base_flights