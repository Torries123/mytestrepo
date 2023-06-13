# Stage 1 - Build the application

FROM node:16-alpine AS builder
# Set base image as node:16.19-alpine

ENV NODE_ENV uat
ENV PORT 3001
WORKDIR /app
# Set the build environment as a folder called /app in the docker container to prevent clashes

COPY package*.json ./
# Copy package.json and package-lock.json to /app

RUN npm install

COPY . .

RUN npm run build

# Stage 2 - Run the application
FROM node:16-alpine AS runner

ENV NODE_ENV uat
ENV PORT 3001

WORKDIR /app

COPY --from=builder /app/package*.json ./

RUN npm install

COPY --from=builder /app/dist ./dist

CMD ["npm", "start"]
