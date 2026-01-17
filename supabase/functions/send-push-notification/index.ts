import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface PushNotificationRequest {
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

// Get OAuth2 access token from service account
async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
  token_uri: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600;

  // Create JWT header and claim
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: serviceAccount.token_uri,
    iat: now,
    exp: exp,
  };

  // Base64url encode
  const encoder = new TextEncoder();
  const headerB64 = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const claimB64 = btoa(JSON.stringify(claim))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const signatureInput = `${headerB64}.${claimB64}`;

  // Import private key and sign
  const pemContents = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signatureInput)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const jwt = `${signatureInput}.${signatureB64}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT not configured");
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const projectId = serviceAccount.project_id;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { user_id, title, body, data }: PushNotificationRequest =
      await req.json();

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: user_id, title, body",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get device tokens for the user
    const { data: tokens, error: tokensError } = await supabase
      .from("device_tokens")
      .select("token, platform")
      .eq("user_id", user_id);

    if (tokensError) {
      throw tokensError;
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: "No device tokens found for user", sent: 0 }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get access token for FCM
    const accessToken = await getAccessToken(serviceAccount);

    // Send to all devices using FCM HTTP v1 API
    const results = await Promise.all(
      tokens.map(async ({ token, platform }) => {
        try {
          const message: Record<string, unknown> = {
            message: {
              token: token,
              notification: {
                title,
                body,
              },
              data: data || {},
            },
          };

          // Add platform-specific config
          if (platform === "android") {
            message.message = {
              ...message.message as object,
              android: {
                priority: "high",
                notification: {
                  sound: "default",
                  channel_id: "default",
                },
              },
            };
          } else if (platform === "ios") {
            message.message = {
              ...message.message as object,
              apns: {
                payload: {
                  aps: {
                    sound: "default",
                    badge: 1,
                  },
                },
              },
            };
          }

          const response = await fetch(
            `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify(message),
            }
          );

          if (!response.ok) {
            const errorData = await response.json();

            // If token is invalid, remove it
            if (
              errorData.error?.details?.some(
                (d: { errorCode: string }) =>
                  d.errorCode === "UNREGISTERED" ||
                  d.errorCode === "INVALID_ARGUMENT"
              )
            ) {
              await supabase.from("device_tokens").delete().eq("token", token);
              return {
                platform,
                success: false,
                error: "Token expired, removed",
              };
            }

            return { platform, success: false, error: errorData.error?.message };
          }

          return { platform, success: true };
        } catch (err) {
          return { platform, success: false, error: String(err) };
        }
      })
    );

    const successCount = results.filter((r) => r.success).length;

    return new Response(
      JSON.stringify({
        message: `Sent ${successCount}/${tokens.length} notifications`,
        sent: successCount,
        results,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
