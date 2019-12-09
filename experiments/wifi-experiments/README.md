#Starting the WiFi experiment
0. [@MAKI] screen -r tcpdump
0.1 [@MAKI] sudo tcpdump -w client.pcap -i enp4s0f0 src 185.104.141.28 or dst 185.104.141.28 and port 6121 // 6122
0.2 [@AMR] screen -r tcpdump
0.3 [@AMR] sudo tcpdump -w server.pcap -i any src 192.168.178.20 or dst 192.168.178.20 and port 6121 // 6122

1. [@AMR] screen -r quiccserver
1.1 [@AMR] sudo ./start_server_AMR.sh
2. [@MAKI] screen -r quicclient
2.1 [@MAKI] sudo ./start_client_MAKI.sh