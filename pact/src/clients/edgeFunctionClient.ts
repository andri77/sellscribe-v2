// Mirrors AiService.generateListingViaEdgeFunction (lib/services/ai_service.dart):
// supabase_flutter's functions.invoke('generate-listing', body: {...}) puts this on the wire.

export interface GenerateListingRequest {
  productName: string;
  category: string;
  keyFeatures: string | null;
  targetAudience: string | null;
  tone: string;
  imageUrls: string[] | null;
}

export interface GeneratedListing {
  title: string;
  description: string;
  bullets: string[];
  tags: string[];
}

export interface EdgeFunctionResult<T> {
  status: number;
  data: T;
}

export class EdgeFunctionClient {
  constructor(
    private readonly baseUrl: string,
    private readonly anonKey: string,
    private readonly accessToken: string,
  ) {}

  async generateListing(
    body: GenerateListingRequest,
  ): Promise<EdgeFunctionResult<GeneratedListing | { error: string }>> {
    const res = await fetch(`${this.baseUrl}/functions/v1/generate-listing`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.accessToken}`,
        apikey: this.anonKey,
      },
      body: JSON.stringify(body),
    });
    return { status: res.status, data: await res.json() };
  }
}
