dirname=$(date +%Y%m%d-%H%M)
if [ $# -eq 1 ]
then
  dirname=$dirname-$1
fi
mkdir $dirname
mv client.pcap $dirname
mv server.pcap $dirname
mv nohup.out $dirname
mv stdoutput_client.txt $dirname
mv stdoutput_server.txt $dirname
mv qlen*.txt $dirname
mv queue.txt $dirname
mv log_client.txt $dirname
mv log_server.txt $dirname
# Client: Time t, cwin, bytes-in-flight , nb_ret, rtt_min, current_rtt, send_time, reception_time, current_ackdelay, srtt, rtt_var, max_ackdelay, state
grep bytes-in-flight $dirname/log_client.txt | awk '{print $3, $5, $7, $9, $11, $13, $15, $17, $19, $21, $23, $25, $27}' > $dirname/firstKPIs