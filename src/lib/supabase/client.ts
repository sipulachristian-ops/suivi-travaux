import { createBrowserClient } from "@supabase/ssr";

// Client Supabase côté navigateur (pages et composants interactifs).
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
