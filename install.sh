#!/bin/bash
regex='href="[^>]*>(docker\-[0-9]{1}[^<]*)';
target_url='https://download.docker.com/linux/static/stable/x86_64/';
result=$(curl $target_url);
files='';

if [ "$(id -u)" != "0" ]; then
    echo "You must be root! Try 'sudo ./<bash_file>'!";
    exit 1;
fi

echo "Uninstalling older versions"
apt remove docker docker-engine docker.io;
rm /usr/bin/docker*;
rm /etc/systemd/system/docker.service;

echo "Installing dependences"
apt install -y \
     apt-transport-https \
     curl \
     wget \
     gnupg2 \
     software-properties-common


# Get all available versions
for s in $result
do
    if [[ $s =~ $regex ]]
    then
        files="$files ${BASH_REMATCH[1]}";
    fi
done

# Finding latest version
sorted_files=$(echo $files | tr ' ' '\n' | sort -u);

for file in $sorted_files
do
    files+=($file);
done

# Get latest version
latest="${files[-1]}";
echo "Latest version is $latest";

# Download version
echo "Downloading last version"

wget $target_url$latest -O /opt/$latest;
tar xzvf /opt/$latest -C /opt

for docker_bin in $(ls /opt/docker)
do
  cp -f /opt/docker/$docker_bin /usr/bin/$docker_bin;
done

echo "Creating systemd file"
cp ./docker.service /etc/systemd/system/docker.service;
chmod 664 /etc/systemd/system/docker.service;
systemctl daemon-reload;
systemctl enable docker.service;
systemctl start docker.service;

echo "Deleting installation files"
rm -Rf /opt/docker;