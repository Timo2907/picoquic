echo "Start QUIC Client on GENI UMass"
../../picoquicdemo -c ../../certs/cert.pem -k ../../certs/key.pem -L -l log_server.txt -p 6121 -1 > stdoutput_server.txt
mv log_server.txt results/log_server_umass_$(date +%Y%m%d-%H%M).txt
mv stdoutput_server.txt results/log_server-std_umass_$(date +%Y%m%d-%H%M).txt
./process_results_on_server.sh GENI_Xms_Xmsgs