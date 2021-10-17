#!/bin/bash

hostnamectl set-hostname ${PGNAME}-db-helper
yum install htop amazon-efs-utils -y
amazon-linux-extras install postgresql13 -y

# https://github.com/aws/amazon-ssm-agent/issues/131
echo 'DefaultEnvironment="ENV=/etc/profile"' >>  /etc/systemd/system.conf

cat << EOF >> /etc/profile
if [ -r ~/.profile ]; then
	. ~/.profile
fi
EOF

# some sleep to wait until ssm-user provisioned
until [ -d /home/ssm-user ]
do
     sleep 5
done

cat << EOF > /home/ssm-user/.profile
if [ "\$${0}" = "sh" ]; then
  cd
  export PGPASSWORD=${PGPASSWORD}
  export PGUSER=${PGUSER}
  export PGHOST=${PGHOST}
  export PGDATABASE=${PGDATABASE}
  export PGSSLMODE=${PGSSLMODE}
	exec bash
fi
EOF

chown ssm-user: /home/ssm-user/.profile

# shutdown instance if no open sessions for the last 5 minutes
cat << EOF > /home/ssm-user/idle-sessions-shutdown.sh
#!/bin/bash

SESSIONS_NUMBER=\$(ps aux|grep ssm-session-worker|grep -v grep|wc -l)

if [ \$SESSIONS_NUMBER -eq 0 ]; then
  /sbin/poweroff
fi
EOF

cat << EOF > /var/spool/cron/root
*/5 * * * * /home/ssm-user/idle-sessions-shutdown.sh
EOF

chmod +x /home/ssm-user/idle-sessions-shutdown.sh

reboot
