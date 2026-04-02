-- Til1m Database Schema
-- Run this in Supabase SQL Editor

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== ENUMS ====================

CREATE TYPE word_level AS ENUM ('A1', 'A2', 'B1', 'B2', 'C1', 'C2');
CREATE TYPE part_of_speech AS ENUM ('noun', 'verb', 'adjective', 'adverb', 'phrase');
CREATE TYPE ui_language AS ENUM ('ru', 'ky');
CREATE TYPE app_theme AS ENUM ('light', 'dark', 'system');
CREATE TYPE word_status AS ENUM ('new', 'learning', 'known');
CREATE TYPE translation_language AS ENUM ('ru', 'ky');

-- ==================== TABLES ====================

-- Words
CREATE TABLE words (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  word            TEXT NOT NULL,
  transcription_text TEXT,
  audio_url       TEXT,
  image_url       TEXT,
  level           word_level NOT NULL,
  part_of_speech  part_of_speech NOT NULL,
  source          TEXT DEFAULT 'manual',
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- Word Translations (RU / KY)
CREATE TABLE word_translations (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  word_id     UUID NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  language    translation_language NOT NULL,
  translation TEXT NOT NULL,
  synonyms    TEXT[] DEFAULT '{}'
);

-- Word Examples
CREATE TABLE word_examples (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  word_id     UUID NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  example_en  TEXT NOT NULL,
  example_ru  TEXT,
  example_ky  TEXT,
  order_index INT DEFAULT 0
);

-- User Settings
CREATE TABLE user_settings (
  user_id       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_goal    INT DEFAULT 5,
  english_level word_level DEFAULT 'A1',
  ui_language   ui_language DEFAULT 'ru',
  reminder_time TIME,
  theme         app_theme DEFAULT 'system',
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- User Word Progress (SM-2)
CREATE TABLE user_word_progress (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  word_id         UUID NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  status          word_status DEFAULT 'new',
  next_review_at  TIMESTAMPTZ,
  ease_factor     FLOAT DEFAULT 2.5,
  repetitions     INT DEFAULT 0,
  last_reviewed_at TIMESTAMPTZ,
  UNIQUE(user_id, word_id)
);

-- User Favorites
CREATE TABLE user_favorites (
  user_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  word_id  UUID NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, word_id)
);

-- ==================== INDEXES ====================

CREATE INDEX idx_words_level ON words(level);
CREATE INDEX idx_word_translations_word_id ON word_translations(word_id);
CREATE INDEX idx_word_examples_word_id ON word_examples(word_id);
CREATE INDEX idx_user_word_progress_user ON user_word_progress(user_id);
CREATE INDEX idx_user_word_progress_review ON user_word_progress(user_id, next_review_at);
CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);

-- ==================== ROW LEVEL SECURITY ====================

ALTER TABLE words ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_examples ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_word_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Words: public read
CREATE POLICY "words_public_read" ON words FOR SELECT USING (true);
CREATE POLICY "word_translations_public_read" ON word_translations FOR SELECT USING (true);
CREATE POLICY "word_examples_public_read" ON word_examples FOR SELECT USING (true);

-- User settings: own data only
CREATE POLICY "user_settings_own" ON user_settings
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- User progress: own data only
CREATE POLICY "user_progress_own" ON user_word_progress
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- User favorites: own data only
CREATE POLICY "user_favorites_own" ON user_favorites
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ==================== TRIGGER: auto-create user_settings ====================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
