date=$(date +%Y%m%d-%H%M%S_)
dirname=$date$1
path=./results/
echo 'Saved in ' $path/$dirname
mkdir $path/$dirname
mv $path/log_client_*.txt $path/$dirname
mv $path/log_client-std*.txt $path/$dirname
# Client: Time t, cwin, bytes-in-flight , nb_ret, rtt_min, current_rtt, send_time, latest msg number, current_ackdelay, srtt, rtt_var, max_ackdelay, state
grep bytes-in-flight $path/$dirname/log_client_*.txt | awk '{print $3, $5, $7, $9, $11, $13, $15, $17, $19, $21, $23, $25, $27}' > $path/$dirname/firstKPIs
# Reception time in sec, stream ID, message number
grep -E "(Stream.*length 100)" $path/$dirname/log_client_*.txt | awk '{print $2, $5, $19}' > $path/$dirname/clientStreamOutput