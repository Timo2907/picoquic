#!/bin/bash
########################### Crosstraffic Experiments ################################
for i in {1..$1}
do
    echo "Welcome $i out of $1 times"

    experiment='crosstraffic-non-ephemeral'
    mn --clean
    echo "##### CLEANED UP MININET #####"
    start=`date +%s`
    echo "Start time:" $(date) "of experiment" $experiment
    nohup python $experiment.py
    echo "Sleep for 5 seconds"
    sleep 5
    chmod +777 nohup.out
    pid=$(ps -ef | grep picoquicdemo | grep client | grep -v grep | awk '{print $2}')
    echo "Process ID is " $pid
    echo "Waiting for the experiment to finish..."
    tail --pid=$pid -f /dev/null
    sleep 5
    echo "##### EXPERIMENT RUN ENDED #####"
    end=`date +%s`
    runtime=$((end-start))
    printf 'Execution time: %dh:%dm:%ds\n' $(($runtime/3600)) $(($runtime%3600/60)) $(($runtime%60))
    pkill python
    mn --clean
    ./process_results.sh $experiment
    echo "##### PROCESSED RESULTS - EXECUTION DONE #####"

    experiment='crosstraffic-light-ephemeral'
    mn --clean
    echo "##### CLEANED UP MININET #####"
    start=`date +%s`
    echo "Start time:" $(date) "of experiment" $experiment
    nohup python $experiment.py
    echo "Sleep for 5 seconds"
    sleep 5
    chmod +777 nohup.out
    pid=$(ps -ef | grep picoquicdemo | grep client | grep -v grep | awk '{print $2}')
    echo "Process ID is " $pid
    echo "Waiting for the experiment to finish..."
    tail --pid=$pid -f /dev/null
    sleep 5
    echo "##### EXPERIMENT RUN ENDED #####"
    end=`date +%s`
    runtime=$((end-start))
    printf 'Execution time: %dh:%dm:%ds\n' $(($runtime/3600)) $(($runtime%3600/60)) $(($runtime%60))
    pkill python
    mn --clean
    ./process_results.sh $experiment
    echo "##### PROCESSED RESULTS - EXECUTION DONE #####"

    experiment='crosstraffic-full-ephemeral'
    mn --clean
    echo "##### CLEANED UP MININET #####"
    start=`date +%s`
    echo "Start time:" $(date) "of experiment" $experiment
    nohup python $experiment.py
    echo "Sleep for 5 seconds"
    sleep 5
    chmod +777 nohup.out
    pid=$(ps -ef | grep picoquicdemo | grep client | grep -v grep | awk '{print $2}')
    echo "Process ID is " $pid
    echo "Waiting for the experiment to finish..."
    tail --pid=$pid -f /dev/null
    sleep 5
    echo "##### EXPERIMENT RUN ENDED #####"
    end=`date +%s`
    runtime=$((end-start))
    printf 'Execution time: %dh:%dm:%ds\n' $(($runtime/3600)) $(($runtime%3600/60)) $(($runtime%60))
    pkill python
    mn --clean
    ./process_results.sh $experiment
    echo "##### PROCESSED RESULTS - EXECUTION DONE #####"

    echo "##### COMPLETED EXPERIMENT #####"
done
echo "##### COMPLETED EXPERIMENT $i TIMES #####"