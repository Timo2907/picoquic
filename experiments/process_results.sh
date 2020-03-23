dirname=$(date +%Y%m%d-%H%M)
if [ $# -eq 1 ]
then
  dirname=$dirname-$1
fi
mkdir $dirname
mv client.pcap $dirname
mv server.pcap $dirname
mv *.log $dirname
mv nohup.out $dirname
mv stdoutput_client.txt $dirname
mv stdoutput_server.txt $dirname
mv qlen*.txt $dirname
mv queue.txt $dirname
mv log_client.txt $dirname
mv log_server.txt $dirname
# Client: Time t, cwin, bytes-in-flight , nb_ret, rtt_min, current_rtt, send_time, latest msg number, current_ackdelay, srtt, rtt_var, max_ackdelay, state
grep bytes-in-flight $dirname/log_client.txt | awk '{print $3, $5, $7, $9, $11, $13, $15, $17, $19, $21, $23, $25, $27}' > $dirname/firstKPIs
# Time in sec, stream ID, message number, age when sent, generation time, sending time 
grep -E "(Stream.*length 100)" $dirname/log_client.txt | awk '{print $2, $5, $19, $22, $24, $26}' > $dirname/clientStreamOutput
# Server: 
grep -E "(Stream.*length 100|Server CB.*100 bytes)" $dirname/log_server.txt > $dirname/serverCallbackInfo
# Reception Time in sec, Stream ID, offset, payload in bytes, msg number, age when received, generation time, reception time
grep -E "(Stream.*length 100)" $dirname/log_server.txt | awk '{print $2, $5, $8, $11, $19, $22, $24, $26}' > $dirname/serverStreamOutput
# Reception Time in sec, Stream ID, payload in bytes, msg number, age when consumed, generation time, consumption time
grep -E "(Server CB.*100 bytes)" $dirname/log_server.txt | awk '{print $2, $7, $9, $15, $18, $20, $22}' > $dirname/serverAppOutput