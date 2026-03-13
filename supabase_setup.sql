-- =============================================
-- DesignAll - Supabase Veritabanı Kurulumu
-- SQL Editor'e yapıştır ve "Run" butonuna bas
-- =============================================

-- 1) PROJECTS TABLOSU (mevcut tabloyu güncelle veya yeniden oluştur)
-- Eğer "projects" tablon zaten varsa, eksik sütunları ekle:
DO $$
BEGIN
  -- client_name sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='client_name') THEN
    ALTER TABLE projects ADD COLUMN client_name text;
  END IF;
  -- room_type sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='room_type') THEN
    ALTER TABLE projects ADD COLUMN room_type text;
  END IF;
  -- tags sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='tags') THEN
    ALTER TABLE projects ADD COLUMN tags jsonb;
  END IF;
  -- budget sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='budget') THEN
    ALTER TABLE projects ADD COLUMN budget float8;
  END IF;
  -- status sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='status') THEN
    ALTER TABLE projects ADD COLUMN status text DEFAULT 'active';
  END IF;
  -- notes sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='notes') THEN
    ALTER TABLE projects ADD COLUMN notes text;
  END IF;
  -- user_id sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='user_id') THEN
    ALTER TABLE projects ADD COLUMN user_id uuid REFERENCES auth.users(id);
  END IF;
  -- updated_at sütunu yoksa ekle
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='projects' AND column_name='updated_at') THEN
    ALTER TABLE projects ADD COLUMN updated_at timestamptz;
  END IF;
END $$;

-- 2) CLIENTS TABLOSU
CREATE TABLE IF NOT EXISTS clients (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  email text,
  phone text,
  address text,
  notes text,
  avatar_url text,
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 3) MEASUREMENTS TABLOSU (AR ölçümleri)
CREATE TABLE IF NOT EXISTS measurements (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  label text NOT NULL DEFAULT '',
  distance_meters float8 NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- 4) BUDGET_ITEMS TABLOSU
CREATE TABLE IF NOT EXISTS budget_items (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  category text NOT NULL DEFAULT '',
  description text NOT NULL DEFAULT '',
  unit_price float8 NOT NULL DEFAULT 0,
  quantity int NOT NULL DEFAULT 1,
  is_purchased boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 5) MOODBOARD_ITEMS TABLOSU (ileride lazım olacak)
CREATE TABLE IF NOT EXISTS moodboard_items (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  type text NOT NULL DEFAULT 'image', -- 'image', 'color', 'note'
  image_url text,
  color_hex text,
  note text,
  position_x float8 DEFAULT 0,
  position_y float8 DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- =============================================
-- ROW LEVEL SECURITY (RLS) - Güvenlik Politikaları
-- Her kullanıcı sadece kendi verisini görsün
-- =============================================

-- Projects RLS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own projects" ON projects;
DROP POLICY IF EXISTS "Users can insert own projects" ON projects;
DROP POLICY IF EXISTS "Users can update own projects" ON projects;
DROP POLICY IF EXISTS "Users can delete own projects" ON projects;

CREATE POLICY "Users can view own projects" ON projects
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own projects" ON projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own projects" ON projects
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own projects" ON projects
  FOR DELETE USING (auth.uid() = user_id);

-- Clients RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own clients" ON clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON clients;
DROP POLICY IF EXISTS "Users can update own clients" ON clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON clients;

CREATE POLICY "Users can view own clients" ON clients
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own clients" ON clients
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own clients" ON clients
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own clients" ON clients
  FOR DELETE USING (auth.uid() = user_id);

-- Measurements RLS (proje sahibi üzerinden)
ALTER TABLE measurements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage measurements" ON measurements;

CREATE POLICY "Users can manage measurements" ON measurements
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = measurements.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- Budget Items RLS (proje sahibi üzerinden)
ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage budget items" ON budget_items;

CREATE POLICY "Users can manage budget items" ON budget_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = budget_items.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- Moodboard Items RLS (proje sahibi üzerinden)
ALTER TABLE moodboard_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage moodboard items" ON moodboard_items;

CREATE POLICY "Users can manage moodboard items" ON moodboard_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = moodboard_items.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- =============================================
-- STORAGE BUCKET (fotoğraf yükleme)
-- =============================================
-- Not: Storage bucket'ı SQL ile oluşturmak her zaman çalışmaz.
-- Eğer "room_previews" bucket'ın yoksa:
-- Sol menü > Storage > New Bucket > "room_previews" > Public bucket olarak oluştur

INSERT INTO storage.buckets (id, name, public)
VALUES ('room_previews', 'room_previews', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: Herkes okuyabilsin, sadece giriş yapmış kullanıcı yükleyebilsin
DROP POLICY IF EXISTS "Public read room_previews" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload room_previews" ON storage.objects;

CREATE POLICY "Public read room_previews" ON storage.objects
  FOR SELECT USING (bucket_id = 'room_previews');

CREATE POLICY "Auth upload room_previews" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'room_previews'
    AND auth.role() = 'authenticated'
  );
