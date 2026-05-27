with days as (
    -- Génère automatiquement une ligne par jour de 2020 à 2030
    select 
        cast(range as date) as date_day
    from range(date '2020-01-01', date '2030-01-01', interval 1 day)
)

select
    date_day,
    -- dbt demande parfois de définir explicitement la granularité
    date_trunc('day', date_day) as date_day_truncated
from days