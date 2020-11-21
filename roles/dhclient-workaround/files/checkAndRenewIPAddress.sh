ifconfig eth0 | grep -Po '(?<=inet )[\d.]+' &> /dev/null
if [ $? == 0 ];
then
    sleep 1
else
    logger Renewing eth0 IP Address
    sudo dhclient -r eth0 && sudo dhclient eth0
fi