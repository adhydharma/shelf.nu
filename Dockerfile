# --- Stage 1: Build Stage ---
FROM node:22-alpine AS builder

# Install pnpm globally
RUN npm install -g pnpm

WORKDIR /app

# Copy workspace and lock files first for caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./

# Copy necessary monorepo directories (including patches!)
COPY patches/ ./patches/
COPY apps/ ./apps/
COPY packages/ ./packages/

# Install all dependencies using pnpm
RUN pnpm install --frozen-lockfile

# Build the webapp
RUN pnpm webapp:build

# --- Stage 2: Production Runtime Stage ---
FROM node:22-alpine AS runner

RUN npm install -g pnpm

WORKDIR /app

ENV NODE_ENV=production

# Copy built artifacts and dependencies from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/webapp ./apps/webapp
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

# Start the application
CMD ["pnpm", "--filter", "webapp", "start"]