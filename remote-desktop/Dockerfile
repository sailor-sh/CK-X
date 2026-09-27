# Headless XFCE desktop on Ubuntu 24.04 LTS, served over TigerVNC + noVNC.
#
# This used to build on nishanb/ck-x-simulator-vnc-base:v3, an Ubuntu 16.04
# image published for amd64 only. The VNC stack now lives here, so the image
# tracks a supported Ubuntu and builds natively on amd64 and arm64.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

ENV HOME=/headless \
    DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    VNC_RESOLUTION=1280x800 \
    VNC_COL_DEPTH=24 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Desktop session, VNC stack and the tools the exam desktop hands the candidate.
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    locales \
    openssh-client \
    telnet \
    nano \
    vim \
    xclip \
    python3 \
    python3-websockify \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    xauth \
    x11-xkb-utils \
    x11-xserver-utils \
    xfonts-base \
    xdg-utils \
    dbus-x11 \
    at-spi2-core \
    libgl1-mesa-dri \
    xfce4 \
    xfce4-terminal \
    thunar \
    elementary-xfce-icon-theme \
    adwaita-icon-theme \
    fonts-dejavu-core \
    fonts-liberation \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# agent.py (and anything else reaching for the classic names) expects the
# upstream binaries; Debian ships them prefixed.
RUN ln -sf /usr/bin/tigervncserver /usr/local/bin/vncserver \
 && ln -sf /usr/bin/tigervncpasswd /usr/local/bin/vncpasswd \
 && ln -sf /usr/bin/Xtigervnc /usr/local/bin/Xvnc

# Firefox from Mozilla's own repository: the Ubuntu package is a snap stub,
# which cannot run in a container.
RUN install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
      -o /etc/apt/keyrings/packages.mozilla.org.asc \
 && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
      > /etc/apt/sources.list.d/mozilla.list \
 && printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
      > /etc/apt/preferences.d/mozilla \
 && apt-get update && apt-get install -y --no-install-recommends firefox \
 && rm -rf /var/lib/apt/lists/*

# Enterprise policy: no first run onboarding, no telemetry prompt, and the
# allowed resources page as the home page. A candidate should land on the docs
# they are permitted to use, not on a "Welcome to Firefox" wizard.
COPY config/firefox-policies.json /etc/firefox/policies/policies.json

# noVNC: the web client websockify serves on 6901.
ENV NOVNC_VERSION=1.7.0
RUN curl -fsSL -o /tmp/novnc.tar.gz \
      "https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz" \
 && mkdir -p /usr/share/novnc \
 && tar -xzf /tmp/novnc.tar.gz -C /usr/share/novnc --strip-components=1 \
 && ln -sf vnc.html /usr/share/novnc/index.html \
 && rm -f /tmp/novnc.tar.gz

# VSCodium. The .deb pulls its own Electron dependencies, and is published for
# both architectures this image builds for.
ENV VSCODIUM_VERSION=1.135.06055
RUN arch="${TARGETARCH:-amd64}" \
 && curl -fsSL -o /tmp/codium.deb \
      "https://github.com/VSCodium/vscodium/releases/download/${VSCODIUM_VERSION}/codium_${VSCODIUM_VERSION}_${arch}.deb" \
 && apt-get update && apt-get install -y --no-install-recommends /tmp/codium.deb \
 && rm -f /tmp/codium.deb \
 && rm -rf /var/lib/apt/lists/*

# The desktop session runs as root out of /headless, the layout the previous
# base image set up and that the panel and VSCodium config below rely on.
RUN mkdir -p /headless/Desktop /headless/.vnc /dockerstartup \
 && cp /etc/skel/.bashrc /etc/skel/.profile /headless/ \
 && sed -i 's|^root:\(.*\):/root:|root:\1:/headless:|' /etc/passwd

# create candidate user
RUN useradd -m candidate

# set hostname as terminal
RUN echo "export HOSTNAME=terminal" >> /headless/.bashrc
# set terminal to bash
RUN echo "export TERM=xterm" >> /headless/.bashrc

# when shell opens, switch to candidate user
RUN echo "cd /home/candidate && su candidate" >> /headless/.bashrc

# disable asking for ssh host verification
RUN mkdir -p /home/candidate/.ssh \
 && echo "StrictHostKeyChecking no" >> /home/candidate/.ssh/config \
 && echo "UserKnownHostsFile /dev/null" >> /home/candidate/.ssh/config

# launcher wrapper, application entry and desktop shortcut. The packaged
# codium.desktop is replaced because it starts Electron without --no-sandbox,
# which a root session cannot do.
COPY config/codium-wrapper.sh /usr/local/bin/codium
COPY config/vscodium.desktop /usr/share/applications/codium.desktop
COPY config/vscodium.desktop /headless/Desktop/VSCodium.desktop
RUN chmod +x /usr/local/bin/codium /headless/Desktop/VSCodium.desktop \
 && ln -sf /usr/local/bin/codium /usr/local/bin/code

# default VSCodium settings for the desktop session user and for candidate
COPY config/vscodium-settings.json /headless/.vscodium-data/User/settings.json
COPY config/vscodium-settings.json /home/candidate/.vscodium-data/User/settings.json
RUN chown -R candidate:candidate /home/candidate/.vscodium-data

# panel docked to the top of the screen, with window buttons (task switcher),
# plus a dock at the bottom
COPY config/xfce4-panel.xml /headless/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
COPY config/helpers.rc /headless/.config/xfce4/helpers.rc
COPY config/launcher-8/thunar.desktop /headless/.config/xfce4/panel/launcher-8/thunar.desktop
COPY config/launcher-9/terminal.desktop /headless/.config/xfce4/panel/launcher-9/terminal.desktop
COPY config/launcher-10/firefox.desktop /headless/.config/xfce4/panel/launcher-10/firefox.desktop
COPY config/launcher-11/vscodium.desktop /headless/.config/xfce4/panel/launcher-11/vscodium.desktop

# VNC session entry point
COPY config/xstartup /headless/.vnc/xstartup
COPY vnc_startup.sh /dockerstartup/vnc_startup.sh
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /headless/.vnc/xstartup /dockerstartup/vnc_startup.sh /usr/local/bin/startup.sh

COPY agent.py /tmp/agent.py

EXPOSE 5901 6901 5000

WORKDIR /headless
ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
