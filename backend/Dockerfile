FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .

FROM node:20-alpine
WORKDIR /app
RUN apk add --no-cache ffmpeg python3 py3-pip
RUN pip3 install yt-dlp
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app . .

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]