#!/bin/bash

INTERFACES=("enp1s0f0np0" "enp1s0f1np1")
NAMESPACES=("ns_server" "ns_client")
IPS=("10.0.0.9/24" "10.0.0.99/24") 

echo "Environment clean. Proceeding with setup..."

for i in "${!INTERFACES[@]}"; do
    echo "-=-=-=-=-=-=-=-=-=-=-=-=-="
    IFACE=${INTERFACES[$i]}
    NS=${NAMESPACES[$i]}
    echo "::: $IFACE  ::: $NS"
    # 1. Check if Namespace exists and delete them
    if ip netns list | grep -q "$NS"; then
        echo "Found existing namespace: $NS. Checking for $IFACE..."

        # 2. Check if the interface is inside that namespace
        if ip netns exec "$NS" ip link show "$IFACE" >/dev/null 2>&1; then
            echo "Moving $IFACE back to root namespace..."
            sudo ip netns exec "$NS" ip link set "$IFACE" netns 1
        fi

        # 3. Clean up the namespace
        echo "Deleting namespace $NS..."
        sudo ip netns delete "$NS"
    fi

    # 2. Add name spaces: 
    sudo ip netns add $NS 

    # 3. Add interface to namespace, set IP and MTU 
    echo "Move Interfaces to Namespaces: $IFACE to $NS "
    sudo ip link set $IFACE netns $NS 
    sleep 1

    # 4. IP assignment for the interface 
    echo "Assigning IP $IPS[i] to $IFACE in $NS"
    echo "---------------------------------------"
    sudo ip netns exec $NS ip addr add ${IPS[$i]} dev $IFACE

    # 5. Bring-up Interface and set Jumbo frame size:
    echo "Bringing up interface and set MTU to Jumbo frame"
    sudo ip netns exec $NS ip link set $IFACE mtu 9000 up
    sudo ip netns exec $NS ip link set lo up
    
    # 6. show the changes
    sleep 1
    echo "---------------------------------------"
    sudo ip netns exec $NS ip link show
    echo "---------------------------------------"

    echo "Verifying RDMA device migration..."
    echo "---------------------------------------"
    sleep 1
    sudo ip netns exec $NS rdma link show
    echo "---------------------------------------"

done

for i in "${!NAMESPACES[@]}"; do
    NS=${NAMESPACES[$i]}
    echo "--- NameSpace $NS Summary ----"
    sudo ip netns exec $NS ip addr show
    echo "------------------------------"
    echo "Verifying RDMA device migration..."
    echo "------------------------------"
    sudo ip netns exec $NS rdma link show
done 

# Make sure to install mlnx-tools to include show_gids 
echo "---- GID table  -------"
# sudo ip netns exec $NAMESPACES[1] /usr/sbin/show_gids
/usr/sbin/show_gids 

# to test RoCE 
echo "For RoCE: v2 bandwidth Test: "
echo "Find the row for rocep1s0f0 in the GID table and look for \`RoCE v2\` and the \`IP address\`"
echo "Note the GID Index (usually 3)"
echo "------------------------------------------------------------------------"
echo "Server> sudo ip netns exec ns_server ib_write_bw -d rocep1s0f0 -x 3 -a "
echo "------------------------------------------------------------------------"
echo "Client> sudo ip netns exec ns_client ib_write_bw -d rocep1s0f1 -x 3 -a 10.0.0.9"
echo "------------------------------------------------------------------------"
echo "Test pipeline : Memory $\rightarrow$ PCIe $\rightarrow$ Port 0 $\rightarrow$ Port 1 $\rightarrow$ PCIe $\rightarrow$ Memory."
echo "------------------------------------------------------------------------"

echo " Run top and check the cpu load is zero."

echo "Check /sys/class/infiniband/rocep1s0fX/ for additional card details "
