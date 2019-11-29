
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
				check if (picoquic_current_time() - last_sending_time <= time_between_msgs)
						+ update last_sending_time + counter the clock skew of picoquic() !! (drifts about 0-70 us per msg, under 0.1ms granularity before, now drifts 1ms for 1000 msgs)
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

7. Changed the frame behavior: No ACK of ACK -> Server ACKs the client's packet, the client does not need to ACK the finished stream
						-> still, every 9th segment, there is an ACK from the Client?!
						BUT when there is no ACK of ACK, the stream limit will be reached (=Stream 2052) -> frame_type_streams_blocked_bidir packet for every stream after that
						[Methods: sender::prepare_packet_ready()->frame::prepare_one_blocked_frame()->prepare_stream_blocked_frame()->frame_type_streams_blocked_bidir]
						=> see 9. (too many open streams?!)
						
8. Method for standard application streams: Streams started one after another, concatenated -> normal streaming behavior (picoquic_demo_client_start_streams)
   Method for additional streams: An additional stream is started, independently from every other stream (picoquic_demo_client_open_stream)
   
	8.1 streams are closed when a new msg is available, since the data on the last stream is outdated now
		-> check for last stream context, if it is still open
		OR
		streams are closed when the stream is finished in time, so there is the ACK from the server and the stream is already finished and can be closed before a new msg is generated
		=> only RESET_STREAM when stream is cancelled, no STOP_SENDING since only a receiver can send that
		=> only RESET_STREAM after deadline, not when its ACKed! This reduces the overhead, since the reset_stream frame is send together with the next data stream in one packet!!
		=> STREAM is not fin'ed, since it is always closed with a reset and a reset does not work for a fin'ed stream
   
9. Changed the flow control variables (blocked streams by client or max streams bidir from server) -> application can handle more, therefore the flow control is set higher

10. Non-ephemeral application: All over one stream -> parameter "ephemeral" set in client for local knowledge what application is used 
													and parameter "fin_used" in cnx set to know when non-ephemeral application has started
	10.1 send only a fin at the end of a POST when is is the very last generated msg (client_sc_nb_counter >= client_sc_nb), else there should not be a stream fin at all
	10.2 opem the same stream for pushing Data, without counting the stream number up + reset the post_sent parameter (since a new post is started)
	10.3 set fin=0 and is_active for stream also as 0 (instead of naturally (!fin) for instant data sending)
	
11. inserted the msg number into the data stream frame (as a 2 bytes/0x00-0xff) -> switched from hex to decimal for better post-processing
			if(available > 3) //we have to check if we have enough space in our payload for the msg number (=> max msg number currently is 4,294,967,295 = 32-bit unsigned int = 2^32-1)
            {
                buffer[0] = (msg >> 24);
                buffer[1] = (msg >> 16);
                buffer[2] = (msg >> 8);
                buffer[3] = msg;
                memset(buffer+sizeof(msg), 0x00, available-sizeof(msg));
			} else {
                memset(buffer, 0x00, available);
            }
			SERVER SIDE: unsigned int msg_no = bytes[3] + (bytes[2] << 8) + (bytes[1] << 16) + (bytes[0] << 24);



[--------------------------------------]
????. Sender sends a 1440 byte packet (1 ping, 1410 padding) after a retransmit -> probe packet after retransmit
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
 => "picoquic_prepare_mtu_probe() 1. when triggered? -> after retransmission (NOT ANYMORE!)
								  2. What does it do? -> testing the path with a max sized packet
TODO: Comment the MTU usage out?

DONE: Server should only provide ACKs and no other packets! (server answers with 260 bytes packet instead of simple acks?!)
		-> demoserver.c [if (stream_ctx->method == 1)] -> comment out the response to a POST	
		-> it is used as ACK?!		
		
DONE: ACKs should not be sent by the client?! 
		-> DONE: There should only be a 100ms wait when the application scenario is started!








from one-hour run on maki server in logfiles -> log_server/client_20190829-2219
 ----------------:PICOQUICDEMO::quic_server()::54c858b5579b3946: 3606.593701 : Closed. Retrans= 145820, spurious= 20873, max sp gap = 13, max sp delay = 350459
	=> what are they saying? -> stats for spurios (unnecessary) retransmissions -> OUTDATED
	=> these stats are not there in client (everything =0)
 ----------------:PICOQUICDEMO::quic_server()-RECEPTION_ZERO::bytes= 0, after 10588 us (wait for 10506 us)
	=> what does this mean? -> waiting time at the socket (specified by "delta_t" variable)