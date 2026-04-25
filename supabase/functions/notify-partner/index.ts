import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const { course_id } = await req.json()

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { data: course } = await supabase
      .from("courses")
      .select("user_id, partner_id, title")
      .eq("id", course_id)
      .single()

    if (!course?.partner_id) {
      return new Response("no partner", { status: 200 })
    }

    const [{ data: partnerUser }, { data: creatorUser }] = await Promise.all([
      supabase.from("users").select("fcm_token").eq("id", course.partner_id).single(),
      supabase.from("users").select("nickname").eq("id", course.user_id).single(),
    ])

    if (!partnerUser?.fcm_token) {
      return new Response("no fcm token", { status: 200 })
    }

    const accessToken = await getFCMAccessToken()
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID")!

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: partnerUser.fcm_token,
            notification: {
              title: "새로운 데이트 코스!",
              body: `${creatorUser?.nickname ?? "파트너"}가 '${course.title}' 코스를 만들었어요.`,
            },
            apns: {
              payload: { aps: { sound: "default" } },
            },
          },
        }),
      }
    )

    return new Response(JSON.stringify({ ok: fcmRes.ok }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})

async function getFCMAccessToken(): Promise<string> {
  const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!)

  const now = Math.floor(Date.now() / 1000)
  const header = { alg: "RS256", typ: "JWT" }
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_")

  const signingInput = `${encode(header)}.${encode(payload)}`

  const pemKey = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "")

  const keyData = Uint8Array.from(atob(pemKey), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  )

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput)
  )

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")

  const jwt = `${signingInput}.${sigB64}`

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const { access_token } = await tokenRes.json()
  return access_token
}
