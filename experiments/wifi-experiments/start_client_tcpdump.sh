echo "Start tcpdump on MAKI Server"
screen -S tcpdump -X exec tcpdump -i enp4s0f0 src 185.104.141.28 > client_tcpdump