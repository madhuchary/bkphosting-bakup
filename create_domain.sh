#!/bin/bash
###
#set -x
echo -e "please enter the Domain Name: \n"
read dn
grep -w $dn "/etc/bind/named.conf.default-zones"

if [ $? == 0 ]
then
echo " Domain name $dn already exist"
exit 1
fi
####

###
echo "creating FTP user name...."
un=`echo $dn|cut -c 1-3`
udate=`date +%d%m`
pdate=`date +%d%m%S`
num=1 
passwd=`perl -e 'print crypt('$un$pdate', "aa")'`
result=1
until [ $result == 0 ]
do 
useradd -p $passwd -m $un$udate$num -c "$dn"
result=$?
let num+=1
done
let num=$num-1
echo "FTP user $un$udate$num created with password $un$pdate"
####

###
echo "creating www and log folders..."
mkdir  /home/$un$udate$num/www
mkdir  /home/$un$udate$num/logs
chown -R $un$udate$num.$un$udate$num /home/$un$udate$num
#chown -R $un$udate$num.$un$udate$num /home/$un$udate$num/logs
echo "www and logs folders created"
####

###
echo "Creating DNS entries..."
echo -e "zone \"$dn\" {" >> "/etc/bind/named.conf.default-zones"
echo  -e "\ttype master;" >> "/etc/bind/named.conf.default-zones"
echo  -e "\tfile \"$dn\";" >> "/etc/bind/named.conf.default-zones"
echo -e "};" >> "/etc/bind/named.conf.default-zones"
echo -e "" >> "/etc/bind/named.conf.default-zones"

if [ -e /var/cache/bind/template ]
then
cp "/var/cache/bind/template" "/var/cache/bind/$dn"
else 
echo "file Template does not exist"
exit 2
fi

echo "DNS entries created"
####

###
echo "restarting DNS service"

/usr/sbin/service bind9 restart

echo "DNS restarted"
####

###
echo "creating Apache config files..."
if [ -e /etc/apache2/sites-available/$dn ]
then
echo "$dn apache config already exist"
else

echo -e "<VirtualHost *:80>" > /etc/apache2/sites-available/$dn
echo -e "\tServerAdmin madhu.sudhan@bkphosting.com" >> /etc/apache2/sites-available/$dn
echo -e "\tServerName $dn" >> /etc/apache2/sites-available/$dn
echo -e "\tServerAlias www.$dn" >> /etc/apache2/sites-available/$dn
echo -e "\tDocumentRoot /home/$un$udate$num/www" >> /etc/apache2/sites-available/$dn
echo -e "\tErrorLog /home/$un$udate$num/logs/error.log" >> /etc/apache2/sites-available/$dn
echo -e "\tCustomLog /home/$un$udate$num/logs/access.log common" >> /etc/apache2/sites-available/$dn
echo -e "\tOptions -Indexes FollowSymLinks" >> /etc/apache2/sites-available/$dn
echo -e "</VirtualHost>" >> /etc/apache2/sites-available/$dn
echo "$dn apache config done"
a2ensite $dn

echo "restarting apache"
service apache2 reload
fi
echo -e "\nPlease email below details to user\n"
echo -e "Domain Name:$dn \nFTP user Name: $un$udate$num \nPassword: $un$pdate"
#set +x
