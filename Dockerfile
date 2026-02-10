# Development Dockerfile for Medusa
FROM node:20-alpine

# Set working directory
WORKDIR /server

COPY package.json yarn.lock ./
COPY .yarn .yarn
COPY .yarnrc.yml ./

RUN corepack enable
RUN yarn install

# Copy source code
COPY . .

# Expose the port Medusa runs on
EXPOSE 9000 5173

# Start with migrations and then the development server
ENTRYPOINT ["./start.sh"]