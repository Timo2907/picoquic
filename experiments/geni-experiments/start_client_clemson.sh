echo "Start QUIC Client on GENI Clemson"
../../picoquicdemo -c ../../certs/cert.pem -k ../../certs/key.pem -L -l log_client.txt -D -X $1 $2 $3 $4 10.10.1.2 6121 > stdoutput_client.txt
mv log_client.txt results/log_client_clemson_$(date +%Y%m%d-%H%M).txt
mv stdoutput_client.txt results/log_client-std_clemson_$(date +%Y%m%d-%H%M).txt
./process_results_on_client.sh