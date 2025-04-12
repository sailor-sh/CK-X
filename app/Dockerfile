FROM node:16-alpine

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the application files
COPY server.js ./
COPY services/ ./services/
COPY public/ ./public/

# Ensure the public directory exists
RUN mkdir -p /app/public

# Expose the port
EXPOSE 3000

# Start the application
CMD ["node", "server.js"] 