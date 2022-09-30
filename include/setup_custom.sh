#!/bin/bash
# Steroid Installation
# Intro
dbpass=demo1
#wget -c http://mirrors.linuxeye.com/oneinstack-full.tar.gz && tar xzf oneinstack-full.tar.gz && ./oneinstack/install.sh --nginx_option 1 --php_option 8 --phpcache_option 1 --php_extensions ioncube,imagick,fileinfo,memcached,memcache --phpmyadmin  --db_option 2 --dbinstallmethod 1 --dbrootpwd $dbpass --pureftpd  --memcached  --iptables  --ssh_port 2211 --reboot
echo "Create Steroid Database"
DB="S4QL"
USER="steroid"
PASS="steroid"
mysql -u root -p${dbpass} -e "CREATE DATABASE $DB CHARACTER SET utf8 COLLATE utf8_general_ci";
mysql -u root -p${dbpass} -e "CREATE USER $USER@'%' IDENTIFIED BY '$PASS'";
mysql -u root -p${dbpass} -e "GRANT SELECT ON $DB.* TO '$USER'@'%'";
#CREATE USER 'steroid1'@'%' IDENTIFIED WITH mysql_native_password AS '***';GRANT SELECT ON *.* TO 'steroid1'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
echo "QUESTION: Enter your custom domain name (peer2.steroid.io): "
read vhosturl
echo "Generate vhost ."
sleep 0.5
echo "Generate vhost .."
sleep 0.5
echo "Generate vhost .."
sleep 0.5
sudo mkdir /usr/local/nginx/conf/vhost
sudo bash -c "echo 'server {
    listen 80;
    listen [::]:80;
    server_name ${vhosturl};
    access_log /data/wwwlogs/${vhosturl}_nginx.log combined;
    index index.html index.htm index.php;
    root /data/wwwroot/${vhosturl};
    #include /usr/local/nginx/conf/rewrite/other.conf;
    #error_page 404 /404.html;
    #error_page 502 /502.html;
    location ~ [^/]\.php(/|$) {
      #fastcgi_pass remote_php_ip:9000;
      fastcgi_pass unix:/dev/shm/php-cgi.sock;
      fastcgi_index index.php;
      include fastcgi.conf;
    }
    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
      expires 30d;
      access_log off;
    }
    location ~ .*\.(js|css)?$ {
      expires 7d;
      access_log off;
    }
    location ~ /(\.user\.ini|\.ht|\.git|\.svn|\.project|LICENSE|README\.md) {
      deny all;
    }
    location /.well-known {
      allow all;
    }
    include /data/wwwroot/${vhosturl}/nginx-rewrites.txt;
  }' > /usr/local/nginx/conf/vhost/${vhosturl}.conf"
  
  
echo "Vhost Created "
DIR="/data/wwwroot/${vhosturl}"
   if [ ! -d "$DIR" ]; then
       mkdir $DIR
       chown www:www  -R $DIR
       cd $DIR
        git clone https://github.com/BeepXtra/Steroid-Core4.0.git . -b testnet
echo "Setup Cron"
        sudo crontab -l > cron_bkp

sudo echo "0 10 * * * sudo /home/test.sh >/dev/null 2>&1" >> cron_bkp
sudo crontab cron_bkp
sudo rm cron_bkp

   fi

echo "Enable PHP shell_exec,exec"
filename="/usr/local/php/etc/php.ini"
$search='disable_functions'
$replace=':disable_functions'

sed -i "s/$search/$replace/" $filename
echo "disable_functions = passthru,chroot,chgrp,chown,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen" > $filename
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get install -y php7.3-gd
service php-fpm restart


echo "Check if  file bpc.log exist"
DIR="/var/log/bpc.log"
   if [ ! -f "$DIR" ]; then
       echo "" > /var/log/bpc.log
       chown www:www  /var/log/bpc.log
       echo "bpc.log file created"
     else
       echo "bpc.log file exist"
   fi

 
read -s -p "Please enter your wallet: " wallet
    
