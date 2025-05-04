FROM docker:dind

# Accept build-time architecture argument
ARG TARGETARCH

#install curl
RUN apk add --no-cache curl
# use our own to start kind cluster
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# persist existing entrypoint
RUN cp /usr/local/bin/dockerd-entrypoint.sh /usr/local/bin/startup.sh

#copy scripts
COPY scripts/ /usr/local/bin/

#make scripts executable
RUN chmod +x /usr/local/bin/env-setup
RUN chmod +x /usr/local/bin/env-cleanup
RUN chmod +x /usr/local/bin/k3d-install.sh

ENV KIND_DEFAULT_VERSION=v1.32.3

RUN apk add --no-cache openssh-server
RUN apk add bash 
RUN apk add openssh-server-pam

RUN ssh-keygen -A

# allow root ssh login without password 
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication no/' /etc/ssh/sshd_config
RUN sed -i 's/^#UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# create a non-login user for ssh access
RUN adduser -D -s /bin/bash candidate
RUN passwd -d candidate

# #set not password for candidate user
RUN echo "candidate::0:0:candidate:/home/candidate:/bin/bash" > /etc/passwd
RUN echo "candidate:x:1000:1000:candidate:/home/candidate:/bin/bash" >> /etc/passwd

# create a home directory for the candidate user
RUN mkdir -p /home/candidate
RUN chown -R candidate: /home/candidate

EXPOSE 6443
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]