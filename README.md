# Common to all installations

Assuming you use the latest Debian version.

- Create a `.env.secrets` file at the project root based on `.env.secrets.example` containing actual secrets
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
- Limit the journalctl log size (it can take several GB after months) by editing `/etc/systemd/journald.conf` and set:

  ```
  [Journal]
  SystemMaxUse=250M
  ```
  then restart it with `systemctl restart systemd-journald`
- For Debian >= 12: `apt install rsyslog`, otherwise Fail2ban cannot access auth.log. See https://unix.stackexchange.com/a/636689
  > FIXME: Make Fail2ban work with the host journalctl.
