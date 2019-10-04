./picoquicdemo -L -l log_client.txt 185.104.141.28 6121
mv log_client.txt logfiles/log_client_MAKI_$(date +%Y%m%d-%H%M).txt
#kill $(ps -ef | grep ./picoquicdemo | awk '{print $2}' | head -1)