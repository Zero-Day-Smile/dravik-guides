-- Dravik one-shot setup for a new Supabase project.
-- Paste this whole file into Supabase SQL Editor and run once.

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Categories
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  image_url TEXT,
  icon TEXT,
  item_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
CREATE POLICY "Categories are viewable by everyone" ON public.categories FOR SELECT USING (true);

-- Destinations
CREATE TABLE IF NOT EXISTS public.destinations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  location TEXT,
  country TEXT,
  continent TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  difficulty TEXT CHECK (difficulty IN ('Easy', 'Moderate', 'Challenging', 'Advanced', 'Expert')),
  duration TEXT,
  distance_km DOUBLE PRECISION,
  elevation_m DOUBLE PRECISION,
  best_season TEXT,
  image_url TEXT,
  gallery TEXT[],
  tags TEXT[],
  category_id UUID REFERENCES public.categories(id),
  avg_rating DOUBLE PRECISION DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT false,
  is_trending BOOLEAN DEFAULT false,
  source_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.destinations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Destinations are viewable by everyone" ON public.destinations;
CREATE POLICY "Destinations are viewable by everyone" ON public.destinations FOR SELECT USING (true);

CREATE INDEX IF NOT EXISTS idx_destinations_category ON public.destinations(category_id);
CREATE INDEX IF NOT EXISTS idx_destinations_country ON public.destinations(country);
CREATE INDEX IF NOT EXISTS idx_destinations_difficulty ON public.destinations(difficulty);
CREATE INDEX IF NOT EXISTS idx_destinations_featured ON public.destinations(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_destinations_trending ON public.destinations(is_trending) WHERE is_trending = true;
CREATE INDEX IF NOT EXISTS idx_destinations_tags ON public.destinations USING GIN(tags);

DROP TRIGGER IF EXISTS update_destinations_updated_at ON public.destinations;
CREATE TRIGGER update_destinations_updated_at
  BEFORE UPDATE ON public.destinations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  location TEXT,
  experience_level TEXT CHECK (experience_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
  interests TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data ->> 'display_name', split_part(NEW.email, '@', 1)))
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Reviews
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  destination_id UUID NOT NULL REFERENCES public.destinations(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  content TEXT,
  photos TEXT[],
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, destination_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON public.reviews;
DROP POLICY IF EXISTS "Users can create reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can update their own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can delete their own reviews" ON public.reviews;
CREATE POLICY "Reviews are viewable by everyone" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users can create reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own reviews" ON public.reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reviews" ON public.reviews FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_reviews_destination ON public.reviews(destination_id);

DROP TRIGGER IF EXISTS update_reviews_updated_at ON public.reviews;
CREATE TRIGGER update_reviews_updated_at
  BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.update_destination_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.destinations SET
    avg_rating = (SELECT COALESCE(AVG(rating), 0) FROM public.reviews WHERE destination_id = COALESCE(NEW.destination_id, OLD.destination_id)),
    review_count = (SELECT COUNT(*) FROM public.reviews WHERE destination_id = COALESCE(NEW.destination_id, OLD.destination_id))
  WHERE id = COALESCE(NEW.destination_id, OLD.destination_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS update_rating_on_review ON public.reviews;
CREATE TRIGGER update_rating_on_review
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_destination_rating();

-- Saved destinations
CREATE TABLE IF NOT EXISTS public.saved_destinations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  destination_id UUID NOT NULL REFERENCES public.destinations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, destination_id)
);

ALTER TABLE public.saved_destinations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their saved destinations" ON public.saved_destinations;
DROP POLICY IF EXISTS "Users can save destinations" ON public.saved_destinations;
DROP POLICY IF EXISTS "Users can unsave destinations" ON public.saved_destinations;
CREATE POLICY "Users can view their saved destinations" ON public.saved_destinations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can save destinations" ON public.saved_destinations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unsave destinations" ON public.saved_destinations FOR DELETE USING (auth.uid() = user_id);

-- Trips
CREATE TABLE IF NOT EXISTS public.trips (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  destination_id UUID REFERENCES public.destinations(id),
  start_date DATE,
  end_date DATE,
  status TEXT CHECK (status IN ('planning', 'upcoming', 'active', 'completed', 'cancelled')) DEFAULT 'planning',
  gear_checklist JSONB DEFAULT '[]'::jsonb,
  notes TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own trips" ON public.trips;
DROP POLICY IF EXISTS "Users can create trips" ON public.trips;
DROP POLICY IF EXISTS "Users can update their own trips" ON public.trips;
DROP POLICY IF EXISTS "Users can delete their own trips" ON public.trips;
CREATE POLICY "Users can view their own trips" ON public.trips FOR SELECT USING (auth.uid() = user_id OR is_public = true);
CREATE POLICY "Users can create trips" ON public.trips FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own trips" ON public.trips FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own trips" ON public.trips FOR DELETE USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS update_trips_updated_at ON public.trips;
CREATE TRIGGER update_trips_updated_at
  BEFORE UPDATE ON public.trips
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Starter categories
INSERT INTO public.categories (name, slug, description, icon, item_count)
VALUES
  ('Trekking', 'trekking', 'Multi-day trails, scenic routes, and iconic long-distance hikes.', 'mountain', 0),
  ('Mountaineering', 'mountaineering', 'High-altitude routes, glacier travel, and summit objectives.', 'mountain-snow', 0),
  ('Camping', 'camping', 'Camp-based outdoor adventures from alpine meadows to remote valleys.', 'tent', 0),
  ('Water Sports', 'water-sports', 'Lakes, rivers, paddling routes, and water-focused escapes.', 'waves', 0),
  ('Rock Climbing', 'rock-climbing', 'Crags, alpine walls, and classic climbing zones.', 'flame', 0),
  ('Mountain Biking', 'mountain-biking', 'Singletrack, bikepacking routes, and high-country descents.', 'bike', 0)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon;

-- Seed destinations
WITH category_map AS (
  SELECT id, slug FROM public.categories
)
INSERT INTO public.destinations (
  title, slug, description, location, country, continent, latitude, longitude,
  difficulty, duration, distance_km, elevation_m, best_season, image_url, gallery,
  tags, category_id, avg_rating, review_count, is_featured, is_trending, source_url
)
VALUES
  ('Everest Base Camp Trek','everest-base-camp-trek','Nepal''s classic high-altitude trek through the Khumbu with Sherpa villages, suspension bridges, and close views of Everest.','Khumbu Region','Nepal','Asia',28.0043,86.8571,'Challenging','12-14 days',130,5364,'March-May, October-November',NULL,ARRAY[]::TEXT[],ARRAY['himalaya','altitude','base-camp','teahouse'],(SELECT id FROM category_map WHERE slug='trekking'),4.9,186,true,true,'https://en.wikipedia.org/wiki/Everest_Base_Camp'),
  ('Annapurna Circuit','annapurna-circuit','A legendary Himalayan circuit crossing deep valleys, high passes, and varied landscapes around the Annapurna massif.','Annapurna Region','Nepal','Asia',28.5970,83.9311,'Advanced','14-18 days',160,5416,'March-May, September-November',NULL,ARRAY[]::TEXT[],ARRAY['himalaya','thorong-la','teahouse','circuit'],(SELECT id FROM category_map WHERE slug='trekking'),4.8,142,true,true,'https://en.wikipedia.org/wiki/Annapurna_Circuit'),
  ('Tour du Mont Blanc','tour-du-mont-blanc','An iconic alpine circuit through France, Italy, and Switzerland with dramatic glaciers, passes, and mountain villages.','Mont Blanc Massif','France','Europe',45.9237,6.8694,'Moderate','10-12 days',170,2665,'June-September',NULL,ARRAY[]::TEXT[],ARRAY['alps','hut-to-hut','cross-border','glacier-views'],(SELECT id FROM category_map WHERE slug='trekking'),4.7,98,true,false,'https://en.wikipedia.org/wiki/Tour_du_Mont_Blanc'),
  ('Kilimanjaro Marangu Route','kilimanjaro-marangu-route','A hut-supported ascent of Africa''s highest peak with equatorial forest, moorland, and a summit push to Uhuru Peak.','Kilimanjaro National Park','Tanzania','Africa',-3.0758,37.3533,'Advanced','5-6 days',72,5895,'January-March, June-October',NULL,ARRAY[]::TEXT[],ARRAY['summit','africa','hut-route','volcano'],(SELECT id FROM category_map WHERE slug='mountaineering'),4.6,77,false,true,'https://en.wikipedia.org/wiki/Mount_Kilimanjaro'),
  ('Aconcagua Normal Route','aconcagua-normal-route','A high-altitude expedition route to the highest mountain in the Americas, emphasizing acclimatization and weather windows.','Mendoza Province','Argentina','South America',-32.6532,-70.0109,'Expert','16-20 days',60,6961,'December-February',NULL,ARRAY[]::TEXT[],ARRAY['seven-summits','expedition','altitude','andes'],(SELECT id FROM category_map WHERE slug='mountaineering'),4.8,51,false,true,'https://en.wikipedia.org/wiki/Aconcagua'),
  ('Patagonia W Trek','patagonia-w-trek','A hut-and-camp route through Torres del Paine featuring granite towers, glacial lakes, and fierce Patagonian weather.','Torres del Paine','Chile','South America',-50.9423,-73.4068,'Moderate','4-5 days',80,900,'November-March',NULL,ARRAY[]::TEXT[],ARRAY['patagonia','glacier','camping','national-park'],(SELECT id FROM category_map WHERE slug='camping'),4.8,123,true,true,'https://en.wikipedia.org/wiki/Torres_del_Paine_National_Park'),
  ('Milford Track','milford-track','One of New Zealand''s classic Great Walks with rainforest, alpine passes, and organized backcountry hut stops.','Fiordland National Park','New Zealand','Oceania',-44.7652,167.8380,'Moderate','4 days',53.5,1154,'October-April',NULL,ARRAY[]::TEXT[],ARRAY['great-walk','hut','waterfalls','fiordland'],(SELECT id FROM category_map WHERE slug='camping'),4.7,64,false,false,'https://en.wikipedia.org/wiki/Milford_Track'),
  ('Lake Atitlan Kayak Circuit','lake-atitlan-kayak-circuit','A scenic multi-stop paddle journey across volcanic shores, local villages, and highland waters of Lake Atitlan.','Lake Atitlan','Guatemala','North America',14.6900,-91.2029,'Easy','1-2 days',24,1562,'November-April',NULL,ARRAY[]::TEXT[],ARRAY['kayak','lake','volcano','paddle'],(SELECT id FROM category_map WHERE slug='water-sports'),4.5,21,false,false,'https://en.wikipedia.org/wiki/Lake_Atitl%C3%A1n'),
  ('El Potrero Chico Sport Climbing','el-potrero-chico-sport-climbing','A world-class limestone climbing area with multi-pitch sport routes and winter-friendly conditions.','Nuevo Leon','Mexico','North America',25.9522,-100.4775,'Advanced','3-7 days',18,700,'November-March',NULL,ARRAY[]::TEXT[],ARRAY['sport-climbing','limestone','multi-pitch','winter'],(SELECT id FROM category_map WHERE slug='rock-climbing'),4.6,38,false,false,'https://en.wikipedia.org/wiki/El_Potrero_Chico'),
  ('Moab Whole Enchilada','moab-whole-enchilada','A famous mountain bike descent from alpine forest to desert slickrock with huge elevation loss and varied terrain.','Moab, Utah','United States','North America',38.5733,-109.5498,'Challenging','1 day',43,2400,'May-June, September-October',NULL,ARRAY[]::TEXT[],ARRAY['singletrack','desert','bike','downhill'],(SELECT id FROM category_map WHERE slug='mountain-biking'),4.9,56,true,true,'https://en.wikipedia.org/wiki/Moab,_Utah')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  location = EXCLUDED.location,
  country = EXCLUDED.country,
  continent = EXCLUDED.continent,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  difficulty = EXCLUDED.difficulty,
  duration = EXCLUDED.duration,
  distance_km = EXCLUDED.distance_km,
  elevation_m = EXCLUDED.elevation_m,
  best_season = EXCLUDED.best_season,
  image_url = EXCLUDED.image_url,
  gallery = EXCLUDED.gallery,
  tags = EXCLUDED.tags,
  category_id = EXCLUDED.category_id,
  avg_rating = EXCLUDED.avg_rating,
  review_count = EXCLUDED.review_count,
  is_featured = EXCLUDED.is_featured,
  is_trending = EXCLUDED.is_trending,
  source_url = EXCLUDED.source_url,
  updated_at = now();

UPDATE public.categories c
SET item_count = counts.destination_count
FROM (
  SELECT category_id, COUNT(*)::INTEGER AS destination_count
  FROM public.destinations
  WHERE category_id IS NOT NULL
  GROUP BY category_id
) counts
WHERE counts.category_id = c.id;