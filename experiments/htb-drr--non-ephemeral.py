#!/usr/bin/env python3
from mininet.net import Mininet
from mininet.node import Controller
from mininet.link import Intf, TCIntf, TCLink
from mininet.cli import CLI
from mininet.log import setLogLevel, info

from mininet.term import makeTerm, makeTerms
import time
import os.path
import sys

def createNetwork():
	#send rate at each link in Mbps
	bwg = 1 #in Mbps
	bwbn = 1 #in Mbps
	mqs = 100 #max queue size of interfaces
	dly = '2.5ms'
	apps = 4 #number of other UDP applications = number of DRR classes - 1

	#create empty network
	net = Mininet(intf=TCIntf)

	info( '\n*** Adding controller\n' )
	net.addController( 'c0' ) #is it ok ?

	#add host to topology
	ht = net.addHost( 'ht', ip='10.10.0.1/24' )
	hu = net.addHost( 'hu', ip='10.10.0.2/24' )
	it = net.addHost( 'it', ip='10.20.0.1/24' )
	iu = net.addHost( 'iu', ip='10.20.0.2/24' )

	rh = net.addHost('rh', ip='10.10.0.10/24')
	ri = net.addHost('ri', ip='10.20.0.20/24')

	info('\n** Adding Switches\n')
	# Adding 2 switches to the network
	sw1 = net.addSwitch('sw1')
	sw2 = net.addSwitch('sw2')

	info('\n** Creating Links \n')
	#create link beetween the network
	link_ht_sw1 = net.addLink( ht, sw1)
	link_hu_sw1 = net.addLink( hu, sw1, intfName1='hu-eth0')
	link_rh_sw1 = net.addLink( rh, sw1, intfName1='rh-eth0')

	link_it_sw2 = net.addLink( it, sw2)
	link_iu_sw2 = net.addLink( iu, sw2)
	link_ri_sw2 = net.addLink( ri, sw2, intfName1='ri-eth0')

	link_rh_ri  = net.addLink( rh, ri, intfName1='rh-eth1', intfName2='ri-eth1')


	#set bandwith
	link_ht_sw1.intf1.config( bw = bwbn, max_queue_size = mqs)
	link_hu_sw1.intf1.config( bw = bwbn, max_queue_size = mqs)
	link_rh_sw1.intf1.config( bw = bwbn, max_queue_size = mqs) #max_queue_size is hardcoded low to prevent bufferbloat, too high queuing delays

	link_it_sw2.intf1.config( bw = bwg, max_queue_size = mqs)
	link_iu_sw2.intf1.config( bw = bwg, max_queue_size = mqs)
	link_ri_sw2.intf1.config( bw = bwg, max_queue_size = mqs, delay=dly) #delay is set at ri on both interfaces

	link_rh_ri.intf1.config(  bw = bwg, max_queue_size = mqs) #loss is set at rh on its interface to ri only

	link_ht_sw1.intf2.config( bw = bwbn, max_queue_size = mqs)
	link_hu_sw1.intf2.config( bw = bwbn, max_queue_size = mqs)
	link_rh_sw1.intf2.config( bw = bwbn, max_queue_size = mqs)

	link_it_sw2.intf2.config( bw = bwg, max_queue_size = mqs)
	link_iu_sw2.intf2.config( bw = bwg, max_queue_size = mqs)
	link_ri_sw2.intf2.config( bw = bwg, max_queue_size = mqs)

	link_rh_ri.intf2.config(  bw = bwg, max_queue_size = mqs,  delay=dly) #delay is set at ri on both interfaces

	net.start()

	info( '\n*** Configuring hosts\n' )

	rh.cmd('ifconfig rh-eth1 10.12.0.10 netmask 255.255.255.0') #reconfiguring mutiples intefaces host to prevent mininet strange initialisation behaviors
	rh.cmd('ifconfig rh-eth0 10.10.0.10 netmask 255.255.255.0')
	rh.cmd('echo 1 > /proc/sys/net/ipv4/ip_forward') #enable forwarding at routers

	ri.cmd('ifconfig ri-eth1 10.12.0.20 netmask 255.255.255.0') #reconfiguring mutiples intefaces host to prvent mininet strange initialisation behaviors
	ri.cmd('ifconfig ri-eth0 10.20.0.20 netmask 255.255.255.0')
	ri.cmd('echo 1 > /proc/sys/net/ipv4/ip_forward') #enable forwarding at routers

	#configure host default gateways
	ht.cmd('ip route add default via 10.10.0.10')
	hu.cmd('ip route add default via 10.10.0.10')
	it.cmd('ip route add default via 10.20.0.20')
	iu.cmd('ip route add default via 10.20.0.20')

	#configure router routing tables
	rh.cmd('ip route add default via 10.12.0.20')
	ri.cmd('ip route add default via 10.12.0.10')

        # weiyu:
        iu.cmd('touch server.pcap')
        hu.cmd('touch client.pcap')


        rh.cmd('tc qdisc del dev rh-eth1 root')


	start_nodes(rh, ri, iu, hu, mqs, it, ht, apps) #experiment actions

	it.cmd('ethtool -K it-eth0 tx off sg off tso off') #disable TSO on TCP on defaul TCP sender need to be done on other host if sending large TCP file from other nodes

	time.sleep(1)

	# Enable the mininet> prompt if uncommented
 	info('\n*** Running CLI\n')
	CLI(net)

	# stops the simulation
	net.stop()

def start_nodes(delay_router, loss_router, quicserver, quicclient, mqs, trafficserver, trafficclient, apps):
 
 #set HTB on interface
 quicclient.cmd('tc qdisc del dev hu-eth0 root')
#  quicclient.cmd('tc qdisc add dev hu-eth0 root handle 1: htb')
#  quicclient.cmd('tc class add dev hu-eth0 parent 1: classid 1:1 htb rate 1Mbit')
 quicclient.cmd('echo "HTB done.\n" > tc.log')

 #set DRR on interface
 #quicclient.cmd('tc qdisc add dev hu-eth0 parent 1:1 handle 2: drr')
 quicclient.cmd('tc qdisc add dev hu-eth0 root handle 1: drr')
 # CLASS for QUIC traffic (class 2:1)
 quicclient.cmd('tc class add dev hu-eth0 parent 1: classid 1:1 drr quantum 55') # quic quantum
 # quic filter with destination port 6121, class 2:1

# CLASSES for UDP traffic (class 2:2 to 2:apps+1)
 for i in range(apps):
 	 quicclient.cmd('tc class add dev hu-eth0 parent 1: classid 1:' + str(i+2) + ' drr quantum 500') #TODO: quantum for crosstraffic?
 
# FILTERS for QUIC + UDP traffic
 quicclient.cmd('tc filter add dev hu-eth0 parent 1: prio 1 u32 match ip dport 6121 0xffff classid 1:1') 
 # quic filter with destination port 6121, class 2:1
 for j in range(apps):
	 quicclient.cmd('tc filter add dev hu-eth0 parent 1: prio 1 u32 match ip dport 600'+ str(j+1) +' 0xffff classid 1:' + str(j+2))
	 # udp filter with destination port 6001..6004, class 2:2 .. 2:5

# default filter
 quicclient.cmd('tc class add dev hu-eth0 parent 1: classid 1:10 drr quantum 9999')
 quicclient.cmd('tc filter add dev hu-eth0 parent 1: prio 2 u32 match u32 0 0 classid 1:10')

 quicclient.cmd('echo "DRR done.\n" >> tc.log')
 quicclient.cmd('tc qdisc show dev hu-eth0 >> tc.log')
 quicclient.cmd('echo "qdisc show done.\n" >> tc.log')
 quicclient.cmd('sudo tc -s -g class show dev hu-eth0 >> tc.log')
 quicclient.cmd('echo "class show done.\n" >> tc.log')
 quicclient.cmd('tc filter show dev hu-eth0 parent 1: >> tc.log')
 quicclient.cmd('echo "filter show done.\n" >> tc.log')

 info( '\n*** Set up of HTB-DRR interface completed.\n' )

 delay_router.cmd('sudo python ./monitor_queue.py &')
 loss_router.cmd('python ./monitor_qlen_ri.py &')
 info( '\n*** Set up of in-network routers completed.\n' )

 info( '\n*** Start QUIC Server...\n' )
 quicserver.cmd('sudo tcpdump -w server.pcap &')
 quicserver.cmd('sudo ./start_server_mininet.sh > stdoutput_server.txt &')
 info( '\n*** QUIC Server started.\n' )

 info( '\n*** Start QUIC Client...\n' )
 quicclient.cmd('sudo tcpdump -w client.pcap &')
 quicclient.cmd('sleep 5; sudo ./start_client_mininet.sh 6000 100 100 N > stdoutput_client.txt &')
 info( '\n*** QUIC Client started.\n' )

 # UDP crosstraffic: "apps" number of UDP applications
 for i in range(apps): #starttimes: 30, 60, 90, 120 | runtime = 150 sec | endtimes: 180, 210, 240, 270
	time.sleep(30)
	quicclient.cmd('sudo tc -s -g class show dev hu-eth0 >> tc.log')
	quicclient.cmd('echo "class show done (udp#'+ str(i+1) +').\n" >> tc.log')

	info( '\n*** Start UDP Server', i+1,' on port 600'+ str(i+1) +' ...\n' )
 	trafficserver.cmd('sudo iperf -s -p 600'+ str(i+1) +' -u > trafficserver'+ str(i+1) +'.log &')
 	info( '\n*** Start UDP App', i+1,' on QUIC Client for Server on port 600'+ str(i+1) +' ...\n')
 	quicclient.cmd('sudo iperf -c 10.20.0.1 -p 600'+ str(i+1) +' -t 150 -u -b 250k > trafficclient'+ str(i+1) +'.log&')


if __name__ == '__main__':
	setLogLevel( 'info' )
	createNetwork()
 