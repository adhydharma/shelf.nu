# --- Stage 1: Build Stage ---
FROM node:22-alpine AS builder

# Install pnpm globally
RUN npm install -g pnpm

WORKDIR /app

# Copy the entire monorepo workspace
COPY . .

# Install all dependencies with pnpm
RUN pnpm install --frozen-lockfile

# Build the webapp via Turborepo
RUN pnpm webapp:build

# --- Stage 2: Production Runtime Stage ---
FROM node:22-alpine AS runner

RUN npm install -g pnpm

WORKDIR /app

ENV NODE_ENV=production

# Copy necessary build outputs, packages, and node_modules from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/webapp ./apps/webapp
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/pnpm-workspace.yaml ./pnpm-workspace.yaml

EXPOSE 3000

# Start the application
CMD ["pnpm", "--filter", "webapp", "start"]