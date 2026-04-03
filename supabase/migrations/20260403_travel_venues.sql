-- Migration: travel_destinations and venues tables
-- Matches the column schema expected by TravelService and VenueService.
-- Run: supabase db push

-- ---------------------------------------------------------------------------
-- Travel Destinations (matches TravelService._destinationColumns)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.travel_destinations (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code             TEXT NOT NULL UNIQUE,
  country_name             TEXT NOT NULL,
  region                   TEXT NOT NULL DEFAULT 'Middle East',
  flag_emoji               TEXT,
  pet_import_allowed       BOOLEAN NOT NULL DEFAULT true,
  quarantine_required      BOOLEAN NOT NULL DEFAULT false,
  quarantine_days          INT  NOT NULL DEFAULT 0,
  required_documents       JSONB NOT NULL DEFAULT '[]'::jsonb,
  banned_breeds            JSONB NOT NULL DEFAULT '[]'::jsonb,
  vaccination_requirements JSONB NOT NULL DEFAULT '[]'::jsonb,
  entry_process_summary    TEXT,
  climate_notes            TEXT,
  pet_friendliness_score   INT  NOT NULL DEFAULT 50 CHECK (pet_friendliness_score BETWEEN 0 AND 100),
  last_verified_at         TIMESTAMPTZ,
  source_urls              JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS travel_destinations_region_idx
  ON public.travel_destinations (region);

ALTER TABLE public.travel_destinations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read travel destinations"
  ON public.travel_destinations FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- Pet-Friendly Venues (matches VenueService._listColumns)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.venues (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                 TEXT NOT NULL,
  phone                TEXT,
  address              TEXT,
  area                 TEXT,
  category             TEXT NOT NULL,
  latitude             DOUBLE PRECISION,
  longitude            DOUBLE PRECISION,
  rating               NUMERIC(2,1) DEFAULT 4.0 CHECK (rating BETWEEN 0 AND 5),
  dog_friendly_status  TEXT NOT NULL DEFAULT 'verified_friendly',
  dog_friendly_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  image_url            TEXT,
  whatsapp_number      TEXT,
  website              TEXT,
  last_verified_at     TIMESTAMPTZ,
  verification_source  TEXT,
  google_place_id      TEXT,
  city                 TEXT NOT NULL DEFAULT 'Dubai',
  country_code         TEXT NOT NULL DEFAULT 'AE',
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS venues_city_idx ON public.venues (city);
CREATE INDEX IF NOT EXISTS venues_category_idx ON public.venues (category);
CREATE INDEX IF NOT EXISTS venues_latlong_idx ON public.venues (latitude, longitude);

ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read venues"
  ON public.venues FOR SELECT USING (true);

-- Materialized view for city list (used by VenueService.getAvailableCities)
CREATE TABLE IF NOT EXISTS public.venue_cities (
  city         TEXT PRIMARY KEY,
  country_code TEXT NOT NULL DEFAULT 'AE',
  venue_count  INT  NOT NULL DEFAULT 0
);

ALTER TABLE public.venue_cities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read venue cities"
  ON public.venue_cities FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- Seed: UAE Travel Destinations
-- ---------------------------------------------------------------------------

INSERT INTO public.travel_destinations
  (country_code, country_name, region, flag_emoji,
   pet_import_allowed, quarantine_required, quarantine_days,
   required_documents, vaccination_requirements, pet_friendliness_score,
   entry_process_summary, last_verified_at)
VALUES
  ('AE', 'United Arab Emirates', 'Middle East', '🇦🇪', true, false, 0,
   '["Microchip","Rabies vaccine","Health certificate","Import permit"]',
   '["Rabies within 1 year","DHPP/FVRCCP"]', 85,
   'Import permit required from MOCCAE. Health certificate issued within 10 days of travel.',
   NOW()),
  ('GB', 'United Kingdom', 'Europe', '🇬🇧', true, false, 0,
   '["Microchip","Rabies vaccine","Tapeworm treatment","Health certificate"]',
   '["Rabies","Tapeworm treatment 1–5 days before travel"]', 70,
   'Pet must enter via approved route. Tapeworm treatment required 1-5 days before arrival.',
   NOW()),
  ('DE', 'Germany', 'Europe', '🇩🇪', true, false, 0,
   '["Microchip","Rabies vaccine","EU Pet Passport"]',
   '["Rabies within 1 year"]', 75,
   'EU Pet Passport or third-country certificate required. Direct entry for vaccinated pets.',
   NOW()),
  ('US', 'United States', 'Americas', '🇺🇸', true, false, 0,
   '["Microchip (recommended)","Rabies vaccine","Health certificate"]',
   '["Rabies within 1 year for dogs"]', 65,
   'Dogs entering from countries with high dog rabies risk require additional documentation.',
   NOW()),
  ('AU', 'Australia', 'Oceania', '🇦🇺', true, true, 10,
   '["Microchip","Rabies vaccine","Blood titer test","Import permit","Health certificate"]',
   '["Rabies","Distemper","Parvovirus"]', 40,
   'Strict quarantine program at Mickleham facility. Blood titer test required 180 days before travel.',
   NOW()),
  ('CA', 'Canada', 'Americas', '🇨🇦', true, false, 0,
   '["Rabies vaccine","Health certificate"]',
   '["Rabies within 3 years"]', 75,
   'Dogs and cats from the US require only proof of rabies vaccination.',
   NOW()),
  ('FR', 'France', 'Europe', '🇫🇷', true, false, 0,
   '["Microchip","Rabies vaccine","EU Pet Passport"]',
   '["Rabies within 1 year"]', 75,
   'EU travel rules apply. ISO-standard microchip required.',
   NOW()),
  ('SA', 'Saudi Arabia', 'Middle East', '🇸🇦', true, false, 0,
   '["Microchip","Rabies vaccine","Import permit","Health certificate","MEWA approval"]',
   '["Rabies","Distemper","Parvovirus"]', 60,
   'Import permit from MEWA required in advance. Health certificate apostilled.',
   NOW()),
  ('SG', 'Singapore', 'Asia', '🇸🇬', true, true, 30,
   '["Microchip","Rabies vaccine","Import permit","Blood titer test"]',
   '["Rabies","Distemper","Parvovirus","Bordetella"]', 55,
   'Category 1 countries (including UAE) require 30-day home quarantine for dogs.',
   NOW()),
  ('JP', 'Japan', 'Asia', '🇯🇵', true, true, 180,
   '["Microchip","2x Rabies vaccines","Blood titer test","Import permit"]',
   '["Rabies x2 doses","Blood titer ≥ 0.5 IU/ml"]', 45,
   'Very strict process requiring 180-day wait after titer test. Start planning 8+ months ahead.',
   NOW())
ON CONFLICT (country_code) DO UPDATE
  SET pet_friendliness_score = EXCLUDED.pet_friendliness_score,
      updated_at = NOW();

-- ---------------------------------------------------------------------------
-- Seed: UAE Pet-Friendly Venues
-- ---------------------------------------------------------------------------

INSERT INTO public.venues
  (name, category, city, country_code, address, area,
   latitude, longitude, rating, dog_friendly_status, dog_friendly_details)
VALUES
  ('Boxpark Dubai', 'cafe', 'Dubai', 'AE',
   'Al Wasl Rd, Jumeirah', 'Jumeirah',
   25.1972, 55.2397, 4.5, 'verified_friendly',
   '{"indoor_seating":true,"outdoor_seating":true,"water_bowls":true}'),
  ('The Sustainable City Pet Garden', 'park', 'Dubai', 'AE',
   'The Sustainable City', 'Al Qudra',
   25.0302, 55.2131, 4.8, 'verified_friendly',
   '{"off_leash_area":true,"water_bowls":true}'),
  ('La Mer Beach', 'beach', 'Dubai', 'AE',
   'La Mer North, Jumeirah 1', 'Jumeirah',
   25.2196, 55.2530, 4.4, 'verified_friendly',
   '{"outdoor_seating":true,"water_bowls":true}'),
  ('Wild & The Moon', 'cafe', 'Dubai', 'AE',
   'Alserkal Avenue, Al Quoz', 'Al Quoz',
   25.1490, 55.2317, 4.6, 'verified_friendly',
   '{"indoor_seating":true,"outdoor_seating":true,"water_bowls":true,"dog_menu":true}'),
  ('Jumeirah Creekside Hotel', 'hotel', 'Dubai', 'AE',
   'Garhoud Rd', 'Garhoud',
   25.2494, 55.3291, 4.3, 'verified_friendly',
   '{"indoor_seating":true,"outdoor_seating":true}'),
  ('Al Barsha Pond Park', 'park', 'Dubai', 'AE',
   'Al Barsha 1', 'Al Barsha',
   25.1090, 55.1975, 4.5, 'verified_friendly',
   '{"off_leash_area":true,"water_bowls":true}'),
  ('Sassy the Dog Cafe', 'cafe', 'Dubai', 'AE',
   'Jumeirah Beach Rd', 'Jumeirah',
   25.2050, 55.2480, 4.7, 'verified_friendly',
   '{"indoor_seating":true,"water_bowls":true,"dog_menu":true,"treats":true}'),
  ('Creek Beach Doggy Park', 'park', 'Dubai', 'AE',
   'Dubai Creek Harbour', 'Creek Harbour',
   25.2048, 55.3470, 4.4, 'verified_friendly',
   '{"off_leash_area":true,"water_bowls":true}'),
  -- Abu Dhabi
  ('Yas Island Dog Park', 'park', 'Abu Dhabi', 'AE',
   'Yas Island', 'Yas Island',
   24.4889, 54.6111, 4.7, 'verified_friendly',
   '{"off_leash_area":true,"water_bowls":true}'),
  ('The St. Regis Abu Dhabi', 'hotel', 'Abu Dhabi', 'AE',
   'Nation Towers, Corniche', 'Corniche',
   24.4700, 54.3450, 4.8, 'verified_friendly',
   '{"indoor_seating":true,"outdoor_seating":true}'),
  ('Corniche Beach Pet Zone', 'beach', 'Abu Dhabi', 'AE',
   'Corniche Beach', 'Corniche',
   24.4670, 54.3270, 4.3, 'verified_friendly',
   '{"outdoor_seating":true,"water_bowls":true}'),
  -- Sharjah
  ('Al Noor Island', 'park', 'Sharjah', 'AE',
   'Khalid Lagoon', 'Khalid Lagoon',
   25.3560, 55.3820, 4.6, 'verified_friendly',
   '{"outdoor_seating":true,"water_bowls":true}')
ON CONFLICT DO NOTHING;

-- Populate venue_cities from venues
INSERT INTO public.venue_cities (city, country_code, venue_count)
SELECT city, country_code, COUNT(*) FROM public.venues GROUP BY city, country_code
ON CONFLICT (city) DO UPDATE SET venue_count = EXCLUDED.venue_count;
