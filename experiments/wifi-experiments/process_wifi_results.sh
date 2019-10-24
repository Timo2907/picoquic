dirname=$(date +%Y%m%d-%H%M)
if [ $# -eq 1 ]
then
  dirname=$dirname-$1
fi
mkdir $dirname
mv log_client.txt $dirname
mv log_client-std.txt $dirname
# Client: Time t, cwin, bytes-in-flight , nb_ret, rtt_min, current_rtt, srtt, rtt_var, state
grep bytes-in-flight results/log_client_*.txt | awk '{print $3, $5, $7, $9, $11, $13, $15, $17, $21}' > results/$dirname/firstKPIsClient

#TODO: pull logfile from server -> only without password possible?!
#TODO: grep KPIs from server logfile - do the same KPIs make sense?
# Server: Time t, cwin, bytes-in-flight , nb_ret, rtt_min, current_rtt, srtt, rtt_var, state
#grep bytes-in-flight results/log_server_*.txt | awk '{print $3, $5, $7, $9, $11, $13, $15, $17, $21}' > results/$dirname/firstKPIsServer
