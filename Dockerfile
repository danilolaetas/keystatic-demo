# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files and npm config
COPY package*.json ./
COPY .npmrc ./

# Accept artifactory token as build arg for pulling @calponia packages
ARG ARTIFACTORY_TOKEN
ENV ARTIFACTORY_TOKEN=$ARTIFACTORY_TOKEN

# Install all dependencies (including theme from artifactory)
RUN npm ci --legacy-peer-deps

# Copy source files
COPY . .

# Accept site URL as build arg - MUST be set for OAuth to work
ARG SITE_URL
ENV SITE_URL=${SITE_URL}

# Verify SITE_URL is set and build application
RUN echo "Building with SITE_URL: ${SITE_URL}" && \
    if [ -z "$SITE_URL" ]; then echo "ERROR: SITE_URL not set!" && exit 1; fi && \
    npm run build

# Production stage
FROM node:22-alpine AS runtime

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/docs/output ./docs/output

ENV HOST=0.0.0.0
ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

CMD ["node", "dist/server/entry.mjs"]
