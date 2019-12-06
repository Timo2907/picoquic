date=$(date +%Y%m%d-%H%M%S_)
dirname=$date$1
path=./results/
echo 'Saved in ' $path/$dirname
mkdir $path/$dirname
mv $path/log_server_*.txt $path/$dirname
mv $path/log_server-std*.txt $path/$dirname
# Server: 
grep -E "(Stream.*length 100|Server CB.*100 bytes)" $path/$dirname/log_server_*.txt > $path/$dirname/serverCallbackInfo
# Reception Time in sec, Stream ID, offset, payload in bytes, msg number
grep -E "(Stream.*length 100)" $path/$dirname/log_server_*.txt | awk '{print $2, $5, $8, $11, $19, $23}' > $path/$dirname/serverStreamOutput
# Reception Time in sec, Stream ID, payload in bytes, msg number
grep -E "(Server CB.*100 bytes)" $path/$dirname/log_server_*.txt | awk '{print $2, $7, $9, $15, $19}' > $path/$dirname/serverAppOutput