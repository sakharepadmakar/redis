#! /bin/bash 
#Update redis version as per your requirement
REDIS_VERSION="5.0.7"

#Data directory for redis 
mkdir /data



#Update reporsitory 
apt update -y 

#Set ulimit and file descriptors limit
cat <<-EOF >> /etc/sysctl.conf
fs.file-max = 2097152

# Do less swapping
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2

# Increase number of incoming connections
net.core.somaxconn = 40960

# Increase number of incoming connections backlog
net.core.netdev_max_backlog = 65536

# Decrease TIME_WAIT seconds
net.ipv4.tcp_fin_timeout = 30

# Recycle and Reuse TIME_WAIT sockets faster
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1

# Decrease the time default value for connections to keep alive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes 
EOF

cat <<-LimitEOF >> /etc/security/limits.conf
* soft nofile 999999
* hard nofile 999999
root soft nofile 999999
root hard nofile 999999
LimitEOF

cat <<-UserEOF >> /etc/systemd/user.conf
DefaultLimitNOFILE=650000
UserEOF

cat <<-SystemEOF >> /etc/systemd/system.conf
DefaultLimitNOFILE=650000
SystemEOF

#Adding Redis user
adduser --system --group --no-create-home redis

mkdir -p /opt/redis

chown -R ubuntu: /opt/redis

wget -P /opt/redis https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz

tar -xvf /opt/redis/redis-${REDIS_VERSION}.tar.gz  -C /opt/redis/

cd /opt/redis/redis-${REDIS_VERSION}/

apt install -y build-essential tcl

#Compile the redis binaries
make


#Install the binary
make install

#Create essentials 
mkdir -p /data/redis &&  touch /data/redis/appendonly.aof && chown -R redis:redis /data/redis &&  chmod -R 770 /data/redis &&  mkdir -p /etc/redis &&  mkdir -p /var/log/redis/ &&  touch /var/log/redis/redis-server.log &&  chown redis.redis /var/log/redis/redis-server.log &&  mkdir -p /var/run/redis/ &&  chown redis.redis /var/run/redis/

#Download redis systemd file 
wget -O /etc/systemd/system/redis.service https://github.com/sakharepadmakar/redis/blob/master/redis.service?raw=true

#Download redis conf file
wget -O /etc/redis/redis.conf https://github.com/sakharepadmakar/redis/blob/master/redis.conf?raw=true

#Auto start redis service on reboot
systemctl enable redis.service

systemctl start redis.service
systemctl status redis.service

reboot 
#verify the redis connection
#redis-cli
