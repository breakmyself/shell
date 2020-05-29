#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#说明：amqp.1.10.2仅适用于php5.6版本以上，pear1.4版本以上,系统要求，CentOS7，其他操作系统后续会陆续增加

public_file=/www/server/panel/install/public.sh
[ ! -f $public_file ] && wget -O $public_file http://download.bt.cn/install/public.sh -T 5;

publicFileMd5=$(md5sum ${public_file}|awk '{print $1}')
md5check="66c89de255c11b64d5215be67dc4fdc6"
[ "${publicFileMd5}" != "${md5check}"  ] && wget -O $public_file http://download.bt.cn/install/public.sh -T 5;

. $public_file
download_Url=$NODE_URL
srcPath='/root';

#安装amqp需要安装librabbitmq依赖
System_Lib(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ] ; then
		installPack="librabbitmq-devel"
	fi

	[ "${installPack}" != "" ] && ${PM} install ${installPack} -y
}
#amqp.1.10.2适合使用的php版本
Ext_Path(){
  case "${version}" in 
    '56')
    extFile="/www/server/php/56/lib/php/extensions/no-debug-non-zts-20131226/amqp.so"
    ;;
    '70')
    extFile="/www/server/php/70/lib/php/extensions/no-debug-non-zts-20151012/amqp.so"
    ;;
    '71')
    extFile="/www/server/php/71/lib/php/extensions/no-debug-non-zts-20160303/amqp.so"
    ;;
    '72')
    extFile="/www/server/php/72/lib/php/extensions/no-debug-non-zts-20170718/amqp.so"
    ;;
    '73')
    extFile='/www/server/php/73/lib/php/extensions/no-debug-non-zts-20180731/amqp.so'
    ;;
    '74')
    extFile='/www/server/php/74/lib/php/extensions/no-debug-non-zts-20190902/amqp.so'
    ;;
	esac
}

Install_librabbitmq()
{	
		#下载smbclient客户端
		cd $srcPath
		wget  https://pecl.php.net/get/amqp-1.10.2.tgz
		tar zxvf amqp-1.10.2.tgz
		cd $srcPath/amqp-1.10.2
		/www/server/php/$version/bin/phpize
		./configure --with-php-config=/www/server/php/$version/bin/php-config 
		make && make install
	if [ ! -d /www/server/php/$version ];then
		return;
	fi
	
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'amqp.so'`
	if [ "${isInstall}" != "" ];then
		echo "php-$vphp 已安装过amqp,请选择其它版本!"
		echo "php-$vphp is already install amqp, Plese select other version!"
		return
	fi
	
	
	echo "extension=amqp.so" >> /www/server/php/$version/etc/php.ini
	/etc/init.d/php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
	/etc/init.d/php-fpm-$version reload
	rm -rf $srcPath/amqp*
	/www/server/php/${version}/bin/php -m|grep amqp
}


Uninstall_librabbitmq()
{
	if [ ! -d /www/server/php/$version ];then
		rm -rf $srcPath/amqp*
	fi
	
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'amqp.so'`
	if [ "${isInstall}" = "" ];then
		echo "php-$vphp 未安装amqp,请选择其它版本!"
		echo "php-$vphp not install amqp, Plese select other version!"
		return
	fi

	rm -f ${extFile}
	sed -i '/amqp.so/d'  /www/server/php/$version/etc/php.ini
	/etc/init.d/php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}
Bt_Check(){
	checkFile="/www/server/panel/install/check.sh"
	wget -O ${checkFile} ${download_Url}/tools/check.sh			
	. ${checkFile} 
}
actionType=$1
version=$2
vphp=${version:0:1}.${version:1:1}
if [ "$actionType" == 'install' ];then
	Ext_Path
	Install_librabbitmq
	Bt_Check
elif [ "$actionType" == 'uninstall' ];then
	Ext_Path
	Uninstall_librabbitmq
fi
