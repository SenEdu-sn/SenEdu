import { createBrowserClient } from "@supabase/ssr";

/**
 * Client Supabase pour le code qui s'exécute dans le navigateur
 * (composants marqués "use client").
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
