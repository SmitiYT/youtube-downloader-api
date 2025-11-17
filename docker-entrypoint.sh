#!/usr/bin/env sh
set -e

# Ensure required directories exist
mkdir -p /app/tasks /app/downloads /var/log/supervisor /var/run/supervisor

# Fix ownership for mounted volumes (only if running as root)
if [ "$(id -u)" = "0" ]; then
  # Use find to skip files we can't chown/chmod (e.g., bind mounts with strict perms)
  find /app/tasks /app/downloads -type d -exec chown app:app {} + 2>/dev/null || true
  find /app/tasks /app/downloads -type f -exec chown app:app {} + 2>/dev/null || true
  find /app/tasks /app/downloads -type d -exec chmod u+rwx,g+rwx {} + 2>/dev/null || true
  find /app/tasks /app/downloads -type f -exec chmod u+rw,g+rw {} + 2>/dev/null || true
  chown -R app:app /var/log/supervisor /var/run/supervisor 2>/dev/null || true
fi

# Start supervisord as root; programs drop to user=app per config
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
