#!/bin/bash
echo "Start QUIC Client Experiment for WiFi"

    echo "100 ms Runs"

    sudo ./start_client_wifi.sh 6000 100 100 N
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 100 L
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 100 F
    sleep 60

    echo "200 ms Runs"
    sudo ./start_client_wifi.sh 6000 100 200 N
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 200 L
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 200 F
    sleep 60    
    
    echo "500 ms Runs"
    sudo ./start_client_wifi.sh 6000 100 500 N
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 500 L
    sleep 60
    sudo ./start_client_wifi.sh 6000 100 500 F
    sleep 60
    
echo "COMPLETED"