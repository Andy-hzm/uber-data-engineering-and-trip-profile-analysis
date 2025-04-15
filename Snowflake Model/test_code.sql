-- Create date_dimension
USE uber_snowflake;
CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    date DATE NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

-- Create time_dimension
CREATE TABLE dim_time (
    time_id INT PRIMARY KEY,
    hour INT NOT NULL,
    minute INT NOT NULL
);

-- Create dim_borough
CREATE TABLE dim_borough (
    borough_id INT PRIMARY KEY,      -- Unique ID for each borough
    borough_name TEXT NOT NULL       -- Name of the borough
);

-- Create zones_dimension
CREATE TABLE dim_zones (
    location_id INT PRIMARY KEY,   -- Unique identifier for each location/zone
    zone TEXT NOT NULL,            -- Name of the zone
    borough TEXT NOT NULL,         -- Borough name (e.g., "Manhattan", "Brooklyn")
    borough_id INT,             
    lat_min DOUBLE,                -- Minimum latitude of the zone
    lat_max DOUBLE,                -- Maximum latitude of the zone
    lon_min DOUBLE,                -- Minimum longitude of the zone
    lon_max DOUBLE              -- Maximum longitude of the zone
);


CREATE TABLE dim_events (
    event_id INT PRIMARY KEY,                -- Unique identifier for each event
    event_name TEXT,                         -- Name of the event
    event_type TEXT,                         -- Type of the event
    event_agency TEXT,                       -- Agency responsible for the event
    borough_id INT,                          -- FK to zones_borough
    start_date_id INT,                       -- FK to dim_date
    start_time_id INT,                       -- FK to dim_time
    end_date_id INT,                         -- FK to dim_date
    end_time_id INT,                         -- FK to dim_time,
    event_street_side TEXT,                  -- Street or side where the event occurred
    full_street_closure TEXT,                -- Whether it was a full street closure (e.g., 'Yes', 'No')
    FOREIGN KEY (borough_id) REFERENCES dim_borough(borough_id),
    FOREIGN KEY (start_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (start_time_id) REFERENCES dim_time(time_id),
    FOREIGN KEY (end_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (end_time_id) REFERENCES dim_time(time_id)
);

CREATE TABLE dim_weather (
    weather_daily_id INT PRIMARY KEY AUTO_INCREMENT,
    date_id INT,                            -- FK to dim_date
    sunrise_time_id INT,                    -- FK to dim_time
    sunset_time_id INT,                     -- FK to dim_time
    daylight_duration DOUBLE,               -- Daylight duration in seconds
    temperature_2m DOUBLE,                  -- Temperature in Celsius
    precipitation DOUBLE,                   -- Precipitation in mm
    rain DOUBLE,                            -- Rainfall in mm
    snowfall DOUBLE,                        -- Snowfall in mm
    snow_depth DOUBLE,                      -- Snow depth in mm
    surface_pressure DOUBLE,                -- Surface pressure in hPa
    wind_speed DOUBLE,                      -- Wind speed in m/s
    weather_code INT,                       -- Weather condition code
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (sunrise_time_id) REFERENCES dim_time(time_id),
    FOREIGN KEY (sunset_time_id) REFERENCES dim_time(time_id)
);

CREATE TABLE fact_trips (
    trip_id INT PRIMARY KEY,                -- Unique ID for each trip
    pickup_date_id INT,                     -- FK to dim_date
    pickup_time_id INT,                     -- FK to dim_time
    dropoff_date_id INT,                    -- FK to dim_date
    dropoff_time_id INT,                    -- FK to dim_time
    PUlocationID INT,                       -- FK to dim_zones
    DOlocationID INT,                       -- FK to dim_zones
    trip_miles DOUBLE,                      -- Distance of the trip
    trip_time INT,                          -- Duration of the trip
    base_passenger_fare DOUBLE,             -- Base fare
    tips DOUBLE,                            -- Tips
    congestion_surcharge DOUBLE,            -- Congestion surcharge
    weather_daily_id INT,                   -- FK to dim_weather
    event_id INT,                           -- FK to dim_event
    pickup_datetime DATETIME,               -- Exact pickup time
    dropoff_datetime DATETIME,              -- Exact dropoff time
    FOREIGN KEY (pickup_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (pickup_time_id) REFERENCES dim_time(time_id),
    FOREIGN KEY (dropoff_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (dropoff_time_id) REFERENCES dim_time(time_id),
    FOREIGN KEY (PUlocationID) REFERENCES dim_zones(location_id),
    FOREIGN KEY (DOlocationID) REFERENCES dim_zones(location_id),
    FOREIGN KEY (weather_daily_id) REFERENCES dim_weather(weather_daily_id),
    FOREIGN KEY (event_id) REFERENCES dim_events(event_id)
);

UPDATE fact_trips ft
JOIN dim_events de ON ft.PUlocationID = de.borough_id
SET ft.event_id = de.event_id
WHERE ft.pickup_date_id = de.start_date_id;

UPDATE fact_trips ft
JOIN dim_weather dw
  ON ft.pickup_date_id = dw.date_id
SET ft.weather_daily_id = dw.weather_daily_id;