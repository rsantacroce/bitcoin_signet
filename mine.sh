#!/bin/bash
NBITS=${NBITS:-"1e0377ae"} #minimum difficulty in signet
# replace while with 1000 iterations

# replace while with for 
ADDR=${MINETO:-$(bitcoin-cli getnewaddress)}
for i in {1..1000}; do
# while true; do
    # ADDR=${MINETO:-$(bitcoin-cli getnewaddress)}
    if [[ -f "${BITCOIN_DIR}/BLOCKPRODUCTIONDELAY.txt" ]]; then
        BLOCKPRODUCTIONDELAY_OVERRIDE=$(cat ~/.bitcoin/BLOCKPRODUCTIONDELAY.txt)
        echo "Delay OVERRIDE before next block" $BLOCKPRODUCTIONDELAY_OVERRIDE "seconds."
        sleep $BLOCKPRODUCTIONDELAY_OVERRIDE
    else
        BLOCKPRODUCTIONDELAY=${BLOCKPRODUCTIONDELAY:="0"}
        if [[ BLOCKPRODUCTIONDELAY -gt 0 ]]; then
            echo "Delay before next block" $BLOCKPRODUCTIONDELAY "seconds."
            sleep $BLOCKPRODUCTIONDELAY
        fi
    fi

    latest_block_hash=$(bitcoin-cli -signet getbestblockhash)

    # Get the full block data for the latest block
    block_data=$(bitcoin-cli -signet getblock "$latest_block_hash")

    # Extract the nBits value using jq
    NBITS=$(echo "$block_data" | jq -r '.bits')

    echo "Mine To:" $ADDR
    miner --cli="bitcoin-cli" generate --grind-cmd="bitcoin-util grind" --address=$ADDR --nbits=$NBITS --set-block-time=$(date +%s)    
    if [[ $i -gt 17 ]]; then
        sleep 300
    fi
done
