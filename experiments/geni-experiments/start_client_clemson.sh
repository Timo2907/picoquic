echo "Start QUIC Client on GENI Clemson"
../../picoquicdemo -c ../../certs/cert.pem -k ../../certs/key.pem -L -l log_client.txt 185.104.141.28 6121 > stdoutput_client.txt
mv log_client.txt results/log_client_clemson_$(date +%Y%m%d-%H%M).txt
mv stdoutput_client.txt results/log_client-std_clemson_$(date +%Y%m%d-%H%M).txt