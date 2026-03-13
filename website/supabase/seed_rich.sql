-- Optional richer seed data for Dravik.
-- Run this after setup_full.sql or after the base migration + seed.sql.
-- Safe to rerun because destinations upsert on slug.

WITH category_map AS (
  SELECT id, slug FROM public.categories
)
INSERT INTO public.destinations (
  title,
  slug,
  description,
  location,
  country,
  continent,
  latitude,
  longitude,
  difficulty,
  duration,
  distance_km,
  elevation_m,
  best_season,
  image_url,
  gallery,
  tags,
  category_id,
  avg_rating,
  review_count,
  is_featured,
  is_trending,
  source_url
)
VALUES
  ('Langtang Valley Trek','langtang-valley-trek','A classic Nepal trek through forest, Tamang villages, and alpine terrain recovering with resilient local culture.','Langtang','Nepal','Asia',28.2111,85.5603,'Moderate','7-10 days',77,3870,'March-May, October-November',NULL,ARRAY[]::TEXT[],ARRAY['nepal','valley','teahouse'],(SELECT id FROM category_map WHERE slug='trekking'),4.7,63,false,true,'https://en.wikipedia.org/wiki/Langtang_National_Park'),
  ('Manaslu Circuit','manaslu-circuit','A less crowded Himalayan circuit with remote villages, dramatic gorges, and the high Larkya La crossing.','Manaslu Region','Nepal','Asia',28.5497,84.5613,'Advanced','14-16 days',177,5106,'March-May, September-November',NULL,ARRAY[]::TEXT[],ARRAY['remote','circuit','himalaya'],(SELECT id FROM category_map WHERE slug='trekking'),4.8,58,false,true,'https://en.wikipedia.org/wiki/Manaslu'),
  ('Inca Trail to Machu Picchu','inca-trail-machu-picchu','A famous Andean trail linking archaeological sites with a dramatic entrance to Machu Picchu.','Cusco Region','Peru','South America',-13.1631,-72.5450,'Moderate','4 days',42,4215,'May-September',NULL,ARRAY[]::TEXT[],ARRAY['inca','andes','heritage'],(SELECT id FROM category_map WHERE slug='trekking'),4.8,134,true,true,'https://en.wikipedia.org/wiki/Inca_Trail_to_Machu_Picchu'),
  ('John Muir Trail Section','john-muir-trail-section','A Sierra Nevada high-country route with granite passes, alpine lakes, and classic backcountry wilderness.','California Sierra','United States','North America',37.7326,-119.5730,'Challenging','7-12 days',110,4300,'July-September',NULL,ARRAY[]::TEXT[],ARRAY['sierra','backpacking','alpine-lake'],(SELECT id FROM category_map WHERE slug='trekking'),4.7,47,false,false,'https://en.wikipedia.org/wiki/John_Muir_Trail'),
  ('Salkantay Trek','salkantay-trek','An alternative Peru trek blending glaciated mountain scenery, cloud forest, and a finish near Machu Picchu.','Cusco Region','Peru','South America',-13.2414,-72.6506,'Challenging','5 days',74,4630,'April-October',NULL,ARRAY[]::TEXT[],ARRAY['peru','glacier','andes'],(SELECT id FROM category_map WHERE slug='trekking'),4.6,52,false,false,'https://en.wikipedia.org/wiki/Salkantay'),
  ('Island Peak Climb','island-peak-climb','A popular Himalayan peak expedition used as an introduction to alpine climbing and crampon travel.','Khumbu Region','Nepal','Asia',27.9228,86.9378,'Expert','16-19 days',68,6189,'April-May, October-November',NULL,ARRAY[]::TEXT[],ARRAY['peak','alpine','himalaya'],(SELECT id FROM category_map WHERE slug='mountaineering'),4.7,39,false,false,'https://en.wikipedia.org/wiki/Imja_Tse'),
  ('Mera Peak Expedition','mera-peak-expedition','A high-altitude trekking peak with broad glacier travel and far-ranging summit views of major Himalayan giants.','Hinku Valley','Nepal','Asia',27.7025,86.8680,'Expert','16-18 days',90,6476,'April-May, October-November',NULL,ARRAY[]::TEXT[],ARRAY['trekking-peak','glacier','summit'],(SELECT id FROM category_map WHERE slug='mountaineering'),4.8,28,false,false,'https://en.wikipedia.org/wiki/Mera_Peak'),
  ('Mont Blanc Gouter Route','mont-blanc-gouter-route','The standard route on Western Europe''s highest mountain combining glacier travel, refuges, and an alpine summit push.','Chamonix','France','Europe',45.8326,6.8652,'Expert','2-3 days',20,4808,'June-September',NULL,ARRAY[]::TEXT[],ARRAY['alps','glacier','summit'],(SELECT id FROM category_map WHERE slug='mountaineering'),4.5,44,false,true,'https://en.wikipedia.org/wiki/Mont_Blanc'),
  ('Mount Elbrus South Route','mount-elbrus-south-route','A glaciated ascent of Europe''s highest peak with lift-assisted access and a high-altitude summit day.','Kabardino-Balkaria','Russia','Europe',43.3499,42.4453,'Advanced','5-8 days',24,5642,'June-September',NULL,ARRAY[]::TEXT[],ARRAY['europe','volcano','glacier'],(SELECT id FROM category_map WHERE slug='mountaineering'),4.4,31,false,false,'https://en.wikipedia.org/wiki/Mount_Elbrus'),
  ('Denali Basecamp Skills Route','denali-basecamp-skills-route','A training-oriented expedition framework focusing on glacier camping, crevasse systems, and severe weather management.','Alaska Range','United States','North America',63.0695,-151.0074,'Expert','12-16 days',35,4300,'May-June',NULL,ARRAY[]::TEXT[],ARRAY['expedition','glacier','cold'],(SELECT id FROM category_map WHERE slug='mountaineering'),4.6,19,false,false,'https://en.wikipedia.org/wiki/Denali'),
  ('Yosemite Valley Camp Loop','yosemite-valley-camp-loop','A scenic camping and day-hike base around waterfalls, granite domes, and iconic Sierra viewpoints.','Yosemite Valley','United States','North America',37.7459,-119.5332,'Easy','2-3 days',18,1220,'May-October',NULL,ARRAY[]::TEXT[],ARRAY['camping','family','granite'],(SELECT id FROM category_map WHERE slug='camping'),4.5,40,false,false,'https://en.wikipedia.org/wiki/Yosemite_Valley'),
  ('Banff Backcountry Lakes','banff-backcountry-lakes','A camp-based route linking alpine lakes, larch meadows, and Rocky Mountain viewpoints.','Banff National Park','Canada','North America',51.4968,-115.9281,'Moderate','3-4 days',36,2100,'July-September',NULL,ARRAY[]::TEXT[],ARRAY['rockies','lake','backcountry'],(SELECT id FROM category_map WHERE slug='camping'),4.7,33,false,true,'https://en.wikipedia.org/wiki/Banff_National_Park'),
  ('Lofoten Coastal Camp Route','lofoten-coastal-camp-route','A coastal camping route with sea cliffs, beaches, midnight light, and steep island ridgelines.','Lofoten','Norway','Europe',68.2042,13.5401,'Moderate','3-5 days',32,850,'June-September',NULL,ARRAY[]::TEXT[],ARRAY['coast','camping','arctic'],(SELECT id FROM category_map WHERE slug='camping'),4.8,22,false,false,'https://en.wikipedia.org/wiki/Lofoten'),
  ('Ha Long Bay Kayak Traverse','ha-long-bay-kayak-traverse','A sea-kayak journey through limestone karst islands, floating villages, and sheltered emerald waters.','Ha Long Bay','Vietnam','Asia',20.9101,107.1839,'Easy','2 days',28,0,'October-April',NULL,ARRAY[]::TEXT[],ARRAY['kayak','sea','karst'],(SELECT id FROM category_map WHERE slug='water-sports'),4.5,18,false,false,'https://en.wikipedia.org/wiki/H%E1%BA%A1_Long_Bay'),
  ('Soca River Packraft Route','soca-river-packraft-route','A turquoise alpine river adventure combining flatwater paddling, easy rapids, and Slovenia''s limestone scenery.','Soča Valley','Slovenia','Europe',46.3389,13.5524,'Moderate','1-2 days',30,480,'May-September',NULL,ARRAY[]::TEXT[],ARRAY['river','packraft','alpine'],(SELECT id FROM category_map WHERE slug='water-sports'),4.6,16,false,false,'https://en.wikipedia.org/wiki/So%C4%8Da'),
  ('Kalymnos Sport Cliffs','kalymnos-sport-cliffs','A Mediterranean climbing destination known for steep pocketed limestone and reliable conditions.','Kalymnos','Greece','Europe',36.9584,26.9803,'Advanced','4-8 days',12,350,'April-June, September-November',NULL,ARRAY[]::TEXT[],ARRAY['limestone','sport','island'],(SELECT id FROM category_map WHERE slug='rock-climbing'),4.8,41,false,true,'https://en.wikipedia.org/wiki/Kalymnos'),
  ('Railay Limestone Walls','railay-limestone-walls','Tropical climbing above beaches and caves with accessible sport routes and deep-water-solo options nearby.','Krabi','Thailand','Asia',8.0066,98.8381,'Moderate','3-6 days',9,180,'November-April',NULL,ARRAY[]::TEXT[],ARRAY['beach','climbing','tropical'],(SELECT id FROM category_map WHERE slug='rock-climbing'),4.7,37,false,false,'https://en.wikipedia.org/wiki/Railay_Beach'),
  ('Red River Gorge Classics','red-river-gorge-classics','Sandstone sport climbing area with steep routes, arches, and extensive route volume across sectors.','Kentucky','United States','North America',37.8220,-83.6274,'Moderate','2-5 days',15,320,'March-May, September-November',NULL,ARRAY[]::TEXT[],ARRAY['sandstone','sport','usa'],(SELECT id FROM category_map WHERE slug='rock-climbing'),4.6,34,false,false,'https://en.wikipedia.org/wiki/Red_River_Gorge'),
  ('Finale Ligure Trails','finale-ligure-trails','A benchmark riding zone mixing coastal weather, shuttle descents, and technical Mediterranean singletrack.','Liguria','Italy','Europe',44.1734,8.3430,'Challenging','2-4 days',55,1450,'March-June, September-November',NULL,ARRAY[]::TEXT[],ARRAY['singletrack','coast','shuttle'],(SELECT id FROM category_map WHERE slug='mountain-biking'),4.8,45,false,true,'https://en.wikipedia.org/wiki/Finale_Ligure'),
  ('Whistler Alpine Flow','whistler-alpine-flow','A big-mountain riding destination with lift access, bike park features, and natural alpine descents.','Whistler','Canada','North America',50.1163,-122.9574,'Advanced','1-3 days',38,1600,'June-September',NULL,ARRAY[]::TEXT[],ARRAY['bike-park','flow','alpine'],(SELECT id FROM category_map WHERE slug='mountain-biking'),4.9,62,true,true,'https://en.wikipedia.org/wiki/Whistler,_British_Columbia'),
  ('Cusco Sacred Valley Ride','cusco-sacred-valley-ride','A high-altitude route network through Incan terraces, mountain villages, and dry Andean trails.','Sacred Valley','Peru','South America',-13.3170,-72.1167,'Moderate','1-2 days',48,3600,'April-October',NULL,ARRAY[]::TEXT[],ARRAY['andes','bike','high-altitude'],(SELECT id FROM category_map WHERE slug='mountain-biking'),4.5,24,false,false,'https://en.wikipedia.org/wiki/Sacred_Valley'),
  ('Dolomites Alta Via Section','dolomites-alta-via-section','A compact hut-to-hut sample of the Dolomites with limestone towers, passes, and world-class alpine scenery.','Dolomites','Italy','Europe',46.4102,11.8440,'Moderate','4-6 days',52,2750,'June-September',NULL,ARRAY[]::TEXT[],ARRAY['dolomites','hut-to-hut','alps'],(SELECT id FROM category_map WHERE slug='trekking'),4.8,49,true,false,'https://en.wikipedia.org/wiki/Dolomites'),
  ('Mount Toubkal Trek','mount-toubkal-trek','A North African mountain trek with Berber villages and a non-technical summit approach to Morocco''s highest peak.','High Atlas','Morocco','Africa',31.0675,-7.9180,'Moderate','2-3 days',21,4167,'April-October',NULL,ARRAY[]::TEXT[],ARRAY['atlas','summit','berber'],(SELECT id FROM category_map WHERE slug='trekking'),4.6,35,false,false,'https://en.wikipedia.org/wiki/Toubkal'),
  ('Torres Base Viewpoint Trek','torres-base-viewpoint-trek','A shorter Patagonian route focused on the iconic towers viewpoint with strong wind and dramatic terrain.','Torres del Paine','Chile','South America',-50.9553,-72.9902,'Moderate','1 day',20,950,'November-March',NULL,ARRAY[]::TEXT[],ARRAY['patagonia','day-hike','granite'],(SELECT id FROM category_map WHERE slug='trekking'),4.7,66,false,true,'https://en.wikipedia.org/wiki/Torres_del_Paine_National_Park'),
  ('Mount Rinjani Crater Rim','mount-rinjani-crater-rim','A volcanic trekking route with crater lake views, ash slopes, and sunrise camps above Lombok.','Lombok','Indonesia','Asia',-8.4113,116.4570,'Challenging','2-3 days',27,3726,'May-October',NULL,ARRAY[]::TEXT[],ARRAY['volcano','crater','sunrise'],(SELECT id FROM category_map WHERE slug='trekking'),4.5,29,false,false,'https://en.wikipedia.org/wiki/Mount_Rinjani')
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
