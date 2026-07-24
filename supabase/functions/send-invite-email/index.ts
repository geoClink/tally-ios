import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const FROM_EMAIL = "support@georgeclinkscalesdev.com";
const APP_STORE_URL = "https://apps.apple.com/app/id6775275483";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const { inviterEmail, inviteeEmail, workspaceName, clientName } = await req.json();

  if (!inviteeEmail || !workspaceName) {
    return new Response(JSON.stringify({ error: "inviteeEmail and workspaceName are required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const inviterDisplay = inviterEmail ?? "Someone";

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body style="margin:0;padding:0;background:#f5f5f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f5f5f7;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="520" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background:#007AFF;padding:32px;text-align:center;">
              <div style="font-size:36px;margin-bottom:8px;">⏱</div>
              <div style="color:#ffffff;font-size:22px;font-weight:700;letter-spacing:-0.3px;">Tally</div>
              <div style="color:rgba(255,255,255,0.75);font-size:13px;margin-top:4px;">Time Tracking</div>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:36px 40px 28px;">
              <p style="margin:0 0 6px;color:#6e6e73;font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">You're invited</p>
              <h1 style="margin:0 0 20px;color:#1d1d1f;font-size:24px;font-weight:700;letter-spacing:-0.3px;line-height:1.2;">
                Join ${workspaceName} on Tally
              </h1>
              <p style="margin:0 0 24px;color:#3a3a3c;font-size:16px;line-height:1.6;">
                <strong>${inviterDisplay}</strong> invited you to track time together on the <strong>${clientName}</strong> project.
              </p>

              <!-- Workspace card -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background:#f5f5f7;border-radius:12px;margin-bottom:28px;">
                <tr>
                  <td style="padding:18px 20px;">
                    <div style="color:#6e6e73;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:6px;">Workspace</div>
                    <div style="color:#1d1d1f;font-size:17px;font-weight:600;">${workspaceName}</div>
                    <div style="color:#007AFF;font-size:14px;margin-top:2px;">${clientName}</div>
                  </td>
                </tr>
              </table>

              <p style="margin:0 0 24px;color:#3a3a3c;font-size:15px;line-height:1.6;">
                Tally is a simple time tracker for freelancers. Start a timer, stop it when you're done — your hours sync with your team automatically.
              </p>

              <!-- CTA button -->
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:28px;">
                <tr>
                  <td align="center">
                    <a href="${APP_STORE_URL}" style="display:inline-block;background:#007AFF;color:#ffffff;text-decoration:none;font-size:16px;font-weight:600;padding:14px 40px;border-radius:980px;letter-spacing:-0.1px;">
                      Download Tally
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Important note -->
              <table width="100%" cellpadding="0" cellspacing="0" style="border:1.5px solid #e5e5ea;border-radius:10px;margin-bottom:8px;">
                <tr>
                  <td style="padding:14px 16px;">
                    <p style="margin:0;color:#3a3a3c;font-size:14px;line-height:1.5;">
                      <strong>Important:</strong> Sign in with <strong>${inviteeEmail}</strong> — that's the email address your invite is tied to. You'll be added to the workspace automatically.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:20px 40px 32px;border-top:1px solid #f0f0f0;">
              <p style="margin:0;color:#aeaeb2;font-size:12px;line-height:1.5;text-align:center;">
                You received this because ${inviterDisplay} entered your email in Tally.<br>
                If you weren't expecting this, you can ignore it.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: `Tally <${FROM_EMAIL}>`,
      to: [inviteeEmail],
      reply_to: inviterEmail ? [inviterEmail] : undefined,
      subject: `${inviterDisplay} invited you to join ${workspaceName} on Tally`,
      html,
    }),
  });

  const data = await res.json();

  if (!res.ok) {
    return new Response(JSON.stringify({ error: data }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
