#!/bin/bash


sudo rm -rf /home/ubuntu/edx.configuration
git clone https://github.com/entuze/edx.configuration.git

# Install application configuration files
sudo cp /home/ubuntu/edx.configuration/edx/app/edxapp/*.json /edx/app/edxapp/
sudo chown edxapp /edx/app/edxapp/*.json
sudo chgrp www-data /edx/app/edxapp/*.json

# Copy our modified nginx configurations for lms and cms
# these contain lets encrypt ssl certificate and https redirection
sudo cp /home/ubuntu/edx.configuration/edx/app/nginx/sites-available/lms /edx/app/nginx/sites-available/
sudo cp /home/ubuntu/edx.configuration/edx/app/nginx/sites-available/cms /edx/app/nginx/sites-available/

# copy server-vars and any other mods to ansible-related work flows
sudo cp /home/ubuntu/edx.configuration/edx/app/edx_ansible/*.* /edx/app/edx_ansible/

# copy theme files into their run-time location
sudo rm -r /edx/app/edxapp/edx-platform/themes/entuze-theme
sudo cp -R /home/ubuntu/edx.configuration/themes/entuze-theme /edx/app/edxapp/edx-platform/themes/
sudo chown -R edxapp /home/ubuntu/edx.configuration/themes/
sudo chgrp -R edxapp /home/ubuntu/edx.configuration/themes/

sudo service nginx restart
