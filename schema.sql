-- 1. Create tables if they don't exist yet
CREATE TABLE IF NOT EXISTS public.novels (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  author_name text NOT NULL,
  genre text DEFAULT 'Fantasy',
  cover_url text,
  synopsis text NOT NULL,
  status text DEFAULT 'Ongoing',
  is_mature boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chapters (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  novel_id uuid REFERENCES public.novels(id) ON DELETE CASCADE NOT NULL,
  chapter_number integer NOT NULL,
  chapter_title text NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  novel_id uuid REFERENCES public.novels(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, novel_id)
);

-- 2. Grant table permissions to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.novels, public.chapters TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.novels, public.chapters, public.bookmarks TO authenticated;
GRANT SELECT ON TABLE public.bookmarks TO authenticated;

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.novels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

-- 4. Drop old policies if re-running, then create clean policies
DROP POLICY IF EXISTS "Public read novels" ON public.novels;
DROP POLICY IF EXISTS "Authors insert novels" ON public.novels;
DROP POLICY IF EXISTS "Authors update own novels" ON public.novels;
DROP POLICY IF EXISTS "Authors delete own novels" ON public.novels;

CREATE POLICY "Public read novels" ON public.novels FOR SELECT USING (true);
CREATE POLICY "Authors insert novels" ON public.novels FOR INSERT TO authenticated WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors update own novels" ON public.novels FOR UPDATE TO authenticated USING (auth.uid() = author_id);
CREATE POLICY "Authors delete own novels" ON public.novels FOR DELETE TO authenticated USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Public read chapters" ON public.chapters;
DROP POLICY IF EXISTS "Authors insert chapters" ON public.chapters;
DROP POLICY IF EXISTS "Authors update chapters" ON public.chapters;
DROP POLICY IF EXISTS "Authors delete chapters" ON public.chapters;

CREATE POLICY "Public read chapters" ON public.chapters FOR SELECT USING (true);
CREATE POLICY "Authors insert chapters" ON public.chapters FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.novels WHERE id = novel_id AND author_id = auth.uid()));
CREATE POLICY "Authors update chapters" ON public.chapters FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.novels WHERE id = novel_id AND author_id = auth.uid()));
CREATE POLICY "Authors delete chapters" ON public.chapters FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.novels WHERE id = novel_id AND author_id = auth.uid()));

DROP POLICY IF EXISTS "Users manage own bookmarks" ON public.bookmarks;
CREATE POLICY "Users manage own bookmarks" ON public.bookmarks FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

