#!/bin/bash

# run bitcoind
# This way new templates are constructed every 20 seconds (taking the most profitable txs from the mempool) 
# and they are sent downstream if new fees collected are more than 1000 sats.
bitcoind --daemonwait -sv2 -sv2port=8442 -sv2interval=20 -sv2feedelta=1000 -debug=sv2 -loglevel=sv2:trace -sv2bind=0.0.0.0
sleep 5
echo "get magic"
magic=$(cat /root/.bitcoin/signet/debug.log | grep -m1 magic)  
magic=${magic:(-8)}
echo $magic > /root/.bitcoin/MAGIC.txt

# if in mining mode
if [[ "$MINERENABLED" == "1" ]]; then
    mine.sh
fi