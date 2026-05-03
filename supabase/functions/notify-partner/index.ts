import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

function subjectParticle(word: string): string {
  if (!word) return "가"
  const code = word.charCodeAt(word.length - 1)
  if (code < 0xAC00 || code > 0xD7A3) return "가"
  return (code - 0xAC00) % 28 !== 0 ? "이가" : "가"
}

serve(async (req) => {
  try {
    const { course_id } = await req.json()
    console.log("[notify-partner] course_id:", course_id)

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { data: course, error: courseError } = await supabase
      .from("courses")
      .select("user_id, partner_id, title")
      .eq("id", course_id)
      .single()

    if (courseError) console.log("[notify-partner] courseError:", courseError)
    if (!course?.partner_id) {
      console.log("[notify-partner] no partner_id")
      return new Response("no partner", { status: 200 })
    }

    const [
      { data: partnerUser, error: partnerError },
      { data: creatorUser },
      { data: partnerPreference, error: preferenceError },
    ] = await Promise.all([
      supabase.from("users").select("fcm_token").eq("id", course.partner_id).single(),
      supabase.from("users").select("nickname").eq("id", course.user_id).single(),
      supabase
        .from("notification_preferences")
        .select("push_enabled, partner_enabled")
        .eq("user_id", course.partner_id)
        .maybeSingle(),
    ])

    if (partnerError) console.log("[notify-partner] partnerError:", partnerError)
    if (preferenceError) console.log("[notify-partner] preferenceError:", preferenceError)
    console.log("[notify-partner] fcm_token:", partnerUser?.fcm_token ? "exists" : "null")

    if (partnerPreference && (!partnerPreference.push_enabled || !partnerPreference.partner_enabled)) {
      return new Response("notification disabled", { status: 200 })
    }

    if (!partnerUser?.fcm_token) {
      return new Response("no fcm token", { status: 200 })
    }

    console.log("[notify-partner] fetching access token...")
    const accessToken = await getFCMAccessToken()
    console.log("[notify-partner] access token length:", accessToken?.length ?? 0)

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
              body: `${creatorUser?.nickname ?? "파트너"}${subjectParticle(creatorUser?.nickname ?? "파트너")} '${course.title}' 코스를 만들었어요.`,
            },
            apns: {
              payload: { aps: { sound: "default" } },
            },
          },
        }),
      }
    )

    const fcmBody = await fcmRes.text()
    console.log("[notify-partner] fcm status:", fcmRes.status, "body:", fcmBody)

    return new Response(JSON.stringify({ ok: fcmRes.ok }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })
  } catch (e) {
    console.log("[notify-partner] error:", String(e))
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})

async function getFCMAccessToken(): Promise<string> {
  const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!
  const sa = JSON.parse(saRaw)

  const now = Math.floor(Date.now() / 1000)
  const header = { alg: "RS256", typ: "JWT" }
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }

  const encodeBase64Url = (data: string) =>
    btoa(data).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")

  const headerB64 = encodeBase64Url(JSON.stringify(header))
  const payloadB64 = encodeBase64Url(JSON.stringify(payload))
  const signingInput = `${headerB64}.${payloadB64}`

  const privateKeyPem = sa.private_key
    .replace(/\\n/g, "\n")
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "")
    .trim()

  const keyData = Uint8Array.from(atob(privateKeyPem), (c) => c.charCodeAt(0))

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

  const tokenJson = await tokenRes.json()
  console.log("[notify-partner] token status:", tokenRes.status, "body:", JSON.stringify(tokenJson))
  if (!tokenJson.access_token) {
    throw new Error(`OAuth2 token error: ${JSON.stringify(tokenJson)}`)
  }
  return tokenJson.access_token
}
