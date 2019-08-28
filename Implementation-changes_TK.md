SERVER DEBUG:
gdb --args ./picoquicdemo -L -l log_server.txt -p 6121 -1
(+ run)

CLIENT DEBUG:
gdb --args ./picoquicdemo -L -l log_client.txt 127.0.0.1 6121
(+ run)

# Implementation steps
0. Set up scripts for starting client/server and moving the log files

1. Comment out the default scenario/parsing of the testing scenario argument
2. Build new function for setting clients' context parameters
	2.0 client_sc_nb = 10 (number of streams)
	2.1 democlient.h: int picoquic_application_scenario_client_initialize_context(picoquic_demo_callback_ctx_t* ctx, size_t nb_demo_streams, char const * alpn, int no_disk)
	2.2 democlient.c: (implementation)
	(!) "demo_stream" value in "picoquic_demo_callback_ctx_t ctx" not set.

3. (change picoquic_demo_client_start_streams() in democlient.c)
3. Change picoquic_application_scenario_client_initialize_context()
	3.1 set demo_streams in ctx: build new demo_stream_description and fill in the values we want (post 100 bytes, stream_id=1, is_binary=0)
	3.2 TODO: variable stream length
	3.3 TODO: timing of streams