# -------- Build stage --------
# Node >= 22.22 is required by react-router 8 / Vite 8.
FROM node:24-alpine AS build

WORKDIR /app

# Enable pnpm via corepack
RUN corepack enable

# Copy only lockfile + package.json first (better caching)
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Microsoft Clarity project id, inlined by Vite (empty = Clarity disabled).
ARG VITE_CLARITY_PROJECT_ID=""
ENV VITE_CLARITY_PROJECT_ID=${VITE_CLARITY_PROJECT_ID}

# Copy source and build
COPY . .
RUN pnpm build


# -------- Production stage --------
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
