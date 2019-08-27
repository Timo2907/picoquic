./picoquicdemo -L -l log_client.txt 127.0.0.1 6121
mv log_client.txt logfiles/log_client_$(date +%Y%m%d-%H%M).txt
#kill $(ps -ef | grep ./picoquicdemo | awk '{print $2}' | head -1)