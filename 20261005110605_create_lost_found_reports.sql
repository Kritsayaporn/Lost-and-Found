/*
# Create Lost & Found KMITL reports

1. New Tables
- `lost_found_reports` stores public lost and found item reports.
- `id` uniquely identifies each report.
- `user_id` links authenticated reports to their owner and defaults to the signed-in user.
- `type` identifies whether the item is lost or found.
- `title`, `description`, `category`, `location`, `image_url` describe the item.
- `status` tracks whether a report is active, matched, or returned.
- `created_at` records when the report was published.

2. Security
- Row Level Security is enabled.
- Anyone can browse reports so the community can search for items.
- Only authenticated users can create reports.
- Users can edit or remove only reports they own.

3. Important Notes
- Reports intentionally remain publicly readable to support matching.
- Ownership is enforced by `auth.uid()` and the database default on `user_id`.
*/

CREATE TABLE IF NOT EXISTS public.lost_found_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  type text NOT NULL CHECK (type IN ('lost', 'found')),
  title text NOT NULL CHECK (char_length(title) BETWEEN 2 AND 120),
  description text NOT NULL CHECK (char_length(description) BETWEEN 2 AND 2000),
  category text NOT NULL DEFAULT 'Other',
  location text NOT NULL,
  image_url text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'matched', 'returned')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS lost_found_reports_type_idx ON public.lost_found_reports(type);
CREATE INDEX IF NOT EXISTS lost_found_reports_status_idx ON public.lost_found_reports(status);
CREATE INDEX IF NOT EXISTS lost_found_reports_created_at_idx ON public.lost_found_reports(created_at DESC);

ALTER TABLE public.lost_found_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can browse reports" ON public.lost_found_reports;
CREATE POLICY "Anyone can browse reports"
ON public.lost_found_reports FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Signed in users can create reports" ON public.lost_found_reports;
CREATE POLICY "Signed in users can create reports"
ON public.lost_found_reports FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their reports" ON public.lost_found_reports;
CREATE POLICY "Users can update their reports"
ON public.lost_found_reports FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their reports" ON public.lost_found_reports;
CREATE POLICY "Users can delete their reports"
ON public.lost_found_reports FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
