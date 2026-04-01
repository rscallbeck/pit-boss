# ==========================================
# STAGE 1: Prune the Monorepo
# ==========================================
FROM node:20-slim AS pruner
WORKDIR /usr/src/app

#
RUN npm -g add turbo@^2
COPY . .
# Add lockfile and package.json's of isolated subworkspace
# Generate a partial monorepo with a pruned lockfile for a target workspace.
# Assuming "web" is the name entered in the project's package.json: { name: "web" }

# Install turbo globally to extract the specific workspace
RUN npm install -g turbo

RUN turbo prune web --docker

COPY . .

# Isolate the exact packages and files needed for casino-web
RUN turbo prune web --docker

# ==========================================
# STAGE 2: Install & Build
# ==========================================
FROM node:20-slim AS builder
WORKDIR /usr/src/app

# First, only copy the isolated package.json files to cache the install step
COPY --from=pruner /usr/src/app/out/json/ .
COPY --from=pruner /usr/src/app/out/package-lock.json ./package-lock.json

# RUN npm ci
# CMD ["npm", "ci"]

# Now copy the actual isolated source code
COPY --from=pruner /usr/src/app/out/full/ .

# Inject the environment variables for Next.js static generation
# COPY .env apps/casino-web/.env

# COPY .env apps/casino-web/.env
# ARG NEXT_PUBLIC_SUPABASE_URL
# ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
# ARG NEXT_PUBLIC_SERVER_URL
# ARG NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID
# ARG NEXT_PUBLIC_CONTRACT_ADDRESS
# ARG NEXT_PUBLIC_RPC_URL
# ARG NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY
# ARG NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY

# ENV NEXT_PUBLIC_SUPABASE_URL=https://wvrzyxkjxyzzccmqiprz.supabase.co
# ENV NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_PivOI-BiCaLweKwOEhaqnw_Ko5vh2jO
# ENV NEXT_PUBLIC_SERVER_URL=https://192.168.49.2:30001
# ENV NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=f1d42de36341d8e2f6c3d951cb3ee55d
# ENV NEXT_PUBLIC_CONTRACT_ADDRESS=0x9926bFb634C86D0d102E14C1D68Bb6B5393e3723
# ENV NEXT_PUBLIC_RPC_URL=https://base-sepolia.infura.io/v3/228e978f498c4f6087aeddff058b263d
# ENV NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cnp5eGtqeHl6emNjbXFpcHJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTMxODQzMywiZXhwIjoyMDg2ODk0NDMzfQ.sXeu0njkcnFkZ5d7Vai3PuelX3AVIvq5_HVdEjwGEOo
# ENV NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_PivOI-BiCaLweKwOEhaqnw_Ko5vh2jO

# Explicitly run the turbo build targeting only the web app
# RUN npx turbo run build --filter=web
CMD ["npx", "turbo", "run", "build", "--filter=web"]

# ==========================================
# STAGE 3: Run the Production Server
# ==========================================
FROM node:20-slim AS runner
WORKDIR /usr/src/app

ENV NODE_ENV=production

# Security: Run as non-root user
RUN groupadd -r aegisgroup && useradd -r -g aegisgroup aegisuser

COPY --from=builder --chown=aegisuser:aegisgroup /usr/src/app/apps/web/.next/standalone ./
COPY --from=builder --chown=aegisuser:aegisgroup /usr/src/app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=aegisuser:aegisgroup /usr/src/app/apps/web/public ./apps/casino-web/public

USER aegisuser

EXPOSE 3000

# Next.js standalone mode in a monorepo mirrors the folder structure
# CMD ["node", "apps/casino-web/server.js"]
CMD ["node", "apps/web/server.js"]
