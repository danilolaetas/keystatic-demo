import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware(async (context, next) => {
  // Skip middleware for OAuth callback - it doesn't need URL rewriting
  // and might be causing the 500 error
  if (context.request.url.includes("/oauth/callback")) {
    return next();
  }

  // Fix Keystatic OAuth redirect_uri issue behind reverse proxies
  // Keystatic doesn't read x-forwarded-* headers, so we rewrite the URL
  
  const forwardedHost = context.request.headers.get("x-forwarded-host");
  const forwardedProto = context.request.headers.get("x-forwarded-proto");
  const siteUrl = process.env.SITE_URL;

  let targetHost: string | null = null;
  let targetProto: string | null = null;

  // Priority: x-forwarded headers > SITE_URL env var
  if (forwardedHost && forwardedProto) {
    targetHost = forwardedHost;
    targetProto = forwardedProto;
  } else if (siteUrl) {
    try {
      const siteUrlParsed = new URL(siteUrl);
      targetHost = siteUrlParsed.hostname;
      targetProto = siteUrlParsed.protocol.replace(":", "");
    } catch (e) {
      // Invalid SITE_URL, skip rewriting
    }
  }

  if (targetHost && targetProto) {
    const newUrl = new URL(context.request.url);
    newUrl.hostname = targetHost;
    newUrl.port = ""; // Clear port for standard https (443)
    newUrl.protocol = targetProto + ":";
    
    // Create a new request with the corrected URL (handle GET vs POST differently)
    const requestInit: RequestInit = {
      method: context.request.method,
      headers: context.request.headers,
    };
    
    // Only include body for non-GET/HEAD requests
    if (context.request.method !== "GET" && context.request.method !== "HEAD") {
      requestInit.body = context.request.body;
      (requestInit as any).duplex = "half";
    }
    
    const newRequest = new Request(newUrl.toString(), requestInit);

    // Replace the request in context
    Object.defineProperty(context, "request", {
      value: newRequest,
      writable: false,
    });
  }

  return next();
});
