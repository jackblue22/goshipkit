export type ApiClientOptions = {
  baseUrl: string;
  fetch?: typeof globalThis.fetch;
};

export function createApiClient({ baseUrl, fetch: customFetch = globalThis.fetch }: ApiClientOptions) {
  return {
    async health(): Promise<{ status: string }> {
      const response = await customFetch(`${baseUrl}/healthz`);
      if (!response.ok) throw new Error(`Health request failed: ${response.status}`);
      return response.json() as Promise<{ status: string }>;
    },
  };
}
