../../picoquicdemo -c ../../certs/cert.pem -k ../../certs/key.pem -L -l log_server.txt -p 6121 -1 > stdoutput_server.txt
mv log_server.txt results/log_server_AMR_$(date +%Y%m%d-%H%M).txt
mv stdoutput_server.txt results/log_server-std_AMR_$(date +%Y%m%d-%H%M).txt
./process_results_on_server.sh WiFi_Xms_X-eph