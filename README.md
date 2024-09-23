# Common to all installations

Assuming you use the latest Debian version.

- Install Docker
- Add this in a new `/etc/docker/daemon.json` file, otherwise users with an IPv6
  will not get their IP forwarded to Django, due to a Docker limitation:

  ```json
  {
    "ip6tables": true,
    "experimental": true
  }
  ```
- Restart Docker with `systemctl restart docker`
- Limit the journalctl log size (it can take several GB after months) by editing `/etc/systemd/journalctl.conf` and set:
  
  ```
  [Journal]
  SystemMaxUse=250M
  ```
  then restart it with `systemctl restart systemd-journald`
- `touch /var/log/auth.log` (otherwise Fail2ban will crash in a loop)
