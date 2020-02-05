#!/bin/bash
echo "Start QUIC Client Experiment for WiFi"
for i in {1..5}
do
    echo "Welcome $i out of 5 times"

    sudo ./start_client_wifi.sh 6000 100 500 N
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 500 L
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 500 F
    sleep 60
done
echo "COMPLETED"