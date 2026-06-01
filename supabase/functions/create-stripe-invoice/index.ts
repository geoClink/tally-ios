// Supabase Edge Function: create-stripe-invoice
// Deploy: supabase functions deploy create-stripe-invoice
// Secrets: supabase secrets set STRIPE_SECRET_KEY=sk_live_...

import Stripe from "https://esm.sh/stripe@14?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

Deno.serve(async (req) => {
  // Only POST
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Verify Supabase auth header
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const body = await req.json() as {
      clientEmail: string;
      clientName: string;
      lineItems: Array<{ description: string; hours: number; rate: number }>;
      currency?: string;
    };

    const { clientEmail, clientName, lineItems, currency = "usd" } = body;

    // Build Stripe line items
    const stripeLineItems = lineItems.map((item) => ({
      price_data: {
        currency,
        product_data: { name: item.description },
        unit_amount: Math.round(item.rate * 100), // cents per hour
      },
      quantity: Math.round(item.hours * 100), // quantity in hundredths so 1.5 hrs = 150
    }));

    // Create a Stripe invoice
    const customer = await stripe.customers.create({
      email: clientEmail,
      name: clientName,
    });

    for (const item of stripeLineItems) {
      await stripe.invoiceItems.create({
        customer: customer.id,
        price_data: {
          currency,
          product_data: { name: item.price_data.product_data.name },
          unit_amount: Math.round(
            (item.price_data.unit_amount * item.quantity) / 100
          ),
        },
        quantity: 1,
      });
    }

    const invoice = await stripe.invoices.create({
      customer: customer.id,
      collection_method: "send_invoice",
      days_until_due: 30,
      auto_advance: true,
    });

    const finalized = await stripe.invoices.finalizeInvoice(invoice.id);

    return new Response(
      JSON.stringify({
        invoiceUrl: finalized.hosted_invoice_url,
        invoiceId: finalized.id,
        amountDue: finalized.amount_due,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err) {
    console.error(err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { headers: { "Content-Type": "application/json" }, status: 500 }
    );
  }
});
