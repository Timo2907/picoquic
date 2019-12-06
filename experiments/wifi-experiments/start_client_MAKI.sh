echo "Start QUIC Client on MAKI Server"
../../picoquicdemo -c ../../certs/cert.pem -k ../../certs/key.pem -L -l log_client.txt -D -X $1 $2 $3 $4 185.104.141.28 6121 > stdoutput_client.txt
mv log_client.txt results/log_client_MAKI_$(date +%Y%m%d-%H%M)_$1_$2_$3_$4.txt
mv stdoutput_client.txt results/log_client-std_MAKI_$(date +%Y%m%d-%H%M)_$1_$2_$3_$4.txt