# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source code
COPY index.html vite.config.ts tsconfig.json tsconfig.node.json ./
COPY src ./src
COPY public ./public

# Build Vue app
RUN npm run build

# Runtime stage - Use lightweight HTTP server
FROM node:20-alpine

WORKDIR /app

# Install a lightweight HTTP server
RUN npm install -g serve

# Copy built application from builder
COPY --from=builder /app/dist ./dist

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000 || exit 1

# Expose port
EXPOSE 3000

# Start the application
CMD ["serve", "-s", "dist", "-l", "3000"]
