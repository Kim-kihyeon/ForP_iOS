import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond({ error: "Authorization required" }, 401);

  const userClient = createClient(supabaseUrl, serviceRoleKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return respond({ error: "Invalid session" }, 401);
  }

  const userId = userData.user.id;

  const deletions = [
    admin.from("wishlist_places").delete().eq("user_id", userId),
    admin.from("anniversaries").delete().eq("user_id", userId),
    admin.from("partners").delete().eq("user_id", userId),
    admin.from("partner_connections").delete().or(`requester_id.eq.${userId},receiver_id.eq.${userId}`),
    admin.from("courses").delete().or(`user_id.eq.${userId},partner_id.eq.${userId}`),
    admin.from("users").delete().eq("id", userId),
  ];

  for (const deletion of deletions) {
    const { error } = await deletion;
    if (error) return respond({ error: error.message }, 500);
  }

  const { error: deleteUserError } = await admin.auth.admin.deleteUser(userId);
  if (deleteUserError) return respond({ error: deleteUserError.message }, 500);

  return respond({ ok: true });
});

function respond(body: object, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
