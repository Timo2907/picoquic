
# first steps
- picoquic_demo_client_initialize_context (2.1) sets boarders to the application scenario (e.g. number of streams)
DONE: set alpn to picoquic_alpn_http_0_9 when invoking the client (default: hq-22 instead of h3-22 in picoquicdemo::quic_client())
DONE: look up PICOQUIC_MIN_SEGMENT_SIZE (is set to 256 in picoquic_internal.h)
-> maybe: PICOQUIC_DEMO_CLIENT_MAX_RECEIVE_BATCH has to be small (is 4 by default = max 5 receive loops)
DONE: try to run an application scenario with POST
DONE: (11.2.3) H09: Use this simple POST to send data to the Server???
	OR skip the format specific request e.g. by using picoquic_add_to_stream() without "_with_ctx" (maybe the server has to be changed as well then)



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
		3.3.3 TRY 1, 2
		3.3.4 Callback function triggered every x ms (tryout 3)
		3.3.5 PICOQUIC_DEMO_CLIENT_MAX_RECEIVE_BATCH value changed from 4 (= 5 packets in a row receiving) to 1 (= 2 packets in a row receiving)
		3.3.6 socket listening time has to be changed: delay_max value provides a upper bound on listening time when the client checks for new receptions over the sockets 
				(framework is not based on real-time scenarios like our use case)
						
4. Implement the number of max retransmission as a macro definition "#define PICOQUIC_MAX_RETRANSMISSIONS 20" in picoquic.h
	[in sender.c: if (cnx->pkt_ctx[pc].nb_retransmit > 4)]
	
5. Implemented a logging mechanism for retransmissions in logger.c 
	5.1 new logging function executed in sender.c when there is a need for a retransmission
	5.2 Updated the congestion logging: Now it provides the current_rtt value, not only the smoothed rtt, rtt_min and rttvar
	5.3 changed again: more values!
	5.4 set values in "should retransmit state" + log only if in actual retransmit case (only noticable afterwards)
		Divide the methods in the logger:
			1. method sets the values in connection context
			2. method logs the values in the logfile
					=> method 1 called whenever a "should retransmit" case is present
					=> method 2 called only when a retransmit is actually happening
	
6. Changed the RTO retransmission timer: 
				It was only normal RTO for the first retransmission.
				For 2nd retransmissions and following, it was set to be 1 second times the number of retransmissions minus 1 [= 1 sec * (nb_retransmit - 1)]
				6.1 just using the retransmit_timer does not work because the very first transmission does not have anything usable (handshake)
				6.2 try a workaroung [if nb_retransmit = 1 (use the 1sec*nb_retransmit-1), else (use retransmit_timer as set)]
				
			(rto = 	cnx->path[0]->retransmit_timer (when first retransmit)
					OR 1000000ull << (cnx->pkt_ctx[pc].nb_retransmit - 1)
				=> BAD with 1000000ull, since it is 1 sec for every retransmit try! (4 retransmits = 3 seconds waiting time!))




7. Sender sends a 1440 byte packet (1 ping, 1410 padding) after a retransmit -> probe packet after retransmit
e.g. 
28386300d599a8f9: Sending packet type: 6 (1rtt protected), S0,
28386300d599a8f9:     <c697584edabc064b>, Seq: 52 (52), Phi: 0,
28386300d599a8f9:     Prepared 1411 bytes
28386300d599a8f9:     ping, 1 bytes
28386300d599a8f9:     padding, 1410 bytes
=> look for "picoquic_frame_type_ping" in sender.c!!
MTU = Maximum Transmission Unit
 => "picoquic_prepare_mtu_probe() 1. when triggered? => after a loss is detected  
								  2. What does it do? => sending a probe packet over the path where the lost was detected (Congestion control things from standard?!)
								 

#NEXT STEPS:	

DONE: Sender sends a 1440 byte packet (1 ping, 1410 padding) after a retransmit -> probe packet after retransmit
e.g. 
28386300d599a8f9: Sending packet type: 6 (1rtt protected), S0,
28386300d599a8f9:     <c697584edabc064b>, Seq: 52 (52), Phi: 0,
28386300d599a8f9:     Prepared 1411 bytes
28386300d599a8f9:     ping, 1 bytes
28386300d599a8f9:     padding, 1410 bytes
=> look for "picoquic_frame_type_ping" in sender.c!!
MTU = Maximum Transmission Unit
 => "picoquic_prepare_mtu_probe() 1. when triggered?  2. What does it do?"
TODO: Comment the MTU usage out?

DONE: Server should only provide ACKs and no other packets! (server answers with 260 bytes packet instead of simple acks?!)
		-> demoserver.c [if (stream_ctx->method == 1)] -> comment out the response to a POST	
		-> it is used as ACK?!
		
		
TODO: ACKs should not be sent by the client?! 
		-> DONE: There should only be a 100ms wait when the application scenario is started!








from one-hour run on maki server in logfiles -> log_server/client_20190829-2219
TODO: ----------------:PICOQUICDEMO::quic_server()::54c858b5579b3946: 3606.593701 : Closed. Retrans= 145820, spurious= 20873, max sp gap = 13, max sp delay = 350459
	=> what are they saying?
	=> these stats are not there in client (everything =0)
TODO: ----------------:PICOQUICDEMO::quic_server()-RECEPTION_ZERO::bytes= 0, after 10588 us (wait for 10506 us)
	=> what does this mean?