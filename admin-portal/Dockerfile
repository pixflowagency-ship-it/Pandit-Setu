# ==============================================================================
# SARV MANGAL Dedicated Admin Web Portal — Multi-Stage Dockerfile
# ==============================================================================

FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json vite.config.ts index.html ./
COPY src/ ./src/

ARG VITE_API_URL=http://localhost:5000/api/v1
ENV VITE_API_URL=${VITE_API_URL}

RUN npm run build

FROM nginx:alpine AS runner

COPY --from=builder /app/dist /usr/share/nginx/html

RUN printf 'server {\n    listen 80;\n    server_name localhost;\n    root /usr/share/nginx/html;\n    index index.html;\n    add_header X-Frame-Options "DENY";\n    add_header X-Content-Type-Options "nosniff";\n    add_header Referrer-Policy "strict-origin-when-cross-origin";\n    location / {\n        try_files $uri $uri/ /index.html;\n    }\n}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
