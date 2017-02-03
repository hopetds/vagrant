---
#Vagrant report
-----------------

##Report Table

| |Issue|How to find|Time to find|How to fix|Time to fix|
| :---: | ---|-----------------| ------------| ---------- | ----------- | 
| **1** | Tomcat is unavailable |```$cd /opt/apache/tomcat/7.0.62/conf```<br>```$cat server.xml | grep port```<br>```$netstat -ntlp```<br>```$curl -IL 192.168.56.10:8080```<br>```$service tomcat status```| **5** mins |```$sed -i '/export/d' /home/tomcat/.bashrc```<br>```$chown -R tomcat:tomcat /opt/apache/tomcat/current/logs```<br> ```$alternatives --set java /opt/oracle/java/x64/jdk1.7.0_79/bin/java```<br>```$service tomcat restart```| **15** mins | 
| **2** | Connecting to Tomcat failed |1. View httpd error_log<br>2. View mod_jk log|  **5** min | 1.Edit worker.properties config **tomcat.worker > tomcat-worker**<br>2.Edit vhost.conf **tomcat.worker>tomcat-worker**|**10** mins|
| **3** | Redirecting to mntlab |1. View httpd access log<br>2. Mntlab is not defined in vhost.conf<br>3. Mntlab is in redirect section of the wrong virtual host |**10** mins|1.Edit vhost.conf mntlab:80>*:80<br>2.Edit httpd.conf - comment VirtualHost lines| **5** mins |
| **4** | Tomcat autostart fail | 1.Service tomcat enable<br>2.Restart server<br>3.```$netstat -ntlp``` - no tomcat processes  |  **10** mins | ```$chkconfig``` - tomcat is in the list, but not configured for level 3 and 5<br>```$chkconfig tomcat on --level 35```<br>```$reboot```<br>```$netstat -ntlp``` -ok<br>```$curl -IL 192.168.56.10:8080``` -200 ok| **15** mins |
| **5** | ```$service iptables status```- empty| 1.Allow connections to 22 and 80 port<br>2.```$iptables-save >>/etc/sysconfig/iptables``` -permission denied<br>3.```$service iptables stop``` -ok<br>4.```$iptables-save >>/etc/sysconfig/iptables``` -permission denied|  **20** mins | 1.```$lsattr /etc/sysconfig/iptables``` -returns iptables marked with "i"<br>2.```chattr -i /etc/sysconfig/iptables```<br>3.```$service iptables restart```<br>4.Edit iptables: add empty line before "COMMIT" - now can restore saved rules| **30** mins |
| **6** | No Tomcat Logs in /var/logs | is related to **issue 1**  |  5 min |```$ln -s /opt/apache/tomcat/7.0.62/logs /var/log/tomcat```| **2** mins|

--------------
#Manual fix steps
--------------

1. Since mntlab virtual machine imitates web-server - lets check availability of the virtual machine over the network:
 
  ```$ping 192.168.56.10```

2. Ping is fine, lets check if the httpd is working:

  ```$curl -IL 192.168.56.10``` 

 Output will return a HTTP/1.1 503 Service Temporary Unavailable
 
 Having a 503 error usually means the proxied page/service is not available. Since we are using tomcat that means tomcat is either not responding to httpd (timeout?) or not even available (down? crashed?). Httpd seems working. Time to check tomcat.

3. Tomcat availability

  ```$vagrant ssh```
  
  ```$service httpd status``` -running
  
  ```$service tomcat status``` -running
  
  ```$netstat -ntlp``` - httpd is listening 80 port. 
  
  !NOTE that theres no listening on 8080(default tomcat port)!

   Lets check tomcat server.xml
  ```$yum info tomcat``` - tomcat isnt installed using vim
  
  ```$find / -name "server.xml"```
  
  ```$cd /opt/apache/tomcat```
  
  ```$ls```  - 2 folders. 7.0.62 and linked current.
  
  ```$cd /opt/apache/tomcat/7.0.62/conf```
  
  ```$cat server.xml | grep port``` - output is saying that tomcat is working on default port 8080. So lets check if it is available
  ```$curl -IL 192.168.56.10:8080``` - output says coudln't connect to host. So, i must fix Tomcat now.

  Fixing Tomcat:
   	$service tomcatstatus - running

   	 Java Check:
   	 	
   	 	$java -version - output bad ELF interpreter - show my DEFAULT java version, which program will use unless we tell them directly not to.

   	 Lets check catalina.sh file to find out if theres a defined java version for out tomcat. Move to tomcat/bin folder and run

   	 	$cat catalina.sh | grep JAVA_HOME

   	 	 java seems to be using default pathes.

   	 Tomcat could crash or stop working. I can try to restart it, but first - lets check tomcat logs:

   	 I didnt find any logs seemed to be related to tomcat in /var/log/
   	 Checking the default log path in catalina.sh

   	 	$cat catalina.sh | grep log 

   	 Output says that catalina out is in default location, which is /logs/catalina.out

   	 	$/opt/apache/tomcat/7.0.62/logs -empty!
   	    $find / -name catalina.out - no result
  	 	$cat /etc/init.d/tomcat | grep .sh 

  	 Returns startup.sh and shutdown.sh, both located in /opt/apache/tomcat//current/bin/. And !note - both of them run with su - tomcat. 

   	 	$su - tomcat -c env

   	 Finally. Tomcat env says that it uses 2 specific variables: JAVA_HOME=/tmp CATALINA_HOME=/tmp. If its not in catalina.sh - then it must be in basic tomcat files /home/tomcat
   	 	
   	 	$cat /home/tomcat/.bashrc

   	 Here it is. 2 strings: export CATALINA_HOME=/tmp and export JAVA_HOME=/tmp
   	 
   	 Folder /tmp contains no tomcat related files or logs.

   	 	$sed -i '/export/d' /home/tomcat/.bashrc

   	 So, deleting this 2 strings will bring us to tomcat startup.sh running well. Now we need to restart tomcat service to reapply new tomcat-user env rules.

   	 	$service tomcat restart
     
     Error occured: permission denied on /opt/apache/tomcat/current/logs/catalina.out
     
   	 	$ls -la /opt/apache/tomcat/7.0.62
     
     Shows that permissions for logs folder are control by root.Since tomcat is running by tomcat user, we do the following:
   	 
        $chown -R tomcat:tomcat /opt/apache/tomcat/current/logs
   	 
     Create a link in /var/log/
     
   	    $ln -s /opt/apache/tomcat/7.0.62/logs /var/log/tomcat
        
   	 Now we can restart tomcat service again
     
   	    $service tomcat restart
        
   	 Starting ok, but again error related to java. Lets run setclasspath.sh to check java 
   	    
        $./setclasspath.sh
    
    Neither the JAVA_HOME nor the JRE_HOME environment variable is defined
     
	At least one of these environment variable is needed to run this program
    
	    $alternatives --display java
           
    Shows that system is using i586 java for 32bit systems, but in according to:
	    $uname -m
           
    We are running x64bit system, so we need to switch java version:
    
		$alternatives--config java  
        
    Choose x64
	
    Now we can restart tomcat service again
    
	    $service tomcat restart
    OK
	
        $netstat -ntlp
    Listening ok
	
        $curl -IL 192.168.56.10:8080
        
    Perform well, now we have access to tomcat
    
		$curl -IL 192.168.56.10 - still 503, next step - check the httpd config:


4.HTTPd config:

    Move to httpd log files dir and run:

 		$tail -5 error_log
        
    Nothing critital, exept warn: No JkShmFile defined in httpd.conf. Using default
    Notice that mod_jk is configured. 
    >>Set loglevel debug in httpd.conf
        
        $tail -5 mod_jk
        
    Returs(tomcat.worker) connecting to tomcat failed
    
    Lets check httpd configs
    
        $cat /etc/httpd/conf.d/workers.properties
        
    Notice!  The name of the worker can contain only the alphanumeric characters [a-z][A-Z][0-9][_\-] and is case sensitive. Lets change worker name 
    Also, worker ip address is incorrect. Since tomcat is running on the same host -change ip to 192.168.56.10
    Changing tomcat.worker > tomcat-worker, check other conf files that might be related with previos worker name
    
        $cat /etc/httpd/conf.d/vhost.conf
        
    Changing tomcat.worker > tomcat-worker and replacing mntlab:80 with *:80. To provide any request to be redirected to tomcat.
    
        $cat /etc/httpd/conf/httpd
        
    We have a VirtualHost in httpd, that should be separeted in vhost.conf file, and an incorrect redirect to unexisting(as far as i know this server configuration host mntlab). So i will comment this block. 
   	   
        $service httpd restart
   	    $curl -IL 192.168.56.10
       
    Returning Tomcat default page.
   	
    Set loglevel warn in httpd.conf.
   	
        $service httpd restart
        
   	Check from host - working.

##Tomcat is now available through httpd.

5.Now, lets check iptables rules
	
    $iptables -L - empty
	
    Adding reqiered rules:
    
		$iptables -A INPUT -p tcp --dport 22 -j ACCEPT
		$iptables -A INPUT -p tcp --dport 80 -j ACCEPT
		$iptables-save
		$service iptables restart

		Error with Applying firewall rules: iptables-restore v1.4.7: no command specified Error occurred at line: 12
		
		$cat /etc/sysconfig/iptables

	Missing line before COMMIT -try to change - fail. Readonly file.
		
        $ls -la /etc/sysconfig/iptables
		$lsattr /etc/sysconfig/iptables
        
    Got "i" on iptables
		
        $chattr -i /etc/sysconfig/iptables
	
    Add an empty line after config before COMMIT -save
    
	    $vi /etc/sysconfig/iptables
		$iptables -A INPUT -p tcp --dport 22 -j ACCEPT
		$iptables -A INPUT -p tcp --dport 80 -j ACCEPT
		$iptables-save
		$service iptables restart - ok
        
##Tomcat is now available through httpd(80).

