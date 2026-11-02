# ---------- Этап 1: сборка ----------
FROM node:22-alpine AS build
WORKDIR /app

# Сначала только package*.json: слой с зависимостями кешируется,
# пока они не меняются
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build && npm prune --omit=dev

# ---------- Этап 2: итоговый образ ----------
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

# Не запускаем приложение от root
USER node

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/main"]
