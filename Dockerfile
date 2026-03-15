# =============================================================================
# Vue.js Documentation - Fully Offline Docker Build
# Multi-stage: build with Node.js, serve with nginx
# =============================================================================

# --------------- Stage 1: Build ---------------
FROM node:20-alpine AS builder

RUN apk add --no-cache curl bash

RUN corepack enable && corepack prepare pnpm@10.28.2 --activate

WORKDIR /app

# Copy dependency files first for better layer caching
COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

# Copy the rest of the project
COPY . .

# Run offline patching (download CDN libs, patch config)
RUN chmod +x docker/patch-offline.sh && bash docker/patch-offline.sh /app

# Build the static site
RUN pnpm run build

# --------------- Stage 2: Serve ---------------
FROM nginx:alpine AS server

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built site from builder
COPY --from=builder /app/.vitepress/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
