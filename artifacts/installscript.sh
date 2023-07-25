#!/bin/bash
exec >installscript.log
exec 2>&1

sudo apt-get update

# Injecting environment variables
echo '#!/bin/bash' >> vars.sh
echo $templateBaseUrl:${10} | awk '{print substr($1,2); }' >> vars.sh

sed -i '2s/^/export templateBaseUrl=/' vars.sh

chmod +x vars.sh
. ./vars.sh

# Creating login message of the day (motd)
sudo curl -v -o /etc/profile.d/welcome.sh ${templateBaseUrl}artifacts/welcome.sh

# Installing Azure CLI & Azure Arc extensions
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

sudo service sshd restart
