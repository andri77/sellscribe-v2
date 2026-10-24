// Supabase Edge Function for generating product listings with OpenAI
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')
// Overridable so contract verification can point at a local stub
const OPENAI_BASE_URL = Deno.env.get('OPENAI_BASE_URL') ?? 'https://api.openai.com'
const OPENAI_ENDPOINT = OPENAI_BASE_URL + '/v1/chat/completions'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const systemPrompt = `You are an expert Shopify product copywriter. Generate compelling product listings that drive sales.

OUTPUT FORMAT (respond with valid JSON only):
{
  "title": "SEO-optimized title (max 70 characters)",
  "description": "Compelling product description (150-300 words with HTML formatting like <p>, <strong>, <ul><li>)",
  "bullets": ["Benefit 1", "Benefit 2", "Benefit 3", "Benefit 4", "Benefit 5"],
  "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
}

GUIDELINES:
- Title: Include main keyword, be specific and compelling
- Description: Address pain points, highlight benefits, include call-to-action
- Bullets: Start with action verbs, focus on benefits over features
- Tags: Include category, material, style, and trending search terms

Respond ONLY with the JSON object, no additional text.`

interface GenerateRequest {
  productName: string
  category: string
  keyFeatures?: string
  targetAudience?: string
  tone: string
  imageUrls?: string[]
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body: GenerateRequest = await req.json()
    const productName = body.productName
    const category = body.category
    const keyFeatures = body.keyFeatures
    const targetAudience = body.targetAudience
    const tone = body.tone

    if (!productName || !category) {
      return new Response(
        JSON.stringify({ error: 'Product name and category are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build user prompt
    const userPrompt = `Generate a Shopify product listing for:

Product Name: ` + productName + `
Category: ` + category + `
Key Features: ` + (keyFeatures || 'Not specified') + `
Target Audience: ` + (targetAudience || 'General consumers') + `
Tone: ` + tone + `

Please provide a complete product listing in JSON format.`

    // Call OpenAI API
    const openaiResponse = await fetch(OPENAI_ENDPOINT, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + OPENAI_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        max_tokens: 1500,
        temperature: 0.7,
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      console.error('OpenAI API error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to generate listing' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const data = await openaiResponse.json()
    const content = data.choices[0]?.message?.content

    if (!content) {
      return new Response(
        JSON.stringify({ error: 'No content generated' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse JSON from response
    const jsonMatch = content.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      return new Response(
        JSON.stringify({ error: 'Failed to parse generated content' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const listing = JSON.parse(jsonMatch[0])

    return new Response(
      JSON.stringify(listing),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
