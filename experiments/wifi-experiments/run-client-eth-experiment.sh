echo "Start QUIC Client Experiment for ETHERNET"
for i in {1..4}
do
    echo "Welcome $i out of 4 times"
    sudo ./start_client_eth.sh 36000 100 100 N
    sleep 60
    sudo ./start_client_eth.sh 36000 100 100 L
    sleep 60
    sudo ./start_client_eth.sh 36000 100 100 F
    sleep 60
done

echo "COMPLETET after $i times"