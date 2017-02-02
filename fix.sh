#httpd
service httpd stop
#
cp -f /vagrant/httpd.conf.1 /etc/httpd/conf/httpd.conf
cp /vagrant/vhost.conf.1 /etc/httpd/conf.d/vhost.conf
cp /vagrant/workers.properties1 /etc/httpd/conf.d/workers.properties
service httpd start
#tomcat
service tomcat stop 
sed -i '/export/d' /home/tomcat/.bashrc
chown -R tomcat:tomcat /opt/apache/tomcat/current/logs
#alternatives --set java /opt/oracle/java/x64//jdk1.7.0_79/bin/java
sudo alternatives --remove java /opt/oracle/java/i586//jdk1.7.0_79/bin/java
sudo alternatives --remove java /opt/oracle/java/x64//jdk1.7.0_79/bin/java
sudo alternatives --install /usr/bin/java java /opt/oracle/java/x64/jdk1.7.0_79/bin/java 2000
sudo alternatives --install /usr/bin/java java /opt/oracle/java/i586/jdk1.7.0_79/bin/java 1000
#cd /opt/apache/tomcat/7.0.62/bin/ >/dev/null
#./configtest.sh --with-java=/opt/oracle/java/x64/jdk1.7.0_79/bin/java >/dev/null 2>&1
chkconfig tomcat on --level 35
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables-save > /etc/iptables_rules
echo "/sbin/iptables-restore < /etc/iptables_rules" >>/etc/rc.local
service tomcat start
