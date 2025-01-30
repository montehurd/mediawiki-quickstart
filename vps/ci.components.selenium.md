
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
      ExecStart=/bin/bash -c 'while true; do git pull && ./ci.components.selenium | tee "/var/log/selenium-results/$(date +%%Y_%%m_%%d)-results.txt"; done'
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