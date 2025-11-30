# Use a minimal Alpine Linux base image
FROM alpine:latest

# Install OpenSSH server
RUN apk add --no-cache openssh openrc curl

# Create candidate user and set password
RUN adduser -D candidate && echo "candidate:password" | chpasswd

# Configure SSH for password authentication
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config

# Copy the MOTD file
COPY motd /etc/motd

# Generate SSH host keys (necessary for SSH to work)
RUN ssh-keygen -A

# Install kubectl (detect architecture)
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
 && KVER=$(curl -L -s https://dl.k8s.io/release/stable.txt) \
 && curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl" \
 && install -m 0755 kubectl /usr/local/bin/kubectl \
 && rm -f kubectl

# Expose SSH port
EXPOSE 22

# Start SSH daemon when the container runs
CMD ["/usr/sbin/sshd", "-D"]
