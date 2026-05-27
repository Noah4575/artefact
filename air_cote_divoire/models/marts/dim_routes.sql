WITH base_flights AS (
    SELECT DISTINCT route_id, origin_airport_code, destination_airport_code 
    FROM {{ ref('Routes') }}
)

SELECT 
    md5(route_id) as route_key,
    route_id,
    origin_airport_code,
    destination_airport_code,
    'Regional' as route_type -- Placeholder logic for your challenge
FROM base_flights