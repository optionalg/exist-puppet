On Ubuntu Vivid (or newer) using Systemd, there is an issue with starting eXist. You need to edit /etc/systemd/system/eXist-db.service and add:

User=exist

Under the [Service] section. Then run `sudo systemctl daemon-reload`, then `sudo systemctl start eXist-db`
