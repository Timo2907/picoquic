echo "Start QUIC Server Experiment for ETHERNET"
for i in {1..4}
do
    echo "Welcome $i out of 4 times"
    sudo ./start_server_eth.sh
    sleep 5
    sudo ./start_server_eth.sh
    sleep 5
    sudo ./start_server_eth.sh
    sleep 5
done

echo "COMPLETET after $i times"