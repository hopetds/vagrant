#script is used ONLY for provisioning that fixes specific errors		   		
#Use it only if you know what it does										   			
#Do NOT use it after changing config of the server that already works properly 			
#After you run vagrant up and confirm that all problems are gone - exclude this	script  
#from Vagrantfile by commenting line: config.vm.provision "shell", path: "fix.sh"       

#v.1.0	

#>>>>>>>>>>>>>httpd fixing section:														
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#Copying !previously! edited configs changes in httpd.conf: - Commented defined VirutalHost									
service httpd stop
cp /vagrant/httpd.conf.1 /etc/httpd/conf/httpd.conf

#Changes in vhost.conf.conf:  - mntlab:80 changed to *:80 to accept all requests and tomcat-worker > tomcat worker 											        
cp /vagrant/vhost.conf.1 /etc/httpd/conf.d/vhost.conf
	
#Changes in workers.properties: tomcat.worker > tomcat-worker
cp /vagrant/workers.properties1 /etc/httpd/conf.d/workers.properties

#Restarting httpd service to apply Changes                                              
service httpd start

#>>>>>>>>>>>>>tomcat fixing section<<<<<<<<<<<<<<<<<<<
service tomcat stop
#Removing defined CATALINA_HOME=/tmp and JAVA_HOME=/tmp from user:tomcat env 			
sed -i '/export/d' /home/tomcat/.bashrc

#Changing permissions on log folder	root:root > tomcat:tomcat. After that tomcat will be able to create file in log folder							
chown -R tomcat:tomcat /opt/apache/tomcat/current/logs

#Alternatives related to java contained double /. Nothing wrong but harder to read. Removing 'bad' path with -remove and add new pathes with setting priority 2 and 1 to switch to x64 java automatically					    
alternatives --remove java /opt/oracle/java/i586//jdk1.7.0_79/bin/java
alternatives --remove java /opt/oracle/java/x64//jdk1.7.0_79/bin/java
alternatives --install /usr/bin/java java /opt/oracle/java/x64/jdk1.7.0_79/bin/java 2
alternatives --install /usr/bin/java java /opt/oracle/java/i586/jdk1.7.0_79/bin/java 1

#Adding tomcat service to chkconfig. The chkconfig utility is a command-line tool that allows you to specify in which runlevel to start a selected service, as well as to list all available services along with their current setting.							
chkconfig tomcat on --level 35

#Create a create a symbolic link for tomcat logs
#ln -s /opt/apache/tomcat/7.0.62/logs /var/log/tomcat

#Restarting reconfigured tomcat service
service tomcat start

#>>>>>>>>>>>>>>>IPtables fixing section
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#Removing readonly permissions on iptables file 	
chattr -i /etc/sysconfig/iptables

#Fixing iptables-restore functioning that cant be performed if there is no empty line before COMMIT
#Removing COMMIT line
sed -i '/COMMIT/d' /etc/sysconfig/iptables

#Adding empty line
echo >> /etc/sysconfig/iptables

#Adding COMMIT to the end of file
echo "COMMIT" >> /etc/sysconfig/iptables

#Adding rules:
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

#Saving rules:
iptables-save >> /etc/sysconfig/iptables

#Restart iptables service
service iptables restart

