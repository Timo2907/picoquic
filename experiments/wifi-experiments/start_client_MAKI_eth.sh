echo "Start QUIC Client on MAKI Server"
../../picoquicdemo -c ../../certs/cert.pem -k ../../certs/key.pem -L -l log_client.txt 185.104.141.28 6122 > stdoutput_client.txt
mv log_client.txt results/log_client_MAKI_$(date +%Y%m%d-%H%M).txt
mv stdoutput_client.txt results/log_client-std_MAKI_$(date +%Y%m%d-%H%M).txt