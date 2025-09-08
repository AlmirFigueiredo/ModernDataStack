
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

CREATE SCHEMA IF NOT EXISTS _airbyte_raw;


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'airbyte_ingest') THEN
    CREATE ROLE airbyte_ingest LOGIN PASSWORD 'airbyte_ingest_pass';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dbt_transform') THEN
    CREATE ROLE dbt_transform LOGIN PASSWORD 'dbt_transform_pass';
  END IF;
END $$;


GRANT USAGE ON SCHEMA _airbyte_raw, bronze TO airbyte_ingest;
GRANT CREATE ON SCHEMA _airbyte_raw, bronze TO airbyte_ingest;

GRANT USAGE ON SCHEMA bronze, _airbyte_raw, silver, gold TO dbt_transform;
GRANT CREATE ON SCHEMA silver, gold TO dbt_transform;

GRANT SELECT ON ALL TABLES IN SCHEMA bronze, _airbyte_raw TO dbt_transform;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA bronze, _airbyte_raw TO dbt_transform;


ALTER DATABASE dw SET search_path = public, bronze, silver, gold, _airbyte_raw;
