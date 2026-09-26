#!/bin/bash
# Boots the headless XFCE session: TigerVNC on :1 and noVNC/websockify on 6901.
set -e

VNC_DISPLAY="${VNC_DISPLAY:-:1}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1280x800}"
VNC_COL_DEPTH="${VNC_COL_DEPTH:-24}"
VNC_PW="${VNC_PW:-${VNC_PASSWORD:-vncpassword}}"

mkdir -p "$HOME/.vnc"

# Password file. vncpasswd -f reads the full password from the first line and
# an optional view only password from the second, so view only mode hands out
# VNC_PW as the read only one and keeps the full password to itself.
if [ "${VNC_VIEW_ONLY}" = "true" ]; then
  echo "Starting VNC server in VIEW ONLY mode"
  printf '%s\n%s\n' "$(head -c 32 /dev/urandom | base64 | cut -c1-8)" "$VNC_PW" \
    | vncpasswd -f > "$HOME/.vnc/passwd"
else
  printf '%s\n' "$VNC_PW" | vncpasswd -f > "$HOME/.vnc/passwd"
fi
chmod 600 "$HOME/.vnc/passwd"

# tigervncserver reads ~/.vnc/config (key=value; anything it does not know
# becomes an Xtigervnc argument) and ~/.vnc/xstartup. Writing it on every boot
# keeps the session agent's `vncserver :1` restart on the same settings.
{
  echo "geometry=${VNC_RESOLUTION}"
  echo "depth=${VNC_COL_DEPTH}"
  echo "localhost=no"
  echo "SecurityTypes=VncAuth"
  echo "AlwaysShared=1"
  echo "desktopName=CK-X Remote Desktop"
} > "$HOME/.vnc/config"

# The system bus is not running in a fresh container; Thunar and friends want it.
mkdir -p /run/dbus
if [ ! -S /run/dbus/system_bus_socket ]; then
  dbus-daemon --system --fork
fi

# Drop anything a previous run left behind before claiming the display.
vncserver -kill "$VNC_DISPLAY" > /dev/null 2>&1 || true
rm -f "/tmp/.X${VNC_DISPLAY#:}-lock" "/tmp/.X11-unix/X${VNC_DISPLAY#:}"

vncserver "$VNC_DISPLAY"

/usr/local/bin/startup.sh

# Surface the session log in `docker logs`.
tail -F "$HOME"/.vnc/*"${VNC_DISPLAY}".log 2>/dev/null &

# noVNC in the foreground, so the container dies with the port the webapp proxies.
exec websockify \
  --web /usr/share/novnc \
  --heartbeat 30 \
  "${NO_VNC_PORT:-6901}" \
  "localhost:${VNC_PORT:-5901}"
