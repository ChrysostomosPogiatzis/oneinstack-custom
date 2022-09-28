#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear
ERROR_CHAR="  ⌦  ERROR->"

echo ""
echo -e "
███████╗████████╗███████╗██████╗  ██████╗ ██╗██████╗    ██╗  ██╗    ██████╗
██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗██║██╔══██╗   ██║  ██║   ██╔═████╗
███████╗   ██║   █████╗  ██████╔╝██║   ██║██║██║  ██║   ███████║   ██║██╔██║
╚════██║   ██║   ██╔══╝  ██╔══██╗██║   ██║██║██║  ██║   ╚════██║   ████╔╝██║
███████║   ██║   ███████╗██║  ██║╚██████╔╝██║██████╔╝        ██║██╗╚██████╔╝██╗
╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═════╝         ╚═╝╚═╝ ╚═════╝ ╚═╝
                                                                            "
sleep 1
echo "Steroid4.0 (BPC) masternode.Installation Script"
sleep 1
echo "This script will install & configure Nginx, Mysql and other required packages."
sleep 1
echo "It will configure a vhost in nginx, clone the Steroid4.0 (BPC) masternode  repo, and setup the database."
echo "Brought to you by Beepxtra "
echo ""
echo ""
# check RAM
checkRAM() {
    RAMTOTAL=$(free -m | awk '/^Mem:/{print $2}')
    DISK_A=$(df $PWD | awk '/[0-9]%/{print $(NF-2)}')
    CORETOTAL=$(grep 'cpu cores' /proc/cpuinfo | uniq)
}
checkRAM
if [[  $RAMTOTAL -lt 1800 ]]; then
    echo ""
    read -p "WARNING: Detected < 2GB RAM.  Continue? (yes|no): " USER_RAM_CONTINUE
    if ! [[ "$USER_RAM_CONTINUE" == "yes" ]]; then
        echo -e "$ERROR_CHAR You did not type 'yes'. Halting setup.\n"
        exitAsError


    fi
  else

      echo -e "Hardware Requirements:

2GB RAM
1 CPU Core
50GB DISK

"




echo -e "Ram Detected:${RAMTOTAL} mb "
echo -e "Cores Detected:${CORETOTAL}  "
echo -e "Disk Available:${DISK_A} mb "
fi
sleep 1
# Prompt user for domain name

echo  "Setup is starting  this will take some time depenting your system specs"
  echo "Checking SSH port"

if grep -Fxq "Port 2211" /etc/ssh/sshd_config
then
    echo "SSH Port is 2211"
else
  echo "Port 2211" >> /etc/ssh/sshd_config
  echo "SSH Port has change to 2211"
    # code if not found
fi

systemctl restart sshd
# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

oneinstack_dir=$(dirname "`readlink -f $0`")
pushd ${oneinstack_dir} > /dev/null
. ./versions.txt
. ./options.conf
. ./include/color.sh
. ./include/check_os.sh
. ./include/check_dir.sh
. ./include/download.sh
. ./include/get_char.sh

dbrootpwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
dbpostgrespwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
dbmongopwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
xcachepwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
dbinstallmethod=1

version() {
  echo "version: 2.6"
  echo "updated date: 2022-09-03"
}

Show_Help() {
  version
  echo "Usage: $0  command ...[parameters]....
  --help, -h                  Show this help message, More: https://oneinstack.com/auto
  --version, -v               Show version info
  --nginx_option [1]        Install Nginx server version


  --php_option [1-11]         Install PHP version
  --mphp_ver [53~81]          Install another PHP version (PATH: ${php_install_dir}\${mphp_ver})
  --mphp_addons               Only install another PHP addons
  --phpcache_option [1-4]     Install PHP opcode cache, default: 1 opcache
  --php_extensions [ext name] Install PHP extensions, include zendguardloader,ioncube,
                              sourceguardian,imagick,gmagick,fileinfo,imap,ldap,calendar,phalcon,
                              yaf,yar,redis,memcached,memcache,mongodb,swoole,xdebug
  --nodejs                    Install Nodejs
  --tomcat_option [1-4]       Install Tomcat version
  --jdk_option [1-2]          Install JDK version
  --db_option [1-14]          Install DB version
  --dbinstallmethod [1-2]     DB install method, default: 1 binary install
  --dbrootpwd [password]      DB super password
  --pureftpd                  Install Pure-Ftpd
  --redis                     Install Redis
  --memcached                 Install Memcached
  --phpmyadmin                Install phpMyAdmin
  --python                    Install Python (PATH: ${python_install_dir})
  --ssh_port [No.]            SSH port
  --iptables                  Enable iptables
  --reboot                    Restart the server after installation
  "
}
ARG_NUM=$#
TEMP=`getopt -o hvV --long help,version,nginx_option:,apache,apache_mode_option:,apache_mpm_option:,php_option:,mphp_ver:,mphp_addons,phpcache_option:,php_extensions:,nodejs,tomcat_option:,jdk_option:,db_option:,dbrootpwd:,dbinstallmethod:,pureftpd,redis,memcached,phpmyadmin,python,ssh_port:,iptables,reboot -- "$@" 2>/dev/null`
[ $? != 0 ] && echo "${CWARNING}ERROR: unknown argument! ${CEND}" && Show_Help && exit 1
eval set -- "${TEMP}"
while :; do
  [ -z "$1" ] && break;
  case "$1" in
    -h|--help)
      Show_Help; exit 0
      ;;
    -v|-V|--version)
      version; exit 0
      ;;
    --nginx_option)
      nginx_option=$2; shift 2
      [[ ! ${nginx_option} =~ ^[1-3]$ ]] && { echo "${CWARNING}nginx_option input error! Please only input number 1~3${CEND}"; exit 1; }
      [ -e "${nginx_install_dir}/sbin/nginx" ] && { echo "${CWARNING}Nginx already installed! ${CEND}"; unset nginx_option; }
      [ -e "${tengine_install_dir}/sbin/nginx" ] && { echo "${CWARNING}Tengine already installed! ${CEND}"; unset nginx_option; }
      [ -e "${openresty_install_dir}/nginx/sbin/nginx" ] && { echo "${CWARNING}OpenResty already installed! ${CEND}"; unset nginx_option; }
      ;;
    --apache)
      apache_flag=y; shift 1
      [ -e "${apache_install_dir}/bin/httpd" ] && { echo "${CWARNING}Aapche already installed! ${CEND}"; unset apache_flag; }
      ;;
    --apache_mode_option)
      apache_mode_option=$2; shift 2
      [[ ! ${apache_mode_option} =~ ^[1-2]$ ]] && { echo "${CWARNING}apache_mode_option input error! Please only input number 1~2${CEND}"; exit 1; }
      ;;
    --apache_mpm_option)
      apache_mpm_option=$2; shift 2
      [[ ! ${apache_mpm_option} =~ ^[1-3]$ ]] && { echo "${CWARNING}apache_mpm_option input error! Please only input number 1~3${CEND}"; exit 1; }
      ;;
    --php_option)
      php_option=$2; shift 2
      [[ ! ${php_option} =~ ^[1-9]$|^1[0-1]$ ]] && { echo "${CWARNING}php_option input error! Please only input number 1~11${CEND}"; exit 1; }
      [ -e "${php_install_dir}/bin/phpize" ] && { echo "${CWARNING}PHP already installed! ${CEND}"; unset php_option; }
      ;;
    --mphp_ver)
      mphp_ver=$2; mphp_flag=y; shift 2
      [[ ! "${mphp_ver}" =~ ^5[3-6]$|^7[0-4]$|^8[0-1]$ ]] && { echo "${CWARNING}mphp_ver input error! Please only input number 53~81${CEND}"; exit 1; }
      ;;
    --mphp_addons)
      mphp_addons_flag=y; shift 1
      ;;
    --phpcache_option)
      phpcache_option=$2; shift 2
      ;;
    --php_extensions)
      php_extensions=$2; shift 2
      [ -n "`echo ${php_extensions} | grep -w zendguardloader`" ] && pecl_zendguardloader=1
      [ -n "`echo ${php_extensions} | grep -w ioncube`" ] && pecl_ioncube=1
      [ -n "`echo ${php_extensions} | grep -w sourceguardian`" ] && pecl_sourceguardian=1
      [ -n "`echo ${php_extensions} | grep -w imagick`" ] && pecl_imagick=1
      [ -n "`echo ${php_extensions} | grep -w gmagick`" ] && pecl_gmagick=1
      [ -n "`echo ${php_extensions} | grep -w fileinfo`" ] && pecl_fileinfo=1
      [ -n "`echo ${php_extensions} | grep -w imap`" ] && pecl_imap=1
      [ -n "`echo ${php_extensions} | grep -w ldap`" ] && pecl_ldap=1
      [ -n "`echo ${php_extensions} | grep -w calendar`" ] && pecl_calendar=1
      [ -n "`echo ${php_extensions} | grep -w phalcon`" ] && pecl_phalcon=1
      [ -n "`echo ${php_extensions} | grep -w yaf`" ] && pecl_yaf=1
      [ -n "`echo ${php_extensions} | grep -w yar`" ] && pecl_yar=1
      [ -n "`echo ${php_extensions} | grep -w redis`" ] && pecl_redis=1
      [ -n "`echo ${php_extensions} | grep -w memcached`" ] && pecl_memcached=1
      [ -n "`echo ${php_extensions} | grep -w memcache`" ] && pecl_memcache=1
      [ -n "`echo ${php_extensions} | grep -w mongodb`" ] && pecl_mongodb=1
      [ -n "`echo ${php_extensions} | grep -w swoole`" ] && pecl_swoole=1
      [ -n "`echo ${php_extensions} | grep -w xdebug`" ] && pecl_xdebug=1
      ;;
    --nodejs)
      nodejs_flag=y; shift 1
      [ -e "${nodejs_install_dir}/bin/node" ] && { echo "${CWARNING}Nodejs already installed! ${CEND}"; unset nodejs_flag; }
      ;;
    --tomcat_option)
      tomcat_option=$2; shift 2
      [[ ! ${tomcat_option} =~ ^[1-4]$ ]] && { echo "${CWARNING}tomcat_option input error! Please only input number 1~4${CEND}"; exit 1; }
      [ -e "$tomcat_install_dir/conf/server.xml" ] && { echo "${CWARNING}Tomcat already installed! ${CEND}" ; unset tomcat_option; }
      ;;
    --jdk_option)
      jdk_option=$2; shift 2
      [[ ! ${jdk_option} =~ ^[1-2]$ ]] && { echo "${CWARNING}jdk_option input error! Please only input number 1~2${CEND}"; exit 1; }
      ;;
    --db_option)
      db_option=$2; shift 2
      if [[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]]; then
        [ -d "${db_install_dir}/support-files" ] && { echo "${CWARNING}MySQL already installed! ${CEND}"; unset db_option; }
      elif [ "${db_option}" == '13' ]; then
        [ -e "${pgsql_install_dir}/bin/psql" ] && { echo "${CWARNING}PostgreSQL already installed! ${CEND}"; unset db_option; }
      elif [ "${db_option}" == '14' ]; then
        [ -e "${mongo_install_dir}/bin/mongo" ] && { echo "${CWARNING}MongoDB already installed! ${CEND}"; unset db_option; }
      else
        echo "${CWARNING}db_option input error! Please only input number 1~14${CEND}"
        exit 1
      fi
      ;;
    --dbrootpwd)
      dbrootpwd=$2; shift 2
      dbpostgrespwd="${dbrootpwd}"
      dbmongopwd="${dbrootpwd}"
      ;;
    --dbinstallmethod)
      dbinstallmethod=$2; shift 2
      [[ ! ${dbinstallmethod} =~ ^[1-2]$ ]] && { echo "${CWARNING}dbinstallmethod input error! Please only input number 1~2${CEND}"; exit 1; }
      ;;
    --pureftpd)
      pureftpd_flag=y; shift 1
      [ -e "${pureftpd_install_dir}/sbin/pure-ftpwho" ] && { echo "${CWARNING}Pure-FTPd already installed! ${CEND}"; unset pureftpd_flag; }
      ;;
    --redis)
      redis_flag=y; shift 1
      [ -e "${redis_install_dir}/bin/redis-server" ] && { echo "${CWARNING}redis-server already installed! ${CEND}"; unset redis_flag; }
      ;;
    --memcached)
      memcached_flag=y; shift 1
      [ -e "${memcached_install_dir}/bin/memcached" ] && { echo "${CWARNING}memcached-server already installed! ${CEND}"; unset memcached_flag; }
      ;;
    --phpmyadmin)
      phpmyadmin_flag=y; shift 1
      [ -d "${wwwroot_dir}/default/phpMyAdmin" ] && { echo "${CWARNING}phpMyAdmin already installed! ${CEND}"; unset phpmyadmin_flag; }
      ;;
    --python)
      python_flag=y; shift 1
      ;;
    --ssh_port)
      ssh_port=$2; shift 2
      ;;
    --iptables)
      iptables_flag=y; shift 1
      ;;
    --reboot)
      reboot_flag=y; shift 1
      ;;
    --)
      shift
      ;;
    *)
      echo "${CWARNING}ERROR: unknown argument! ${CEND}" && Show_Help && exit 1
      ;;
  esac
done

# Use default SSH port 22. If you use another SSH port on your server
if [ -e "/etc/ssh/sshd_config" ]; then
  [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && now_ssh_port=22 || now_ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}' | head -1`
  while :; do echo
    [ ${ARG_NUM} == 0 ] && read -e -p "Please input SSH port(Default: ${now_ssh_port}): " ssh_port
    ssh_port=${ssh_port:-${now_ssh_port}}
    if [ ${ssh_port} -eq 22 >/dev/null 2>&1 -o ${ssh_port} -gt 1024 >/dev/null 2>&1 -a ${ssh_port} -lt 65535 >/dev/null 2>&1 ]; then
      break
    else
      echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
      exit 1
    fi
  done

  if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "${ssh_port}" != '22' ]; then
    sed -i "s@^#Port.*@&\nPort ${ssh_port}@" /etc/ssh/sshd_config
  elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
    sed -i "s@^Port.*@Port ${ssh_port}@" /etc/ssh/sshd_config
  fi
fi

if [ ${ARG_NUM} == 0 ]; then
  if [ ! -e ~/.oneinstack ]; then
    # check iptables
    while :; do echo
      read -e -p "Do you want to enable iptables? [y/n]: " iptables_flag
      if [[ ! ${iptables_flag} =~ ^[y,n]$ ]]; then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
      else
        break
      fi
    done
  fi

  # check Web server
  while :; do echo
    #read -e -p "Do you want to install Web server? [y/n]: " web_flag
    web_flag=y
    if [[ ! ${web_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      if [ "${web_flag}" == 'y' ]; then
        # Nginx/Tegine/OpenResty
        while :; do echo
          #echo 'Please select Nginx server:'
          #echo -e "\t${CMSG}1${CEND}. Install Nginx"

          #read -e -p "Please input a number:(Default 1 press Enter) " nginx_option
          nginx_option=1
          if [[ ! ${nginx_option} =~ ^[1-4]$ ]]; then
            echo "${CWARNING}input error! Please only input number 1~4${CEND}"
          else
            [ "${nginx_option}" != '4' -a -e "${nginx_install_dir}/sbin/nginx" ] && { echo "${CWARNING}Nginx already installed! ${CEND}"; unset nginx_option; }

            break
          fi
        done



      fi
      break
    fi
  done

  # choice database
  while :; do echo
  #  read -e -p "Do you want to install Database? [y/n]: " db_flag
    db_flag=y
    if [[ ! ${db_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      if [ "${db_flag}" == 'y' ]; then
        while :; do echo
      #    echo 'Please select a version of the Database:'

    #      echo -e "\t${CMSG} 1${CEND}. Install MySQL-5.7"

        #  read -e -p "Please input a number:(Default 1 press Enter) " db_option
          db_option=2
          if [[ "${db_option}" =~ ^[1-9]$|^1[0-4]$ ]]; then

              [ -d "${db_install_dir}/support-files" ] && { echo "${CWARNING}MySQL already installed! ${CEND}"; unset db_option; break; }

            while :; do

                read -e -p "Please input the root password of MySQL(default: ${dbrootpwd}): " dbpwd
                dbpwd=${dbpwd:-${dbrootpwd}}

              [ -n "`echo ${dbpwd} | grep '[+|&]'`" ] && { echo "${CWARNING}input error,not contain a plus sign (+) and & ${CEND}"; continue; }
              if (( ${#dbpwd} >= 5 )); then
                if [ "${db_option}" == '13' ]; then
                  dbpostgrespwd=${dbpwd}
                elif [ "${db_option}" == '14' ]; then
                  dbmongopwd=${dbpwd}
                else
                  dbrootpwd=${dbpwd}
                fi
                break
              else
                echo "${CWARNING}password least 5 characters! ${CEND}"
              fi
            done
            # choose install methods
            if [[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]]; then
              while :; do echo
             #  echo "Please choose installation of the database:"
             #   echo -e "\t${CMSG}1${CEND}. Install database from binary package."
              #  echo -e "\t${CMSG}2${CEND}. Install database from source package."
            #    read -e -p "Please input a number:(Default 1 press Enter) " dbinstallmethod
                dbinstallmethod=1
                if [[ ! ${dbinstallmethod} =~ ^[1-2]$ ]]; then
                  echo "${CWARNING}input error! Please only input number 1~2${CEND}"
                else
                  break
                fi
              done
            fi
            break
          else
            echo "${CWARNING}input error! Please only input number 1~14${CEND}"
          fi
        done
      fi
      break
    fi
  done

  # choice php
  while :; do echo
    #read -e -p "Do you want to install PHP? [y/n]: " php_flag
    php_flag=y
    if [[ ! ${php_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      if [ "${php_flag}" == 'y' ]; then
        [ -e "${php_install_dir}/bin/phpize" ] && { echo "${CWARNING}PHP already installed! ${CEND}"; unset php_option; break; }
        while :; do echo
        #  echo 'Please select a version of the PHP:'

          #echo -e "\t${CMSG} 1${CEND}. Install php-7.3"
        #  echo -e "\t${CMSG} 2${CEND}. Install php-7.4"
        #  echo -e "\t${CMSG}3${CEND}. Install php-8.0"
        #  echo -e "\t${CMSG}4${CEND}. Install php-8.1"
        #  read -e -p "Please input a number:(Default 1 press Enter) " php_option
          php_option=8
          php_option=${php_option:-8}
          if [[ ! ${php_option} =~ ^[1-9]$|^1[0-1]$ ]]; then
            echo "${CWARNING}input error! Please only input number 1~4${CEND}"
          else
            break
          fi
        done
      fi
      break
    fi
  done

  # check php ver
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    PHP_detail_ver=$(${php_install_dir}/bin/php-config --version)
    PHP_main_ver=${PHP_detail_ver%.*}
  fi

  # PHP opcode cache and extensions
  if [[ ${php_option} =~ ^[1-9]$|^1[0-1]$ ]] || [ -e "${php_install_dir}/bin/phpize" ]; then

    # PHP extension
    while :; do
  #    echo
    #  echo 'Please select PHP extensions:'
  #    echo -e "\t${CMSG} 0${CEND}. Do not install"
  #    echo -e "\t${CMSG} 1${CEND}. Install zendguardloader(PHP<=5.6)"
  #    echo -e "\t${CMSG} 2${CEND}. Install ioncube"
  #    echo -e "\t${CMSG} 3${CEND}. Install sourceguardian(PHP<=7.2)"
  #    echo -e "\t${CMSG} 4${CEND}. Install imagick"
  #    echo -e "\t${CMSG} 5${CEND}. Install gmagick"
  #    echo -e "\t${CMSG} 6${CEND}. Install fileinfo"
  #    echo -e "\t${CMSG} 7${CEND}. Install imap"
  #    echo -e "\t${CMSG} 8${CEND}. Install ldap"
  #    echo -e "\t${CMSG} 9${CEND}. Install phalcon(PHP>=5.5)"
    #  echo -e "\t${CMSG}10${CEND}. Install yaf(PHP>=7.0)"
  #    echo -e "\t${CMSG}11${CEND}. Install redis"
  #    echo -e "\t${CMSG}12${CEND}. Install memcached"
    #  echo -e "\t${CMSG}13${CEND}. Install memcache"
  #    echo -e "\t${CMSG}14${CEND}. Install mongodb"
  #    echo -e "\t${CMSG}15${CEND}. Install swoole"
  #    echo -e "\t${CMSG}16${CEND}. Install xdebug(PHP>=5.5)"
    #  read -e -p "Please input numbers:(Default '4 11 12' press Enter) " phpext_option
      phpext_option='2 4 6 12 13'
      [ "${phpext_option}" == '0' ] && break
      array_phpext=(${phpext_option})
      array_all=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)
      for v in ${array_phpext[@]}
      do
        [ -z "`echo ${array_all[@]} | grep -w ${v}`" ] && phpext_flag=1
      done
      if [ "${phpext_flag}" == '1' ]; then
        unset phpext_flag
        echo; echo "${CWARNING}input error! Please only input number 4 11 12 and so on${CEND}"; echo
        continue
      else
        [ -n "`echo ${array_phpext[@]} | grep -w 1`" ] && pecl_zendguardloader=1
        [ -n "`echo ${array_phpext[@]} | grep -w 2`" ] && pecl_ioncube=1
        [ -n "`echo ${array_phpext[@]} | grep -w 3`" ] && pecl_sourceguardian=1
        [ -n "`echo ${array_phpext[@]} | grep -w 4`" ] && pecl_imagick=1
        [ -n "`echo ${array_phpext[@]} | grep -w 5`" ] && pecl_gmagick=1
        [ -n "`echo ${array_phpext[@]} | grep -w 6`" ] && pecl_fileinfo=1
        [ -n "`echo ${array_phpext[@]} | grep -w 7`" ] && pecl_imap=1
        [ -n "`echo ${array_phpext[@]} | grep -w 8`" ] && pecl_ldap=1
        [ -n "`echo ${array_phpext[@]} | grep -w 9`" ] && pecl_phalcon=1
        [ -n "`echo ${array_phpext[@]} | grep -w 10`" ] && pecl_yaf=1
        [ -n "`echo ${array_phpext[@]} | grep -w 11`" ] && pecl_redis=1
        [ -n "`echo ${array_phpext[@]} | grep -w 12`" ] && pecl_memcached=1
        [ -n "`echo ${array_phpext[@]} | grep -w 13`" ] && pecl_memcache=1
        [ -n "`echo ${array_phpext[@]} | grep -w 14`" ] && pecl_mongodb=1
        [ -n "`echo ${array_phpext[@]} | grep -w 15`" ] && pecl_swoole=1
        [ -n "`echo ${array_phpext[@]} | grep -w 16`" ] && pecl_xdebug=1
        break
      fi
    done
  fi





  # check phpMyAdmin
  if [[ ${php_option} =~ ^[1-9]$|^1[0-1]$ ]] || [ -e "${php_install_dir}/bin/phpize" ]; then
    while :; do echo
    #  read -e -p "Do you want to install phpMyAdmin? [y/n]: " phpmyadmin_flag
      phpmyadmin_flag=y
      if [[ ! ${phpmyadmin_flag} =~ ^[y,n]$ ]]; then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
      else
        [ "${phpmyadmin_flag}" == 'y' -a -d "${wwwroot_dir}/default/phpMyAdmin" ] && { echo "${CWARNING}phpMyAdmin already installed! ${CEND}"; unset phpmyadmin_flag; }
        break
      fi
    done
  fi


fi

if [[ ${nginx_option} =~ ^[1-3]$ ]] || [ "${apache_flag}" == 'y' ] || [[ ${tomcat_option} =~ ^[1-4]$ ]]; then
  [ ! -d ${wwwroot_dir}/default ] && mkdir -p ${wwwroot_dir}/default
  [ ! -d ${wwwlogs_dir} ] && mkdir -p ${wwwlogs_dir}
fi
[ -d /data ] && chmod 755 /data

# install wget gcc curl python
if [ ! -e ~/.oneinstack ]; then
  downloadDepsSrc=1
  [ "${PM}" == 'apt-get' ] && apt-get -y update > /dev/null
  [ "${PM}" == 'yum' ] && yum clean all
  ${PM} -y install wget gcc curl python
  [ "${RHEL_ver}" == '8' ] && { yum -y install python36; sudo alternatives --set python /usr/bin/python3; }
  [ ! -e "/usr/bin/python" ] && [ -e "/usr/bin/python3" ] && ln -s /usr/bin/python3 /usr/bin/python
  clear
fi

# get the IP information
IPADDR=$(./include/get_ipaddr.py)
PUBLIC_IPADDR=$(./include/get_public_ipaddr.py)
IPADDR_COUNTRY=$(./include/get_ipaddr_state.py ${PUBLIC_IPADDR})

# openSSL
. ./include/openssl.sh

# Check download source packages
. ./include/check_download.sh

[ "${armplatform}" == "y" ] && dbinstallmethod=2
checkDownload 2>&1 | tee -a ${oneinstack_dir}/install.log

# get OS Memory
. ./include/memory.sh

if [ ! -e ~/.oneinstack ]; then
  # Check binary dependencies packages
  . ./include/check_sw.sh
  case "${Family}" in
    "rhel")
      installDepsRHEL 2>&1 | tee ${oneinstack_dir}/install.log
      . include/init_RHEL.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
    "debian")
      installDepsDebian 2>&1 | tee ${oneinstack_dir}/install.log
      . include/init_Debian.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
    "ubuntu")
      installDepsUbuntu 2>&1 | tee ${oneinstack_dir}/install.log
      . include/init_Ubuntu.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
  esac
  # Install dependencies from source package
  installDepsBySrc 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# start Time
startTime=`date +%s`

# openSSL
Install_openSSL | tee -a ${oneinstack_dir}/install.log

# Jemalloc
if [[ ${nginx_option} =~ ^[1-3]$ ]] || [[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]]; then
  . include/jemalloc.sh
  Install_Jemalloc | tee -a ${oneinstack_dir}/install.log
fi

# Database
[ "${Family}" == 'rhel' ] && [ "${RHEL_ver}" == '9' ] && dbinstallmethod=2 && checkDownload
case "${db_option}" in
  1)
    . include/mysql-8.0.sh
    Install_MySQL80 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/mysql-5.7.sh
    Install_MySQL57 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  3)
    . include/mysql-5.6.sh
    Install_MySQL56 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  4)
    . include/mysql-5.5.sh
    Install_MySQL55 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  5)
    . include/mariadb-10.6.sh
    Install_MariaDB106 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  6)
    . include/mariadb-10.5.sh
    Install_MariaDB105 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  7)
    . include/mariadb-10.4.sh
    Install_MariaDB104 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  8)
    . include/mariadb-5.5.sh
    Install_MariaDB55 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  9)
    [ "${Family}" == 'rhel' ] && [ "${RHEL_ver}" == '8' ] && dbinstallmethod=2 && checkDownload
    . include/percona-8.0.sh
    Install_Percona80 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  10)
    . include/percona-5.7.sh
    Install_Percona57 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  11)
    . include/percona-5.6.sh
    Install_Percona56 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  12)
    . include/percona-5.5.sh
    Install_Percona55 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  13)
    . include/postgresql.sh
    Install_PostgreSQL 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  14)
    . include/mongodb.sh
    Install_MongoDB 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

# Nginx server
case "${nginx_option}" in
  1)
    . include/nginx.sh
    Install_Nginx 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/tengine.sh
    Install_Tengine 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  3)
    . include/openresty.sh
    Install_OpenResty 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

# Apache
if [ "${apache_flag}" == 'y' ]; then
  apache_mode_option=${apache_mode_option:-1}
  apache_mpm_option=${apache_mpm_option:-1}
  . include/apache.sh
  Install_Apache 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# PHP
case "${php_option}" in
  1)
    . include/php-5.3.sh
    Install_PHP53 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/php-5.4.sh
    Install_PHP54 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  3)
    . include/php-5.5.sh
    Install_PHP55 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  4)
    . include/php-5.6.sh
    Install_PHP56 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  5)
    . include/php-7.0.sh
    Install_PHP70 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  6)
    . include/php-7.1.sh
    Install_PHP71 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  7)
    . include/php-7.2.sh
    Install_PHP72 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  8)
    . include/php-7.3.sh
    Install_PHP73 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  9)
    . include/php-7.4.sh
    Install_PHP74 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  10)
    . include/php-8.0.sh
    Install_PHP80 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  11)
    . include/php-8.1.sh
    Install_PHP81 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

PHP_addons() {
  # PHP opcode cache
  case "${phpcache_option}" in
    1)
      . include/zendopcache.sh
      Install_ZendOPcache 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
    2)
      . include/apcu.sh
      Install_APCU 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
    3)
      . include/xcache.sh
      Install_XCache 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
    4)
      . include/eaccelerator.sh
      Install_eAccelerator 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
  esac

  # ZendGuardLoader
  if [ "${pecl_zendguardloader}" == '1' ]; then
    . include/ZendGuardLoader.sh
    Install_ZendGuardLoader 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # ioncube
  if [ "${pecl_ioncube}" == '1' ]; then
    . include/ioncube.sh
    Install_ionCube 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # SourceGuardian
  if [ "${pecl_sourceguardian}" == '1' ]; then
    . include/sourceguardian.sh
    Install_SourceGuardian 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # imagick
  if [ "${pecl_imagick}" == '1' ]; then
    . include/ImageMagick.sh
    Install_ImageMagick 2>&1 | tee -a ${oneinstack_dir}/install.log
    Install_pecl_imagick 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # gmagick
  if [ "${pecl_gmagick}" == '1' ]; then
    . include/GraphicsMagick.sh
    Install_GraphicsMagick 2>&1 | tee -a ${oneinstack_dir}/install.log
    Install_pecl_gmagick 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # fileinfo
  if [ "${pecl_fileinfo}" == '1' ]; then
    . include/pecl_fileinfo.sh
    Install_pecl_fileinfo 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # imap
  if [ "${pecl_imap}" == '1' ]; then
    . include/pecl_imap.sh
    Install_pecl_imap 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # ldap
  if [ "${pecl_ldap}" == '1' ]; then
    . include/pecl_ldap.sh
    Install_pecl_ldap 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # calendar
  if [ "${pecl_calendar}" == '1' ]; then
    . include/pecl_calendar.sh
    Install_pecl_calendar 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # phalcon
  if [ "${pecl_phalcon}" == '1' ]; then
    . include/pecl_phalcon.sh
    Install_pecl_phalcon 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # yaf
  if [ "${pecl_yaf}" == '1' ]; then
    . include/pecl_yaf.sh
    Install_pecl_yaf 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # yar
  if [ "${pecl_yar}" == '1' ]; then
    . include/pecl_yar.sh
    Install_pecl_yar 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # pecl_memcached
  if [ "${pecl_memcached}" == '1' ]; then
    . include/memcached.sh
    Install_pecl_memcached 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # pecl_memcache
  if [ "${pecl_memcache}" == '1' ]; then
    . include/memcached.sh
    Install_pecl_memcache 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # pecl_redis
  if [ "${pecl_redis}" == '1' ]; then
    . include/redis.sh
    Install_pecl_redis 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # pecl_mongodb
  if [ "${pecl_mongodb}" == '1' ]; then
    . include/pecl_mongodb.sh
    Install_pecl_mongodb 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # swoole
  if [ "${pecl_swoole}" == '1' ]; then
    . include/pecl_swoole.sh
    Install_pecl_swoole 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # xdebug
  if [ "${pecl_xdebug}" == '1' ]; then
    . include/pecl_xdebug.sh
    Install_pecl_xdebug 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi

  # pecl_pgsql
  if [ -e "${pgsql_install_dir}/bin/psql" ]; then
    . include/pecl_pgsql.sh
    Install_pecl_pgsql 2>&1 | tee -a ${oneinstack_dir}/install.log
  fi
}

[ "${mphp_addons_flag}" != 'y' ] && PHP_addons

if [ "${mphp_flag}" == 'y' ]; then
  . include/mphp.sh
  Install_MPHP 2>&1 | tee -a ${oneinstack_dir}/install.log
  php_install_dir=${php_install_dir}${mphp_ver}
  PHP_addons
fi

# JDK
case "${jdk_option}" in
  1)
    . include/openjdk-8.sh
    Install_OpenJDK8 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/openjdk-11.sh
    Install_OpenJDK11 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

case "${tomcat_option}" in
  1)
    . include/tomcat-10.sh
    Install_Tomcat10 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/tomcat-9.sh
    Install_Tomcat9 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  3)
    . include/tomcat-8.sh
    Install_Tomcat8 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  4)
    . include/tomcat-7.sh
    Install_Tomcat7 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

# Nodejs
if [ "${nodejs_flag}" == 'y' ]; then
  . include/nodejs.sh
  Install_Nodejs 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# Pure-FTPd
if [ "${pureftpd_flag}" == 'y' ]; then
  . include/pureftpd.sh
  Install_PureFTPd 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# phpMyAdmin
if [ "${phpmyadmin_flag}" == 'y' ]; then
  . include/phpmyadmin.sh
  Install_phpMyAdmin 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# redis
if [ "${redis_flag}" == 'y' ]; then
  . include/redis.sh
  Install_redis_server 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# memcached
if [ "${memcached_flag}" == 'y' ]; then
  . include/memcached.sh
  Install_memcached_server 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# index example
if [ -d "${wwwroot_dir}/default" ]; then
  . include/demo.sh
  DEMO 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# get web_install_dir and db_install_dir
. include/check_dir.sh

# Python
if [ "${python_flag}" == 'y' ]; then
  . include/python.sh
  Install_Python 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# Starting DB
[ -d "/etc/mysql" ] && /bin/mv /etc/mysql{,_bk}
[ -d "${db_install_dir}/support-files" ] && [ -z "`ps -ef | grep mysqld_safe | grep -v grep`" ] && service mysqld start

# reload php
[ -e "${php_install_dir}/sbin/php-fpm" ] && { [ -e "/bin/systemctl" ] && systemctl reload php-fpm || service php-fpm reload; }
[ -n "${mphp_ver}" -a -e "${php_install_dir}${mphp_ver}/sbin/php-fpm" ] && { [ -e "/bin/systemctl" ] && systemctl reload php${mphp_ver}-fpm || service php${mphp_ver}-fpm reload; }
[ -e "${apache_install_dir}/bin/apachectl" ] && ${apache_install_dir}/bin/apachectl -k graceful

endTime=`date +%s`
((installTime=($endTime-$startTime)/60))
echo "####################Congratulations########################"
echo "Total OneinStack Install Time: ${CQUESTION}${installTime}${CEND} minutes"
[[ "${nginx_option}" =~ ^[1-3]$ ]] && echo -e "\n$(printf "%-32s" "Nginx install dir":)${CMSG}${web_install_dir}${CEND}"
[ "${apache_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "Apache install dir":)${CMSG}${apache_install_dir}${CEND}"
[[ "${tomcat_option}" =~ ^[1-4]$ ]] && echo -e "\n$(printf "%-32s" "Tomcat install dir":)${CMSG}${tomcat_install_dir}${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo -e "\n$(printf "%-32s" "Database install dir:")${CMSG}${db_install_dir}${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo "$(printf "%-32s" "Database data dir:")${CMSG}${db_data_dir}${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo "$(printf "%-32s" "Database user:")${CMSG}root${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo "$(printf "%-32s" "Database password:")${CMSG}${dbrootpwd}${CEND}"
[ "${db_option}" == '13' ] && echo -e "\n$(printf "%-32s" "PostgreSQL install dir:")${CMSG}${pgsql_install_dir}${CEND}"
[ "${db_option}" == '13' ] && echo "$(printf "%-32s" "PostgreSQL data dir:")${CMSG}${pgsql_data_dir}${CEND}"
[ "${db_option}" == '13' ] && echo "$(printf "%-32s" "PostgreSQL user:")${CMSG}postgres${CEND}"
[ "${db_option}" == '13' ] && echo "$(printf "%-32s" "postgres password:")${CMSG}${dbpostgrespwd}${CEND}"
[ "${db_option}" == '14' ] && echo -e "\n$(printf "%-32s" "MongoDB install dir:")${CMSG}${mongo_install_dir}${CEND}"
[ "${db_option}" == '14' ] && echo "$(printf "%-32s" "MongoDB data dir:")${CMSG}${mongo_data_dir}${CEND}"
[ "${db_option}" == '14' ] && echo "$(printf "%-32s" "MongoDB user:")${CMSG}root${CEND}"
[ "${db_option}" == '14' ] && echo "$(printf "%-32s" "MongoDB password:")${CMSG}${dbmongopwd}${CEND}"
[[ "${php_option}" =~ ^[1-9]$|^1[0-1]$ ]] && echo -e "\n$(printf "%-32s" "PHP install dir:")${CMSG}${php_install_dir}${CEND}"
[ "${phpcache_option}" == '1' ] && echo "$(printf "%-32s" "Opcache Control Panel URL:")${CMSG}http://${IPADDR}/ocp.php${CEND}"
[ "${phpcache_option}" == '2' ] && echo "$(printf "%-32s" "APC Control Panel URL:")${CMSG}http://${IPADDR}/apc.php${CEND}"
[ "${phpcache_option}" == '3' -a -e "${php_install_dir}/etc/php.d/04-xcache.ini" ] && echo "$(printf "%-32s" "xcache Control Panel URL:")${CMSG}http://${IPADDR}/xcache${CEND}"
[ "${phpcache_option}" == '3' -a -e "${php_install_dir}/etc/php.d/04-xcache.ini" ] && echo "$(printf "%-32s" "xcache user:")${CMSG}admin${CEND}"
[ "${phpcache_option}" == '3' -a -e "${php_install_dir}/etc/php.d/04-xcache.ini" ] && echo "$(printf "%-32s" "xcache password:")${CMSG}${xcachepwd}${CEND}"
[ "${phpcache_option}" == '4' -a -e "${php_install_dir}/etc/php.d/02-eaccelerator.ini" ] && echo "$(printf "%-32s" "eAccelerator Control Panel URL:")${CMSG}http://${IPADDR}/control.php${CEND}"
[ "${phpcache_option}" == '4' -a -e "${php_install_dir}/etc/php.d/02-eaccelerator.ini" ] && echo "$(printf "%-32s" "eAccelerator user:")${CMSG}admin${CEND}"
[ "${phpcache_option}" == '4' -a -e "${php_install_dir}/etc/php.d/02-eaccelerator.ini" ] && echo "$(printf "%-32s" "eAccelerator password:")${CMSG}eAccelerator${CEND}"
[ "${pureftpd_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "Pure-FTPd install dir:")${CMSG}${pureftpd_install_dir}${CEND}"
[ "${pureftpd_flag}" == 'y' ] && echo "$(printf "%-32s" "Create FTP virtual script:")${CMSG}./pureftpd_vhost.sh${CEND}"
[ "${phpmyadmin_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "phpMyAdmin dir:")${CMSG}${wwwroot_dir}/default/phpMyAdmin${CEND}"
[ "${phpmyadmin_flag}" == 'y' ] && echo "$(printf "%-32s" "phpMyAdmin Control Panel URL:")${CMSG}http://${IPADDR}/phpMyAdmin${CEND}"
[ "${redis_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "redis install dir:")${CMSG}${redis_install_dir}${CEND}"
[ "${memcached_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "memcached install dir:")${CMSG}${memcached_install_dir}${CEND}"
if [[ ${nginx_option} =~ ^[1-3]$ ]] || [ "${apache_flag}" == 'y' ] || [[ ${tomcat_option} =~ ^[1-4]$ ]]; then
  echo -e "\n$(printf "%-32s" "Index URL:")${CMSG}http://${IPADDR}/${CEND}"
fi
if [ ${ARG_NUM} == 0 ]; then
  while :; do echo
  echo "Create Steroid Database"
  DB="S4QL"
  USER="steroid"
  PASS="steroid"
 /usr/local/mysql/bin/mysql -u root -p${dbpwd} -e "CREATE DATABASE $DB CHARACTER SET utf8 COLLATE utf8_general_ci";
/usr/local/mysql/bin/mysql -u root -p${dbpwd} -e "CREATE USER $USER@'%' IDENTIFIED BY '$PASS'";
/usr/local/mysql/bin/mysql -u root -p${dbpwd} -e "GRANT SELECT ON $DB.* TO '$USER'@'%'";
  CREATE USER 'steroid1'@'%' IDENTIFIED WITH mysql_native_password AS '***';GRANT SELECT ON *.* TO 'steroid1'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
  echo "QUESTION: Enter your custom domain name (peer2.steroid.io): "
  read vhosturl
  echo "Generate vhost ."
  sleep 0.5
  echo "Generate vhost .."
  sleep 0.5
  echo "Generate vhost .."
  sleep 0.5
  echo "server {
    listen 80;
    listen [::]:80;
    server_name ${vhosturl};
    access_log /data/wwwlogs/${vhosturl}_nginx.log combined;
    index index.html index.htm index.php;
    root /data/wwwroot/${vhosturl};

    include /usr/local/nginx/conf/rewrite/other.conf;
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
  }" > /usr/local/nginx/conf/vhost/${vhosturl}.conf

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
      public $db_password = '${dbpwd}';
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

    echo "${CMSG}Please restart the server and see if the services start up fine.${CEND}"
    read -e -p "Do you want to restart OS ? [y/n]: " reboot_flag
    if [[ ! "${reboot_flag}" =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      break
    fi
  done
fi
[ "${reboot_flag}" == 'y' ] && reboot
