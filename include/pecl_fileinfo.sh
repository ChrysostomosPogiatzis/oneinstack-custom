#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

Install_pecl_fileinfo() {
  if [ -e "${php_install_dir}/bin/phpize" ]; then
    pushd ${oneinstack_dir}/src > /dev/null
    phpExtensionDir=$(${php_install_dir}/bin/php-config --extension-dir)
    PHP_detail_ver=$(${php_install_dir}/bin/php-config --version)
    src_url=https://secure.php.net/distributions/php-${PHP_detail_ver}.tar.gz && Download_src
    tar xzf php-${PHP_detail_ver}.tar.gz


#file_info_install
    pushd php-${PHP_detail_ver}/ext/fileinfo > /dev/null
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config
    [[ "${php_option}" =~ ^1[0-1]$ ]] && sed -i 's@^CFLAGS = -g -O2@CFLAGS = -std=c99 -g -O2@' Makefile
    make -j ${THREAD} && make install
    popd > /dev/null
    if [ -f "${phpExtensionDir}/fileinfo.so" ]; then
      echo 'extension=fileinfo.so' > ${php_install_dir}/etc/php.d/04-fileinfo.ini
      echo "${CSUCCESS}PHP fileinfo module installed successfully! ${CEND}"
  
    else
      echo "${CFAILURE}PHP fileinfo module install failed, Please contact the author! ${CEND}" && lsb_release -a
    fi
    popd > /dev/null

    pushd php-${PHP_detail_ver}/ext/gmp > /dev/null
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config
    [[ "${php_option}" =~ ^1[0-1]$ ]] && sed -i 's@^CFLAGS = -g -O2@CFLAGS = -std=c99 -g -O2@' Makefile
    make -j ${THREAD} && make install
    popd > /dev/null
    if [ -f "${phpExtensionDir}/gmp.so" ]; then
      echo 'extension=gmp.so' > ${php_install_dir}/etc/php.d/04-gmp.ini
      echo "${CSUCCESS}PHP gmp module installed successfully! ${CEND}"

    else
      echo "${CFAILURE}PHP gmp module install failed, Please contact the author! ${CEND}" && lsb_release -a
    fi
    popd > /dev/null

    pushd php-${PHP_detail_ver}/ext/bcmath > /dev/null
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config
    [[ "${php_option}" =~ ^1[0-1]$ ]] && sed -i 's@^CFLAGS = -g -O2@CFLAGS = -std=c99 -g -O2@' Makefile
    make -j ${THREAD} && make install
    popd > /dev/null
    if [ -f "${phpExtensionDir}/bcmath.so" ]; then
      echo 'extension=bcmath.so' > ${php_install_dir}/etc/php.d/04-bcmath.ini
      echo "${CSUCCESS}PHP bcmath module installed successfully! ${CEND}"

    else
      echo "${CFAILURE}PHP bcmath module install failed, Please contact the author! ${CEND}" && lsb_release -a
    fi
    popd > /dev/null



    pushd php-${PHP_detail_ver}/ext/pdo > /dev/null
    ${php_install_dir}/bin/phpize
    ./configure --with-php-config=${php_install_dir}/bin/php-config
    [[ "${php_option}" =~ ^1[0-1]$ ]] && sed -i 's@^CFLAGS = -g -O2@CFLAGS = -std=c99 -g -O2@' Makefile
    make -j ${THREAD} && make install
    popd > /dev/null
    if [ -f "${phpExtensionDir}/pdo.so" ]; then
      echo 'extension=pdo.so' > ${php_install_dir}/etc/php.d/04-pdo.ini
      echo "${CSUCCESS}PHP pdo module installed successfully! ${CEND}"

    else
      echo "${CFAILURE}PHP pdo module install failed, Please contact the author! ${CEND}" && lsb_release -a
    fi
    popd > /dev/null

    rm -rf php-${PHP_detail_ver}
  fi
}

Uninstall_pecl_fileinfo() {
  if [ -e "${php_install_dir}/etc/php.d/04-fileinfo.ini" ]; then
    rm -f ${php_install_dir}/etc/php.d/04-fileinfo.ini
    echo; echo "${CMSG}PHP fileinfo module uninstall completed${CEND}"
  else
    echo; echo "${CWARNING}PHP fileinfo module does not exist! ${CEND}"
  fi
}
