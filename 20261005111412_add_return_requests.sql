/*
# Add safe return requests

1. New Table
- `lost_found_return_requests` stores private contact and handoff details for a possible match.
- `report_id` identifies the public item report.
- `requester_id` identifies the signed-in person starting the conversation.
- `meeting_location`, `meeting_time`, and `verification_note` are private handoff details.
- `message` contains the requester's note.
- `status` tracks pending, accepted, declined, or completed.
- `created_at` records when the request was made.

2. Security
- Row Level Security is enabled.
- Only authenticated users can create requests.
- A request is visible only to its requester or the owner of the linked report.
- Only those participants can update or delete the request.

3. Important Notes
- Public item browsing never exposes contact details.
- Meeting information is shared only after the two authenticated participants can access the request.
*/

CREATE TABLE IF NOT EXISTS public.lost_found_return_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES public.lost_found_reports(id) ON DELETE CASCADE,
  requester_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  meeting_location text NOT NULL CHECK (char_length(meeting_location) BETWEEN 2 AND 160),
  meeting_time timestamptz NOT NULL,
  verification_note text NOT NULL CHECK (char_length(verification_note) BETWEEN 2 AND 500),
  message text NOT NULL DEFAULT '' CHECK (char_length(message) <= 1000),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS lost_found_return_requests_report_idx ON public.lost_found_return_requests(report_id);
CREATE INDEX IF NOT EXISTS lost_found_return_requests_requester_idx ON public.lost_found_return_requests(requester_id);

ALTER TABLE public.lost_found_return_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view return requests" ON public.lost_found_return_requests;
CREATE POLICY "Participants can view return requests"
ON public.lost_found_return_requests FOR SELECT
TO authenticated
USING (
  auth.uid() = requester_id
  OR EXISTS (
    SELECT 1 FROM public.lost_found_reports
    WHERE lost_found_reports.id = lost_found_return_requests.report_id
    AND lost_found_reports.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Signed in users can request a return" ON public.lost_found_return_requests;
CREATE POLICY "Signed in users can request a return"
ON public.lost_found_return_requests FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Participants can update return requests" ON public.lost_found_return_requests;
CREATE POLICY "Participants can update return requests"
ON public.lost_found_return_requests FOR UPDATE
TO authenticated
USING (
  auth.uid() = requester_id
  OR EXISTS (
    SELECT 1 FROM public.lost_found_reports
    WHERE lost_found_reports.id = lost_found_return_requests.report_id
    AND lost_found_reports.user_id = auth.uid()
  )
)
WITH CHECK (
  auth.uid() = requester_id
  OR EXISTS (
    SELECT 1 FROM public.lost_found_reports
    WHERE lost_found_reports.id = lost_found_return_requests.report_id
    AND lost_found_reports.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Participants can delete return requests" ON public.lost_found_return_requests;
CREATE POLICY "Participants can delete return requests"
ON public.lost_found_return_requests FOR DELETE
TO authenticated
USING (
  auth.uid() = requester_id
  OR EXISTS (
    SELECT 1 FROM public.lost_found_reports
    WHERE lost_found_reports.id = lost_found_return_requests.report_id
    AND lost_found_reports.user_id = auth.uid()
  )
);
