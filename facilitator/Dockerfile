FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies and SSH client for connecting to jumphost
RUN apk add --no-cache openssh-client

# Install dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
COPY package*.json ./

# Install dependencies
RUN npm install

# Bundle app source
COPY . .

# Create logs directory
RUN mkdir -p logs

# Create a non-root user and switch to it
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 -G nodejs

# Setup SSH for passwordless authentication
RUN mkdir -p /home/nodeuser/.ssh && \
    chmod 700 /home/nodeuser/.ssh && \
    echo "Host jumphost\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null" > /home/nodeuser/.ssh/config && \
    chmod 600 /home/nodeuser/.ssh/config && \
    chown -R nodeuser:nodejs /home/nodeuser/.ssh

# Change ownership of the app files to the non-root user
RUN chown -R nodeuser:nodejs /usr/src/app

# Expose the service port
EXPOSE 3000

# Copy entrypoint.sh to /usr/src/app
COPY entrypoint.sh /home/nodeuser/entrypoint.sh

# Make entrypoint.sh executable
RUN chmod +x /home/nodeuser/entrypoint.sh

# Switch to non-root user
USER nodeuser

ENTRYPOINT ["/bin/sh", "/home/nodeuser/entrypoint.sh"]