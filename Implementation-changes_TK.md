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
		    /*  SINGLE DEMO STREAM
				picoquic_demo_stream_desc_t * stream_desc_f = (picoquic_demo_stream_desc_t*)malloc(sizeof(picoquic_demo_stream_desc_t));

				stream_desc_f->stream_id = 4; //stream id
				stream_desc_f->previous_stream_id = PICOQUIC_DEMO_STREAM_ID_INITIAL;
				stream_desc_f->doc_name = "/";
				stream_desc_f->f_name = "test.txt";
				stream_desc_f->repeat_count = 0;
				stream_desc_f->is_binary = 0; //txt file
				stream_desc_f->post_size = 102400; //payload bytes
			*/
	3.2 the scenario has now a variable length (update democlient::picoquic_application_scenario_client_initialize_context(-) to use the input parameter nb_demo_streams)
	"Why is the stream_id a multiplication of 4?"
	-> (indication of stream-initiator) because with least significant bit=0 the stream is client-initiated and with =1 it is server-initiated
		&& (indication of stream type) with the second least significant bit=0 it is bidirectional and with =1 it is unidirectional
		https://quicwg.org/base-drafts/draft-ietf-quic-transport.html#rfc.section.2.1
		
	3.3 TODO: timing of streams