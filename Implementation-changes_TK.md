SERVER DEBUG:
gdb --args gdb --args ./picoquicdemo -L -l log_server.txt -p 6121 -1
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

3. change picoquic_demo_client_start_streams() in democlient.c


*Program received signal SIGSEGV, Segmentation fault.
*0x0000000000436e7e in picoquic_demo_client_start_streams (cnx=cnx@entry=0x6878e0, ctx=ctx@entry=0x7fffffffcf40,
*    fin_stream_id=fin_stream_id@entry=18446744073709551615) at /home/maki/picoquic/picohttp/democlient.c:380
*380             if (ctx->demo_stream[i].previous_stream_id == fin_stream_id) {