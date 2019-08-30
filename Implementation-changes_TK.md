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
		
	3.3 timing of streams
		3.3.1 current_time is in usec:
				double duration_usec = (double)(current_time - picoquic_get_cnx_start_time(cnx_client)); (divided by 1000000.0 for seconds)
		3.3.2 timing_between_msgs as parameter
				before sending the next msg in the Event Loop:
				check if (last_sending_time + time_between_msgs) < picoquic_current_time()
						+ update last_sending_time after "sendto()" was performed (= the msg went out through the socket)
						
4. Implement the number of max retransmission as a macro definition "#define PICOQUIC_MAX_RETRANSMISSIONS 20" in picoquic.h
	[in sender.c: if (cnx->pkt_ctx[pc].nb_retransmit > 4)]

TODO: Server should only provide ACKs and no other packets! (server answers with 260 bytes packet instead of simple acks?!)
		-> demoserver.c [if (stream_ctx->method == 1)] -> comment out the response to a POST
		
		
TODO: ACKs should not be sent by the client?! 
		-> There should only be a 100ms wait when the application scenario is started!
		
TODO: Stream should start after 100ms, even if the last one is not finished
		-> e.g. additional parameter in demo_stream (named "finished")? 
				+ skip those who are finished until reaching an unfinished one
				
TODO: retransmissions should also not be waiting for 100 ms!








from one-hour run on maki server in logfiles -> log_server/client_20190829-2219
TODO: ----------------:PICOQUICDEMO::quic_server()::54c858b5579b3946: 3606.593701 : Closed. Retrans= 145820, spurious= 20873, max sp gap = 13, max sp delay = 350459
	=> what are they saying?
	=> these stats are not there in client (everything =0)
TODO: ----------------:PICOQUICDEMO::quic_server()-RECEPTION_ZERO::bytes= 0, after 10588 us (wait for 10506 us)
	=> what does this mean?