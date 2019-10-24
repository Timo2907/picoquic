#Starting the WiFi experiment
0. [@MAKI] screen -r tcpdump
0.1 [@MAKI] sudo ./start_client_tcpdump.sh
1. [@AMR] screen -r quiccserver
1.1 [@AMR] sudo ./start_server_AMR.sh
2. [@MAKI] screen -r quicclient
2.1 [@MAKI] sudo ./start_client_MAKI.sh

3. [@MAKI] sudo ./process_wifi_results.sh