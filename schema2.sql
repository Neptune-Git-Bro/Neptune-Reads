INSERT INTO storage.buckets (id, name, public)
VALUES ('neptune-media', 'neptune-media', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read neptune-media" ON storage.objects;
CREATE POLICY "Public read neptune-media"
ON storage.objects FOR SELECT
USING (bucket_id = 'neptune-media');

DROP POLICY IF EXISTS "Authenticated upload neptune-media" ON storage.objects;
CREATE POLICY "Authenticated upload neptune-media"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'neptune-media');

DROP POLICY IF EXISTS "Authenticated update neptune-media" ON storage.objects;
CREATE POLICY "Authenticated update neptune-media"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'neptune-media');
