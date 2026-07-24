import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const TO_EMAIL = "1lclink2@att.net";
const FROM_EMAIL = "support@georgeclinkscalesdev.com";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const { message, userEmail, appVersion, iosVersion, userId } = await req.json();

  if (!message?.trim()) {
    return new Response(JSON.stringify({ error: "Message is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const html = `
    <h2>Tally Support Request</h2>
    <p><strong>From:</strong> ${userEmail ?? "unknown"}</p>
    <p><strong>Message:</strong></p>
    <p>${message.replace(/\n/g, "<br>")}</p>
    <hr>
    <p style="color:#888;font-size:12px;">
      App version: ${appVersion ?? "?"} &nbsp;|&nbsp;
      iOS: ${iosVersion ?? "?"} &nbsp;|&nbsp;
      User ID: ${userId ?? "?"}
    </p>
  `;

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: `Tally Support <${FROM_EMAIL}>`,
      to: [TO_EMAIL],
      reply_to: userEmail ? [userEmail] : undefined,
      subject: "Tally: Support Request",
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
