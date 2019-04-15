#!/bin/bash


rm -rf /root/edx.configuration
git clone https://github.com/entuze/edx.configuration.git

sudo cp /root/edx.configuration/edx/app/edxapp/*.json /edx/app/edxapp/
sudo chown edxapp /edx/app/edxapp/*.json
sudo chgrp www-data /edx/app/edxapp/*.json

# Copy our modified nginx configurations for lms and cms
# these contain lets encrypt ssl certificate and https redirection
cp /root/edx.configuration/edx/app/nginx/sites-available/lms /edx/app/nginx/sites-available/
cp /root/edx.configuration/edx/app/nginx/sites-available/cms /edx/app/nginx/sites-available/

# copy server-vars and any other mods to ansible-related work flows
cp /root/edx.configuration/edx/app/edx_ansible/*.* /edx/app/edx_ansible/

sudo service nginx restart
