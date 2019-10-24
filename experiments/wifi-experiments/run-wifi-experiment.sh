########################### Experiment ################################
experiment='network-wifi'
echo "##### START EXPERIMENT #####"
start=`date +%s`
echo "Start time:" $(date) "of experiment" $experiment

#TODO START EXPERIMENT HERE
#1. ssh into SERVER@AMR
#1.1 start SERVER@AMR -> sudo ./start_server IN SCREEN!
#1.2 log out of ssh?!
#2. start CLIENT@MAKI -> sudo ./start_client IN SCREEN!

echo "Sleep for 5 seconds"
sleep 5
pid=$(ps -ef | grep picoquicdemo | grep client | grep -v grep | awk '{print $2}') #check/test this - should work!
echo "Process ID is " $pid
echo "Waiting for the experiment to finish..."
tail --pid=$pid -f /dev/null
sleep 5
echo "##### EXPERIMENT RUN ENDED #####"
end=`date +%s`
runtime=$((end-start))
printf 'Execution time: %dh:%dm:%ds\n' $(($runtime/3600)) $(($runtime%3600/60)) $(($runtime%60))
./process_wifi_results.sh
echo "##### PROCESSED RESULTS - EXECUTION DONE #####"