# Multi-stage build for the React/Vite frontend.
# Stage 1 builds the static site (tsc typecheck + vite build, using .env.production).
# Stage 2 serves the prebuilt dist/ from stock nginx — parity with the current
# host-mounted /srv/site/frontend model, but as a portable, immutable OCI image.

FROM node:22-alpine AS build
WORKDIR /app

# Install deps first for better layer caching.
COPY package.json package-lock.json ./
RUN npm ci

# Build (npm run build runs `tsc --noEmit` then `vite build`; vite loads .env.production).
COPY . .
RUN npm run build

FROM nginx:alpine AS runtime
# Serve the built assets exactly where the host mount used to provide them.
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
# Mirror the compose-level healthcheck so the image is self-describing (K8s-probe ready).
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
