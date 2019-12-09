echo "Start QUIC Client over WiFi with $1 $2 $3 $4"
../../picoquicdemo -c ../../certs/cert.pem -k ../../certs/key.pem -L -l log_client.txt -D -X $1 $2 $3 $4 185.104.141.28 6121 > stdoutput_client.txt
./process_results_on_client.sh WiFi-$1msgs-$2-$3ms-$4-ephemeral