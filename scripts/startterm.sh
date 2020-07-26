# here is where you start all the services you need

# removing where I usually put my logs
rm /root/vncstatus.log
touch /root/vncstatus.log

echo "setup started"

# kill all services, so this functions as a restart script.
echo "killing services..."
/usr/share/tomcat8/bin/shutdown.sh
vncserver -kill :1
vncserver -kill :2

# remove temp files created by vncserver, incase of an unexpected shutdown
rm -rf /tmp/.X1*

# kill all services running.
pkill -9 Xvnc
pkill -9 guacd
pkill -9 sshd
echo "done."

# hacky, but eh
sleep 1

echo "setup firewall..."
iptables-restore < /root/iptables.rules
ip6tables-restore < /root/iptables.rules
echo "done." >> /root/vncstatus.log
echo "starting services..."
vncserver
/sbin/sshd -f /root/sshd_config
/usr/share/tomcat8/bin/startup.sh
guacd start
echo "starting irc..."
cd /root/qwebirc
python2 run.py -p 8000

# you can add any other services you want to run here, modify as you like

echo "setup finished"
