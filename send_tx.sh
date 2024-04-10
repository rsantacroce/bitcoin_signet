#!/bin/bash

# Assigning command-line arguments to variables.
NUM_TX="$1"
DURATION="$2"

echo "Starting Bitcoin transaction script..."

# Check if bitcoin-cli is available
if ! command -v bitcoin-cli &> /dev/null
then
    echo "bitcoin-cli could not be found. Please install Bitcoin Core and ensure it is in your PATH."
    exit 1
fi

# Get a list of addresses with balance
ADDRESSES_WITH_BALANCE=$(bitcoin-cli listaddressgroupings | jq -r '.[][] | select(.[1] > 0) | .[0]')

# Select the first address with a balance to send coins from
SOURCE_ADDRESS=$(echo "$ADDRESSES_WITH_BALANCE" | head -n 1)

if [ -z "$SOURCE_ADDRESS" ]; then
    echo "No address with balance found. Ensure the wallet has a balance."
    exit 1
fi

# Get the balance of the selected address
BALANCE=$(bitcoin-cli getreceivedbyaddress "$SOURCE_ADDRESS")

# Generate a new address for receiving the coins
DESTINATION_ADDRESS=$(bitcoin-cli getnewaddress)

echo "Selected source address: $SOURCE_ADDRESS (Balance: $BALANCE BTC)"
echo "Generated new destination address: $DESTINATION_ADDRESS"

# Calculate amount to send per transaction
AMOUNT=$(echo "$BALANCE / $NUM_TX" | bc -l)
AMOUNT=$(printf "%.8f" $AMOUNT)  # Format to satoshi precision

echo "Amount per transaction: $AMOUNT BTC"

# Calculating the delay between transactions to spread them over the desired duration.
if [ "$NUM_TX" -gt 1 ]; then
    INTERVAL=$(($DURATION * 60 / ($NUM_TX - 1)))  # Convert minutes to seconds and divide by one less than number of transactions
else
    INTERVAL=0  # If only one transaction, no need for interval
fi

echo "Sending $NUM_TX transactions every $INTERVAL seconds."

# Loop to create and send transactions
for (( i=0; i<$NUM_TX; i++ ))
do
    echo "Sending transaction $((i+1)) of $NUM_TX from $SOURCE_ADDRESS to $DESTINATION_ADDRESS."
    TXID=$(bitcoin-cli sendtoaddress "$DESTINATION_ADDRESS" "$AMOUNT" "Comment: Transaction $((i+1)) from script")
    if [ $? -eq 0 ]; then
        echo "Transaction successful: TXID $TXID"
    else
        echo "Transaction failed with error: $TXID"
        break
    fi
    sleep $INTERVAL  # Waiting for the specified interval before sending the next transaction
done

echo "All transactions sent successfully."
