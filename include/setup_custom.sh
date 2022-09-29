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

   url="${vhosturl}/api"
   content=$(curl -s "$url" | grep -oP '"info"\s*:\s*"\K([^"]*)' )


    a=$content
    b="Basic API Information"
    while [[ -z "$check" ]]
    do
      content=$(curl -s "$url" | grep -oP '"info"\s*:\s*"\K([^"]*)' )


       a=$content
       b="Basic API Information"
      if [[ $a == $b ]]
       then
         check=0
          echo "Successfull"
       else
           check=''
          echo "Error"
    read -s -p "Check again (whait a little ): " check

       fi

    done
read -s -p "Please enter your wallet: " wallet
    DIR="/data/wwwroot/${vhosturl}/strdconfig.php"
       if [ ! -f "$DIR" ]; then
           echo "class strdconfig {

    //Database configuration
    public $db_hostname = 'localhost';
    public $db_username = 'root';
    public $db_password = '${dbpass}';
    public $strd_database = 'S4QL';
    public $debug = 1;
    public $root_folder = '';
    //The time a session should be left alive (In seconds)
    //This is for security reasons. Users will be automatically logged out after the specified seconds of inactivity
    public $session_timeout = '10800';
    //Time settings
    public $timezone = 'UTC';
    //Chain configuration
    public $premine = 500000000;
    // Maximum number of connected peers
    public $max_peers = 30;
    // Enable testnet mode for development
    public $testnet = false;
    // To avoid any problems if other clones are made
    public $coin = 'bpc';
    // Allow others to connect to the node api (if set to false, only the below 'allowed_hosts' are allowed)
    public $public_api = true;
    // Hosts that are allowed to mine on this node
    public $allowed_hosts = [
        '127.0.0.1',
        '139.162.179.250',
        '139.162.212.101',
        '172.104.134.29',
        '62.228.227.198',
        '*'
    ];
    // Disable transactions and block repropagation
    public $disable_repropagation = true;

    /*
      |--------------------------------------------------------------------------
      | Peer Configuration
      |--------------------------------------------------------------------------
     */
    // The number of peers to send each new transaction to
    public $transaction_propagation_peers = 1;
    // How many new peers to check from each peer
    public $max_test_peers = 1;
    // The initial peers to sync from in sanity
    public $initial_peer_list = [
        'https://peer1.steroid.io',
    ];
    // does not peer with any of the peers. Uses the seed peers and syncs only from those peers. Requires a cronjob on sanity.php
    public $passive_peering = false;

    /*
      |--------------------------------------------------------------------------
      | Mempool Configuration
      |--------------------------------------------------------------------------
     */
    // The maximum transactions to accept from a single peer
    public $peer_max_mempool = 100;
    // The maximum number of mempool transactions to be rebroadcasted
    public $max_mempool_rebroadcast = 5000;
    // The number of blocks between rebroadcasting transactions
    public $sanity_rebroadcast_height = 30;
    // Block accepting transfers from addresses blacklisted by the Steroid devs
    public $use_official_blacklist = false;

    /*
      |--------------------------------------------------------------------------
      | Sanity Configuration
      |--------------------------------------------------------------------------
     */
    // Recheck the last blocks on sanity
    public $sanity_recheck_blocks = 10;
    // The interval to run the sanity in seconds
    public $sanity_interval = 900;
    // Enable setting a new hostname (should be used only if you want to change the hostname)
    public $allow_hostname_change = false;
    public $hostname = false;
    // Rebroadcast local transactions when running sanity
    public $sanity_rebroadcast_locals = true;
    // Get more peers?
    public $get_more_peers = false;

    /*
      |--------------------------------------------------------------------------
      | Logging Configuration
      |--------------------------------------------------------------------------
     */
    // Enable log output to the specified file
    public $enable_logging = true;
    // Log verbosity (default 0, maximum 3)
    public $log_verbosity = 3;

    /*
      |--------------------------------------------------------------------------
      | Masternode Configuration
      |--------------------------------------------------------------------------
     */
    // Enable this node as a masternode
    public $masternode = true;
    public $maintenance = false;
    // The public key for the masternode
    public $masternode_public_key = '${wallet}';



    function __construct() {
        $this->root_folder = dirname(__FILE__);

        if(isset($_SERVER['HTTP_HOST'])){
            $servername = explode('.', $_SERVER['HTTP_HOST']);
        } else {
            $servername = 'localhost';
        }

        $this->debug_queries = $this->debug;

        // The specified file to write to (this should not be publicly visible)
        $this->log_file = '/var/log/'.$this->coin.'.log';
    }

    public function getTld() {
        //print_r($_SERVER);
        $tldsrc = strrchr($_SERVER['HTTP_HOST'], ".");
        $tld = substr($tldsrc, 1);
        return $tld;
    }

}
?>" > $DIR
           chown www:www  $DIR
           echo "strdconfig.php file created"
         else
           echo "strdconfig.php file exist"
       fi
