DIRNAME=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/$1
echo 'DIRNAME' $DIRNAME
FIRSTKPIS=firstKPIs
CLIENT=log_client_MAKI_20191128-1510.txt
echo '$1' $1
echo 'firstKPIs' $FIRSTKPIS
echo 'client' $CLIENT
# Client: Time t, cwin, bytes-in-flight , nb_ret, rtt_min, current_rtt, send_time, reception_time, current_ackdelay, srtt, rtt_var, max_ackdelay, state
grep bytes-in-flight $1$CLIENT | awk '{print $3, $5, $7, $9, $11, $13, $15, $17, $19, $21, $23, $25, $27}' > $1$FIRSTKPIS
# Server: 
#grep -E "(Stream.*length 100|Server CB.*100 bytes)" $DIRNAME/log_server_*.txt > $DIRNAME/serverCallbackInfo
# Reception Time in sec, Stream ID, offset, payload in bytes, msg number
#grep -E "(Stream.*length 100)" $DIRNAME/log_server_*.txt | awk '{print $2, $5, $8, $11, $19}' > $DIRNAME/serverStreamOutput
# Reception Time in sec, Stream ID, payload in bytes, msg number
#grep -E "(Server CB.*100 bytes)" $DIRNAME/log_server_*.txt | awk '{print $2, $7, $9, $15}' > $DIRNAME/serverAppOutput