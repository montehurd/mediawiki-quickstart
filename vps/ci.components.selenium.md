
```
#cloud-config
runcmd:
  - git clone https://gitlab.wikimedia.org/mhurd/vps-provisioning.git
  - cd vps-provisioning
  - ./docker.sh install
  - ./user.sh create "quickstart" "quickstart"
  - mkdir -p /var/log/selenium-results
  - chown -R quickstart:quickstart /var/log/selenium-results
  - su quickstart -c "git clone https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart.git /home/quickstart/mediawiki-quickstart"
  - chmod +x /home/quickstart/mediawiki-quickstart/ci.components.selenium
  - systemctl daemon-reload
  - systemctl enable selenium-test
  - systemctl start selenium-test
  - systemctl enable results-server
  - systemctl start results-server

write_files:
  - path: /etc/systemd/system/selenium-test.service
    content: |
      [Unit]
      Description=Continuous Selenium Test Runner
      After=network.target

      [Service]
      Type=simple
      User=quickstart
      WorkingDirectory=/home/quickstart/mediawiki-quickstart
      Environment="SILENT=1"
      Environment="RECLONE_REPOS=1"
      Environment="OUTPUT_PATH=/var/log/selenium-results"
      ExecStart=/bin/bash -c 'while true; do if ! git pull; then if df -h . | awk "NR==2 {print \$5}" | sed "s/%//" | awk "\$1 > 95"; then docker system prune -af && git pull; fi; fi && ./ci.components.selenium; done'
      Restart=always

      [Install]
      WantedBy=multi-user.target

  - path: /etc/systemd/system/results-server.service
    content: |
      [Unit]
      Description=Simple HTTP Server for Selenium Results
      After=network.target

      [Service]
      Type=simple
      User=quickstart
      WorkingDirectory=/var/log/selenium-results
      ExecStart=/usr/bin/python3 -m http.server 8088
      Restart=always

      [Install]
      WantedBy=multi-user.target
```