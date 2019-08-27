1. Install picotls
	1.1 git clone https://github.com/h2o/picotls.git
	1.2 cd picotls
	1.3 git submodule init
	1.4 git submodule update
	1.5 cmake .
	1.6 make
	1.7 sudo apt-get install faketime libscope-guard-perl libtest-tcp-perl
	1.8 make check
	
2. Install picoquic
	2.1 git clone https://github.com/private-octopus/picoquic.git
	2.2 cd picoquic
	2.3 cmake .
	2.4 make
	2.5 for usage description: ./picoquicdemo -h
	2.5 start server: ./picoquicdemo -p 6121
		2.5.1 ./picoquicdemo -L -l log_server.txt -p 6121 -1 
				(provides extended log-file and closes after 1 connection)
	2.6 start client: ./picoquicdemo 127.0.0.1 6121
		2.6.1 GET REQUEST
				./picoquicdemo -L -l log_client.txt 127.0.0.1 6121 0:/104857600; 
				(provides extended log-file and downloads a file with 104857600 bytes = 1MB on stream 0)
		2.6.2 POST COMMAND
				./picoquicdemo -L -l log_client.txt 127.0.0.1 6121 0:b:test:104857600;
				(sends a 1MB file as binary named "test" to the server on stream 0)
	
	
	
	
### Usage of picoquicdemo:
PicoQUIC demo client and server
Usage: picoquicdemo <options> [server_name [port [scenario]]]
  For the client mode, specify server_name and port.
  For the server mode, use -p to specify the port.
Options:
  -c file               cert file (default: certs/cert.pem)
  -e if                 Send on interface (default: -1)
                           -1: receiving interface
                            0: routing lookup
                            n: ifindex
  -f migration_mode     Force client to migrate to start migration:
                        -f 1  test NAT rebinding,
                        -f 2  test CNXID renewal,
                        -f 3  test migration to new address.
  -h                    This help message
  -i <src mask value>   Connection ID modification: (src & ~mask) || val
                        Implies unconditional server cnx_id xmit
                          where <src> is int:
                            0: picoquic_cnx_id_random
                            1: picoquic_cnx_id_remote (client)
                            2: same as 0, plus encryption of unmasked data
                            3: same as 0, plus encryption of all data
                        val and mask must be hex strings of same length, 4 to 18
  -k file               key file (default: certs/key.pem)
  -K file               ESNI private key file (default: don't use ESNI)
  -E file               ESNI RR file (default: don't use ESNI)
  -l file               Log file, Log to stdout if file = "n". No logging if absent.
  -L                    Log all packets. If absent, log stops after 100 packets.
  -p port               server port (default: 4443)
  -m mtu_max            Largest mtu value that can be tried for discovery
  -n sni                sni (default: server name)
  -a alpn               alpn (default function of version)
  -r                    Do Reset Request
  -s <64b 64b>          Reset seed
  -t file               root trust file
  -u nb                 trigger key update after receiving <nb> packets on client
  -v version            Version proposed by client, e.g. -v ff000012
  -z                    Set TLS zero share behavior on client, to force HRR.
  -1                    Once: close the server after processing 1 connection.
  -S solution_dir       Set the path to the source files to find the default files
  -I length             Length of CNX_ID used by the client, default=8
  -g cc_log_dir         log congestion control traces in specified dir
  -D                    no disk: do not save received files on disk.

The scenario argument specifies the set of files that should be retrieved,
and their order. The syntax is:
  *{[<stream_id>':'[<previous_stream>':'[<format>:]]]path;}
where:
  <stream_id>:          The numeric ID of the QUIC stream, e.g. 4. By default, the
                        next stream in the logical QUIC order, 0, 4, 8, etc.  
  <previous_stream>:    The numeric ID of the previous stream. The GET command will
                        be issued after that stream's transfer finishes. By default,
                        previous stream in this scenario.
  <format>:             Whether the received file should be written to disc as
                        binary(b) or text(t). Defaults to text.
  <path>:               The name of the document that should be retrieved
If no scenario is specified, the client executes the default scenario.
