#!/bin/bash
set -e

# Lancer Samba en arrière-plan (récupérer l'entrypoint original)
/usr/local/samba/sbin/samba --foreground --no-process-group &
SAMBA_PID=$!

# Attendre que le port LDAP loopback soit actif
echo "Waiting for Samba LDAP to be ready..."
for i in $(seq 1 30); do
  if ss -tlnp | grep -q "127.0.0.1:389"; then
    echo "Samba LDAP ready, applying iptables rules..."
    break
  fi
  sleep 2
done

# Activer le routage loopback + rediriger le port 389
sysctl -w net.ipv4.conf.all.route_localnet=1
iptables -t nat -F PREROUTING
iptables -t nat -A PREROUTING -p tcp --dport 389 \
  -j DNAT --to-destination 127.0.0.1:389

echo "iptables DNAT rule applied. LDAP accessible on all interfaces."

# Garder le conteneur vivant
wait $SAMBA_PID