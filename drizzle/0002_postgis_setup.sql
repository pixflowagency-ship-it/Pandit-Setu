-- Custom SQL migration file, put your code below! --
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE INDEX IF NOT EXISTS idx_pandits_location_gist ON pandits USING GIST (location);