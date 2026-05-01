const openAIKey = Deno.env.get("OPENAI_API_KEY");

Deno.serve(async (req) => {
  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);
  if (!openAIKey) return respond({ error: "OPENAI_API_KEY is not configured" }, 500);

  const { systemMessage, prompt } = await req.json();
  if (!systemMessage || !prompt) {
    return respond({ error: "systemMessage and prompt are required" }, 400);
  }

  const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAIKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o",
      max_tokens: 2000,
      messages: [
        { role: "system", content: systemMessage },
        { role: "user", content: prompt },
      ],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "course_plan",
          strict: true,
          schema: {
            type: "object",
            properties: {
              courseReason: { type: "string" },
              courses: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    order: { type: "integer" },
                    category: { type: "string" },
                    keyword: { type: "string" },
                    reason: { type: "string" },
                    menu: { anyOf: [{ type: "string" }, { type: "null" }] },
                    isSelected: { type: "boolean" },
                  },
                  required: ["order", "category", "keyword", "reason", "menu", "isSelected"],
                  additionalProperties: false,
                },
              },
              outfit: { type: "string" },
            },
            required: ["courseReason", "courses", "outfit"],
            additionalProperties: false,
          },
        },
      },
    }),
  });

  const body = await openAIResponse.text();
  return new Response(body, {
    status: openAIResponse.status,
    headers: { "Content-Type": "application/json" },
  });
});

function respond(body: object, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
