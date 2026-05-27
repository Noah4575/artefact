WITH base_bookings AS (
    SELECT * FROM {{ ref('Bookings') }}
)

SELECT 
    md5(booking_id) as booking_key,
    md5(customer_id) as customer_key,
    md5(flight_id) as flight_key,
    booking_id,
    booking_date::DATE as booking_date,
    booking_channel,
    fare_class,
    fare_family,
    booking_status,
    ticket_price_usd,
    ancillary_revenue_usd,
    bags_count
FROM base_bookings