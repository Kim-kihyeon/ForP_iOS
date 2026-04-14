import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const jwtSecret = Deno.env.get("JWT_SECRET")!;

Deno.serve(async (req) => {
  try {
    const { accessToken } = await req.json();
    if (!accessToken) return respond({ error: "accessToken required" }, 400);

    // 1. 카카오 유저 정보 조회
    const kakaoRes = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!kakaoRes.ok) return respond({ error: "Invalid kakao token" }, 401);

    const kakaoUser = await kakaoRes.json();
    const kakaoId = String(kakaoUser.id);
    const email = kakaoUser.kakao_account?.email ?? `kakao_${kakaoId}@forp.app`;
    const nickname = kakaoUser.kakao_account?.profile?.nickname ?? "사용자";
    const password = `forp_kakao_${kakaoId}_${jwtSecret.slice(0, 8)}`;

    const admin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // 2. 기존 유저 조회
    const { data: listData } = await admin.auth.admin.listUsers();
    const existing = listData?.users.find(
      (u: any) => u.user_metadata?.kakao_id === kakaoId
    );

    const userEmail = existing?.email ?? email;

    if (!existing) {
      // 신규 유저 생성
      const { error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { kakao_id: kakaoId, nickname },
      });
      if (error) throw error;
    } else {
      // 기존 유저 패스워드 업데이트 (이전 방식으로 생성됐을 수 있음)
      await admin.auth.admin.updateUserById(existing.id, { password });
    }

    // 패스워드로 로그인해서 세션 획득
    const anonClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!);
    const { data: sessionData, error: signInError } = await anonClient.auth.signInWithPassword({
      email: userEmail,
      password,
    });
    if (signInError) throw signInError;

    return respond({
      access_token: sessionData.session!.access_token,
      refresh_token: sessionData.session!.refresh_token,
      user_id: sessionData.user!.id,
      email: userEmail,
      nickname,
    });
  } catch (e) {
    console.log("ERROR:", String(e));
    return respond({ error: String(e) }, 500);
  }
});

function respond(body: object, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
