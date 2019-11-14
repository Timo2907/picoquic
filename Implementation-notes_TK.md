### General Notes
ctx = context ?
cnx = connection
sni = server name indication (when server name is used instead of IP address)
uint8_t buffer[1024] = char array with size of 1024
fd = he socket from picoquic_open_client_socket
picoquic.h explains the QUIC API => important points marked with (API)


Interesting parts marked with "TK:"

#GDB DEBUG
SERVER DEBUG:
gdb --args ./picoquicdemo -L -l log_server.txt -p 6121 -1
gdb --args ./picoquicdemo -L -l log_server.txt -p 6122 -1
(+ run)

CLIENT DEBUG:
gdb --args ./picoquicdemo -L -l log_client.txt 127.0.0.1 6121
gdb --args ./picoquicdemo -L -l log_client.txt 185.104.141.28 6122
(+ run)




## Client
picoquicdemo::main()
calls picoquicdemo::quic_client() with [server_name, server_port, sni, esni_rr_file, alpn, root_trust_file, proposed_version, force_zero_share, force_migration, nb_packets_before_update, mtu_max, F_log, client_cnx_id_length, client_scenario, cc_log_dir, no_disk, use_long_log]
		*SET SCENARIO BACKGROUND*
		1. calls democlient::demo_client_parse_scenario_desc, which sets [client_sc] and [client_sc_nb]
				1.1 calls democlient::demo_client_parse_stream_spaces(-) -> delete spaces
				1.2 calls democlient::demo_client_parse_stream_desc(-) -> stream_number, stream_format, stream_path, post_size => "number:b/t:path_to_docname:post_size;"
		2. calls democlient::picoquic_demo_client_initialize_context with [&callback_ctx (=context => not set before/empty here), client_sc (=demo_stream parameters), client_sc_nb (= number of demo_streams), alpn (=application_layer_protocol_negotiation => irrelevant?), no_disk (=> irrelevant?)]
				2.1 sets parameters in [callback_ctx]: demo_stream, nb_demo_stream, alpn, nodisk
		*OPEN UDP SOCKETS*
		3. calls picosocks::picoquic_get_server_adress(-) (no changes needed here?!)
		4. calls picosocks::picoquic_open_client_socket(-) (no changes needed here?!)
		*CREATE QUIC CONTEXT*
(API)	5. calls qclient = quicctx::picoquic_create (no changes needed here?!) with [8 (=number of connections), NULL, NULL, root_crt (= cert root file name => irrelevant?!), alpn, NULL, NULL, NULL, NULL, NULL, current_time, NULL, ticket_store_filename (=> irrelevant?!), NULL, 0 (= encryption key length => irrelevant?!)]
			subsequently update context (NOT WITHIN picoquic_create()!):
			5.1 set congestion algorithm with quicctx::picoquic_set_default_congestion_algorithm(-)
			5.2 load tokens with token_store::picoquic_load_tokens(-)
			5.3 set zero_share flag and set mtu_max (maximum transmission unit)
			5.4 set connection id length with quicctx::picoquic_set_default_connection_id_length(-)
			5.5 set logfile and logfile length with picoquic_internal::PICOQUIC_SET_LOG(-)
			5.6 set set key log file with picoquicdemo::picoquic_set_key_log_file_from_env(-)
			5.7 set congection control log with quicctx::picoquic_set_cc_log(-)
			5.8 set sni and root certificate

		*CREATE CLIENT CONNECTION*
(API)	6. calls quicctx::picoquic_create_cnx with [qclient, picoquic_null_connection_id (= initial CID), picoquic_null_connection_id (= "remote" CID), (struct sockaddr*)&server_address, current_time, proposed_version, sni, alpn, 1 (=client mode)]
			(within picoquic_create_cnx()!)
					6.1 calls quicctx::picoquic_create_path (no changes needed?!) with [cnx (=connection), start_time, NULL, addr_to (= peer address)]
					6.2 inserts connection in list / "by wake time"
					6.2 calls quicctx::picoquic_init_transport_parameters(-) or sets them directly
								6.2.1 sets parameters like max_stream_id, packet_size, idle_timeout, active_connection_id_limit, etc
					6.3 initializes local flow control variables and other parameters (e.g. padding)
					6.4 set callback function, callback context, and congestion algorithm to default + proposed_version
					6.5 calls quicctx::picoquic_create_random_cnx_id(-)
					6.6 set packet_context_array (size=3) to start values (for all three indexes in the array)
						[first_sack_item, highest_ack_sent, time_stamp_largest_received, send_sequence, nb_retransmit, other ack and time variables]
					6.7 set tls_stream array (size=4) to start values (for all four indexes) => crypto stream, not needed?
					6.8 calls pisosplay::picosplay_init_tree with parameters [picoquic_stream_node_compare (= compare function), picoquic_stream_node_create (= create function), picoquic_stream_node_delete (= delete function), picoquic_stream_node_value (= return value function)]
								-> "SPLAY TREE" => stream_tree in cnx: Used for handling streams => DO NOT CHANGE?! Only for efficient stream data manegement?!
(APTLS)				6.9 calls tls_api::picoquic_tlscontext_create with [quic (=qclient), cnx (= connection), current_time] (no changes needed here?!)
(APTLS)				6.10 calls tls_api::picoquic_setup_initial_traffic_keys with [cnx]
					6.11 calls quicctx::picoquic_register_path with [cnx, cnx->path]
			
(API)	7. calls quicctx::picoquic_set_callback with [cnx_client, picoquic_demo_client_callback (= function), &callback_ctx]
(API)	8. calls quicctx::picoquic_set_transport_parameters with [cnx_client, callback_ctx.tp]
(!)					8.1 sets the local transport parameters of [cnx_client] to the same as [callback_ctx.tp] (initialized in step 2.1)
(APTLS) 9. calls tls_api::picoquic_esni_client_from_file with [cnx_client, esni_rr_file (=encryption SNI file)] (no changes needed here?!)
(API)	10. calls quicctx::picoquic_start_client_cnx with [cnx_client]
(APTLS)				10.1 calls tls_api::picoquic_initialize_tls_stream with [cnx]
						-> prepare the initial message when starting a connection (PICOTLS!) tls_api::picoquic_tls_set_extensions(-) // ptls_buffer_init(-) // 10.1.3 pltls_handle_message(-) // 10.1.4 tls_api::picoquic_add_to_tls_stream(-) // 10.1.5 ptls_buffer_dispose(-)

(API)	11. if quicctx::picoquic_is_0rtt_available(cnx_client)
			calls democlient::picoquic_demo_client_start_streams with [cnx, ctx, fin_stream_id (= last stream)]
					11.1 starts with ALPN initialization: 
							if alpn=picoquic_alpn_http_3, 
(HTTP)						calls democlient::h3zero_client_init [cnx] -> use HTTP0.9 to evade this
(API)							(deep) 11.1.1 sender::picoquic_add_to_stream [cnx, 2, h3_frame, h3_size, 0]
(API)							(deep) 11.1.2 picoquic_mark_high_priority_stream with [cnx, 2 (= stream ID), 1]
(API)							(deep) 11.1.3 sender::picoquic_add_to_stream [cnx, 6 (= stream ID), &encoder_stream_head, 1, 0]
(API)							(deep) 11.1.4 sender::picoquic_add_to_stream [cnx, 10 (= stream ID), &decoder_stream_head, 1, 0]
(!)					11.2 open all streams scheduled after the stream that just finished until it reaches ctx->nb_demo_streams (set in step 2.1)
							calls democlient::picoquic_demo_client_open_stream with [cnx, ctx, demo_stream:stream_id, demo_stream:doc_name, demo_stream:f_name, demo_stream:is_binary, demo_stream:post_size (= values of demo streams = scenarios specified), repeat_nb (= number of repeated stream openings)]
								11.2.1 create stream context
								11.2.2 create file (-> fname) + check if name is formated correctly
(!)								11.2.3 format the protocol specific request (= HTTP REQUEST)
(HTTP)								-> calls h3zero_client_create_stream_request(-) (no details here -> evade this?!)
(!!!)									  OR h09_demo_client_prepare_stream_open_command with [buffer (= for command, empty), sizeof(buffer) (= max size of command), path (= path to document), path_len, post_size, cnx->sni, &request_length]
												(simplistic GET request or POST -> use POST for sending something to the server??)
												=>	"POST " + [path] + " HTTP/1.9\r\n HOST: " + [host] + "\r\nContent-Type: text/plain\r\n\r\n"		
													-> add the timestamp here for one-way delay?
								(deep) 11.2.4 send the request/post
(API)								-> calls sender::picoquic_add_to_stream_with_ctx with [cnx, streamid, buffer (= command/data), length, 0/1 for POST/GET (= set_fin), stream_ctx]
(API)								 (if post) calls sender::picoquic_mark_active_stream [cnx, stream_id, 1, stream_ctx] 
(API)	12. calls sender::picoquic_prepare_packet [cnx_client, current_time, send_buffer, sizeof(send_buffer), &send_length, NULL (=addr_to), NULL, NULL (= addr_from), NULL]
					12.1 quicctx::picoquic_promote_successful_probe(-) (-> for client migration? new paths?)
					(12.2 quicctx::picoquic_delete_abandoned_paths(-))
					(12.3 sender::picoquic_insert_hole_in_send_sequence_if_needed(-))
					(12.4 quicctx::picoquic_delete_failed_probes (-) + sender::picoquic_prepare_probe(-))
					(12.5 sender::picoquic_prepare_alt_challenge(-))
					12.6 select the path
					12.7 util::picoquic_store_addr(-) + set to_length and from_length
					12.8 Send available segments
(API)					 	12.8.1 packet = sender::picoquic_create_packet [cnx->quic]
							12.8.2 sender::picoquic_prepare_segment [cnx, path, packet, current_time, send_buffer + send_length, available, &segment_length, &next_wake_time]
(API)								-> checks for alive connection
										& calls sender::picoquic_prepare_packet_(client_init/_server_init/_ready/_closing)
							12.8.3 (sender::picoquic_recycle_packet [cnx->quic, packet])
					12.9 log the sent packet + update wake up time for connection
(SCKT)	13. calls UDPSOCKET::sendto [fd (= socket), send_buffer (= msg), send_length, 0 (= flags), &server_address, server_addr_length]

		* WAIT FOR PACKETS * (from line 688)
			**RECEIVE**
		14. calls bytes_recv = picosocks::picoquic_select [&fd (= socket), 1 (= number of sockets), &packet_from (= source addr), &from_length, &packet_to (= dest addr), &to_length, &if_index_to, &received_ecn (=congestion?), buffer, sizeof(buffer), delta_t, &current_time]
(picoqtls)	14.1 calls naclref::select [sockmax+1 (= max socket number), &readfd (= socket), NULL, NULL, &tv (= time)] (no changes needed here?!)
			14.2 calls picosocks::picoquic_recvmsg [sockets(i), addr_from, from_length, addr_dest, dest_length_ dest_if, received_ecn, buffer, buffer_max] (no changes needed here?!)
(SCKT)					-> calls UDPSOCKET::recvmsg[fd, &msg, 0]
(SKIP)	15. (~ line 716 - 749: Client Migration Behavior)
(API)	16. calls packet::picoquic_incoming_packet [qlient, buffer, bytes_recv, &packet_from, &packet_to, if_index_to, received_exn, current_time]
				-> calls packet::picoquic_incoming_segment [quic, bytes + consumed_index, packet_length - consumed_index, packet_length, &consumed, addr_from, addr_to, received_ecn, current_time]
						16.-.1 packet::picoquic_parse_header_and_decrypt(-)
(deep)								-> packet::picoquic_parse_packet_header(-)
										=> encoding header depending on the packet type (Initial, 0-RTT, Handshake, Retry, not valid, no version)
						16.-.2 util::picoquic_is_connection_id_null(-)
						16.-.3 logger::picoquic_log_packet_address(-)
						16.-.4 logger::picoquic_log_decrypted_segment(-)
(LOG)	17. logger::picoquic_log_processing + logger::picoquic_log_error_packet => internal logging
				***QUIC STATE RDY or CLIENT RDY START*** 
		18. (see 11. ) calls democlient::picoquic_demo_client_start_streams [cnx_client, &callback_ctx, PICOQUIC_DEMO_STREAM_ID_INITIAL]
		19. (~ line 833 - 846: Client Migration)
		20. (~ line 848 - 860: Key Rotation)
		21. no open streams -> close the connection + log statistics
			open streams + idle for 10 secs -> close the connection
			(sender::picoquic_close [cnx_client, 0 (= reason code)])
			**SEND**
		22. (see 12. ) calls sender::picoquic_prepare_packet [cnx_client, current_time, send_buffer, sizeof(buffer), &send_length, &x_to, &x_to_length, &x_from, &x_from_length]
(SCKT)	23. calls UDPSOCKET::sendto [fd, send_buffer, send_length, 0, &x_to, x_to_length]
	    24. calls quicctx::picoquic_get_next_wake_delay [qclient, current_time, delay_max])
		
		* CLEAN UP * (from line 930)
		25. picoquic_demo_client_delete_context [&callback_ctx]
		26. quicctx::picoquic_free [qclient]
		27. SOCKET_CLOSE [fd] => UDPSOCKET::close [fd]
		28. democlient::demo_client_delete_scenario_desc [client_sc_nb, client_sc]




## Server
picoquicdemo::main()
calls picoquicdemo::quic_server()
		1. calls picoquic_open_server_sockets[&server_sockets, server_port]
		
		* CREATE QUIC CONTEXT *
		2. (see Client: 5. ) qserver = quicctx::picoquic_create [8 (= number of connections), pem_cert, pem_key, NULL, NULL, picoquic_demo_server_callback, NULL, cnx_id_callback, cnx_id_callback_ctx, reset_seed, current_time, NULL, NULL, NULL, 0]
(APTLS)	3. quicctx::picoquic_set_cookie_mode(-)
		4. quicctx::picoquic_set_default_congestion_algorithm(-)
(APTLS)	5. picoquicdemo::picoquic_set_key_log_file_from_env(-)
(APTLS)	6. tls_api::picoquic_esni_load_key(-) + tls_api::picoquic_esni_server_setup(-)
		
		*WAIT FOR PACKETS + PROCESS THEM *
			**RECEIVING**
		7. (see Client: 14. ) calls bytes_recv = picosocks::picoquic_select [server_sockets.s_socket, PICOQUIC_NB_SERVER_SOCKETS, &addr_from, &from_length, &addr_to, &to_length, &if_index_to, &received_ecn, buffer, sizeof(buffer), delta_t (= wake_delay), &current_time]
		8. (see Client: 16. ) packet::picoquic_incoming_packet [qserver, buffer, bytes_recv, &addr_from, &addr_to, if_index_to, received_ecn, current_time]
		9. check if first connection and log the connection details
		(10. calls quicctx::picoquic_dequeue_stateless_packet[qserver]
(SCKT)				-> calls picosocks::picoquic_send_through_server_sockets(-) -> calls picosocks::picoquic_send_through_socket(-))
			**SENDING**
		11. (see Client: 12. ) sender::picoquic_prepare_packet [cnx_next, current_time, send_buffer, sizeof(send_buffer), &send_length, &peer_addr, &peer_addr_len, &local_addr, &local_addr_len]
		12	either: close connection + log (when disconnected)
			or:		picosocks::picoquic_send_through_server_sockets(-)
		
		*CLEAN UP*
		13. quicctx::picoquic_free[qserver]
		14. picosocks::picoquic_close_server_sockets [&server_sockets] -> SOCKET_CLOSE






# Detailed function flow for retransmissions
(see Client 12. )  sender::picoquic_prepare_packet(-)
				-> sender::picoquic_prepare_segment(-)
					1. check that connection is still alive
					2. prepare header depending on the connection state (client/server init, closing, or ready)
						picoquic_state_ready: sender::picoquic_prepare_packet_ready(-)
							2.1 stream = stream head = NULL
								packet_type = 1rtt_protected
								pc = packet context = application
								is_pure_ack = 1
							2.2 check if handshake finished 
										-> sender::picoquic_prepare_packet_old_context(-) if not finished
							2.3 stream = frames::picoquic_find_ready_stream(cnx)
									2.3.1 check for high priority stream 
													-> hi_pri_stream = quicctx::picoquic_find_stream [cnx, cnx->high_priority_stream_id]
														(finds stream in the splaytree, see 6.8 )
									2.3.2 skip to first non-visited stream 
									2.3.3 look for a ready stream
												-> with data to send (= not finished) and not blocked
							2.4 (RETRANSMIT) calls sender::picoquic_retransmit_needed [cnx, pc, path_x, current_time, next_wake_time (= next retransmit time), packet, send_buffer_min_max, &is_cleartext_mode, &header_length]
									2.4.1 should_retransmit = 0 / timer_based_retransmit = 0 
											old_p = cnx->pkt_cnx[pc].retransmit_oldest (= oldest packet that has to be retransmitted) 
											p_next = old_p->previous_packet
									2.4.2 calls should_retransmit = sender::picoquic_retransmit_needed_by_packet [cnx, old_p, current_time, next_retransmit_time, &timer_based_retransmit]
													2.4.2.1 (later packets are acked -> RACK timer-based, although stated as timer-based=0 !)
															by default: timer-based RACK logic (to absorb out-of-order deliveries) and delta_seq should be smaller than 3 (RACK works best with small reordering window) when 3 or more later packets are acked, choose always first computations
																	retransmit_time = MINIMUM of 
																						p->send_time + cnx->path[0]->retransmit_timer 	("retransmit_timer" equals "cnx->path[0]->smoothed_rtt + (cnx->path[0]->smoothed_rtt >> 3)")
																						cnx->pkt_ctx[pc].latest_time_acknowledged + cnx->remote_parameters.max_ack_delay + (cnx->path[0]->smoothed_rtt >> 2)
															(later packets are not acked -> timer-based)
															rto = 	cnx->path[0]->retransmit_timer (when first retransmit)
																	OR 1000000ull << (cnx->pkt_ctx[pc].nb_retransmit - 1)
															retransmit_time = p->sendtime + rto
													2.4.2.2 decide based on the retransmit_timer and the current_time if a retransmit is needed right now
									2.4.3 calls sender::picoquic_copy_before_retransmit(-)
									2.4.4 calls old_p = picoquic_dequeue_retransmit_packet(-) 
															=> update number of bytes "in-flight" and remove old packet from queue + placed in retransmitted queue for detecting spurious retransmissions
									2.4.6 check for MAX_RETRANSMISSIONS (if already exceeded)
									2.4.7 return length of packets (= bytes)
											
									
								(NO RETRANSMIT) calls frame::picoquic_prepare_ack_frame(-) (if frame::picoquic_is_ack_needed(-) is true)
											   calls several specific functions if they are needed like 
																picoquic_prepare_crypto_hs_frame(-)
																picoquic_prepare_first_misc_frame(-) 
																picoquic_prepare_new_path_and_id(-)
																picoquic_prepare_max_streams_frame_if_needed(-)
																picoquic_prepare_max_data_frame(-)
																picoquic_prepare_required_max_stream_data_frames(-)
(interesting?)													picoquic_prepare_stream_frame(-) => encode the stream frame/frames
																picoquic_prepare_blocked_frames(-)
																"The case where many acks are not acknowledged"
																	= picoquic_pad_to_policy(-)
																	else = picoquic_prepare_mtu_probe(-)
																"maybe send keep alive packets"
																	= picoquic_predict_packet_header_length(-)
							2.5 sender::picoquic_finalize_and_protect_packet(-)
									(encodes the packet if encryption is used)
									-> calls picoquic_protect_packet(-)
										+ calls picoquic_queue_for_retransmit(-) (if it is not ack'ed, we have it in queue)
							2.6 log information => logger::picoquic_cc_dump(-)





# Update of RTT values / Retransmit Timer Update:
packet::picoquic_incoming_(0rtt/client_handshake/server_cleartext/initial/encrypted) 	=> encrypted = normal received answer -> if ack -> update RTT
		-> calls frames::picoquic_decode_frames(-)
			-> calls frames::picoquic_decode_ack_(ecn_)frame(-)
				-> calls frames::picoquic_decode_ack_frame_maybe_ecn(-)
					-> calls frames::picoquic_update_rtt(-)
							(checks for up-to-date ack)
							-> calls frames::picoquic_update_path_rtt(-)

								1. set new max_ack_delay (if ack_delay is bigger now)
								2. (initial)
									2.1 smoothed_rtt = rtt_estimate
									2.2 rtt_variant = rtt_estimate/2
									2.3 rtt_min = rtt_estimate
									2.4 retransmit_timer = 3 x rtt_estimate + max_ack_delay
									2.5 ack_delay_local = rtt_min/4
									2.6 ack_delay_local = max(ack_delay_local, PICOQUIC_ACK_DELAY_MIN)
								
									(not initial) *BASED ON RFC 6298* (TCP Retransmission Timer)
									2.1	delta_rtt = rtt_estimate - smoothed_rtt
									2.2 smoothed_rtt = smoothed_rtt + delta_rtt/8
									2.3 delta_rtt_average = delta_rtt - rtt_variant (-> delta_rtt can be sub-zero!)
									2.4 rtt_variant = rtt_variant + delta_rtt_average / 4
									2.5 rtt_estimate = max(rtt_estimate, rtt_min)
									2.6 ack_delay_local = max(ack_delay_local, PICOQUIC_ACK_DELAY_MIN)
									2.7 ack_delay_local = min(ack_delay_local, PICOQUIC_ACK_DELAY_MAX)
									2.8 if [4 x rtt_variant < rtt_min] -> rtt_variant = rtt_min / 4
									2.9 retransmit_timer = smoothed_rtt + 4 x rtt_variant + max_ack_delay (MaxAckDelay is set in cnx->remote_parameters)
									2.10 retransmit_timer = max(retransmit_timer, PICOQUIC_MIN_RETRANSMIT_TIMER)
									
									
									
									
									
# Send Time & Acknowledged time: How does "rtt_estimate" gets computed?

*Official Description*
"Time management. Internally, picoquic works in "virtual time", updated via the "current time" parameter
 passed through picoquic_create(), picoquic_create_cnx(), picoquic_incoming_packet(), and picoquic_prepare_packet().
 The function "picoquic_current_time()" reads the wall time in microseconds, accessed through system API. 
 The default socket code in "picosock" uses that time function, and returns the time
 at which messages arrived.
 The function "picoquic_get_quic_time()" returns the "virtual time"."
 
 
ACK received = update RTT with "current_time" as a parameter
	
	*HOW? Current Time updated*
	- function "picoquic_get_quic_time(quic)"
	**Code snipped**
    uint64_t now;
    struct timeval tv;
    (void)gettimeofday(&tv, NULL);
    now = (tv.tv_sec * 1000000ull) + tv.tv_usec;
	return now;
	
	*WHEN? Current Time update
	- Set up of Client / Server context [picoquicdemo::quic_client(-) + picoquicdemo::quic_server]
	- Set up the TL tokens [quicctx::picoquic_load_token_file(-)]
	- Receiving bytes over a socket [picosocks::picoquic_select(-)]
	- Every loop when waiting for a packet [picoquicdemo::quic_client(-)]
    
	*HOW? Send time*
	- set in "sender::prepate_packet_(...)"-functions	
		=> "packet->send_time = current_time;"
	
	*HOW? Acknowledged time*
	**Code snipped**
	uint64_t acknowledged_time = current_time - ack_delay;
    int64_t rtt_estimate = acknowledged_time - packet->send_time;
	
	if (pkt_ctx->latest_time_acknowledged < packet->send_time) {
        pkt_ctx->latest_time_acknowledged = packet->send_time;
    }
    cnx->latest_progress_time = current_time;

	*! rtt_estimate = current RTT which is used in computation of retransmission timer !*



# NEW TIMING:

[picoquic_demo_client_start_streams]: opens all streams and calls [picoquic_demo_client_open_stream]
(see 11.2) [picoquic_demo_client_open_stream]: nb_open_streams++, calls [picoquic_add_to_stream_with_ctx], calls [picoquic_mark_active_stream]
[picoquic_add_to_stream_with_ctx]: SENDER fills the stream with the data
[picoquic_mark_active_stream]: Mark stream as active, or not. If a stream is active, it will be polled for data when the transport is ready to send. The polling will only start after all currently queued data has been sent.
	=> if is_active = 0, then data is never sent/POSTed
	=> use this for delaying streams

[picoquic_demo_client_callback] in case "picoquic_callback_stream_fin" calls [picoquic_demo_client_close_stream]
[picoquic_demo_client_close_stream]: nb_open_streams--, stream_ctx->is_open = 0






