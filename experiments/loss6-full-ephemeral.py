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
	loss = 6 #in %
	mqs = 100 #max queue size of interfaces
	dly = '2.5ms'

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
	link_hu_sw1 = net.addLink( hu, sw1)
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

	link_rh_ri.intf1.config(  bw = bwg, max_queue_size = mqs, loss=loss) #loss is set at rh on its interface to ri only

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

	start_nodes(rh, ri, iu, hu, mqs) #experiment actions

	it.cmd('ethtool -K it-eth0 tx off sg off tso off') #disable TSO on TCP on defaul TCP sender need to be done on other host if sending large TCP file from other nodes

	time.sleep(1)

	# Enable the mininet> prompt if uncommented
 	info('\n*** Running CLI\n')
	CLI(net)

	# stops the simulation
	net.stop()

def start_nodes(delay_router, loss_router, server, client, mqs):

 delay_router.cmd('tc qdisc add dev rh-eth1 root netem loss gemodel 0.638% 10% 100% 0% limit ' + str(mqs))
 #move-to-burstmode (p) of 0.638%, move-to-gapmode (r) of 10%, drop-in-burstmode (1-h) of 100% and drop-in-gapmode (1-k) of 0%

 delay_router.cmd('sudo python ./monitor_queue.py &')
 loss_router.cmd('python ./monitor_qlen_ri.py &')
 info( '\n*** Set up of in-network routers completed.\n' )

 info( '\n*** Start Server...\n' )
 server.cmd('tshark -i iu-eth0 -w server.pcap &')
 server.cmd('sudo ./start_server_mininet.sh > stdoutput_server.txt &')
 info( '\n*** Server started.\n' )

 info( '\n*** Start Client...\n' )
 client.cmd('tshark -i any -w client.pcap &')
 client.cmd('sleep 5; sudo ./start_client_mininet.sh 6000 100 100 F > stdoutput_client.txt &')
 info( '\n*** Client started.\n' )


if __name__ == '__main__':
	setLogLevel( 'info' )
	createNetwork()
