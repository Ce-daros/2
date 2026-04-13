systemctl status ssh --no-pager -l || systemctl status sshd --no-pager -l
journalctl -u ssh -n 200 --no-pager || journalctl -u sshd -n 200 --no-pager
ss -ltnp | grep -E ':22 |:2222 |:22022 |:13000 '
grep -E '^(MaxStartups|AllowTcpForwarding|GatewayPorts|PasswordAuthentication|PermitRootLogin)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null
systemctl status nginx --no-pager -l
curl -i http://127.0.0.1:13000/api/config