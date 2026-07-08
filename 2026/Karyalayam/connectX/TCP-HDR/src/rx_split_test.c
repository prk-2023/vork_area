/*
 * Test RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT support
 *
 * This program:
 *  1. Initializes DPDK EAL
 *  2. Checks mlx5 RX offload capability
 *  3. Creates two mempools:
 *       - header buffer pool
 *       - payload buffer pool
 *  4. Configures RX queue using rte_eth_rxseg_split
 *  5. Starts the port
 *
 * Expected result:
 *   show rxq info 0 0
 *
 * should report:
 *
 *   RX scattered packets: on
 *
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#include <rte_eal.h>
#include <rte_ethdev.h>
#include <rte_mempool.h>
#include <rte_mbuf.h>


#define PORT_ID          0

#define RX_RING_SIZE     256

#define NUM_MBUFS        8192
#define MBUF_CACHE_SIZE  250


int main(int argc, char **argv)
{
    int ret;

    struct rte_eth_dev_info dev_info;

    struct rte_eth_conf port_conf = {0};

    struct rte_eth_rxconf rx_conf;

    struct rte_mempool *header_pool;
    struct rte_mempool *payload_pool;


    /*
     * rte_eth_rxseg is a union.
     *
     * For BUFFER_SPLIT mode:
     *
     * segment 0 -> header buffer
     * segment 1 -> payload buffer
     *
     */
    union rte_eth_rxseg rx_seg[2];


    /*
     * Initialize EAL
     */
    ret = rte_eal_init(argc, argv);

    if (ret < 0)
        rte_exit(EXIT_FAILURE,
                 "EAL initialization failed\n");



    /*
     * Check port exists
     */
    if (!rte_eth_dev_is_valid_port(PORT_ID))
        rte_exit(EXIT_FAILURE,
                 "Invalid port %u\n",
                 PORT_ID);



    /*
     * Get PMD capabilities
     */
    ret = rte_eth_dev_info_get(PORT_ID, &dev_info);

    if (ret != 0)
        rte_exit(EXIT_FAILURE,
                 "rte_eth_dev_info_get failed\n");


    printf("\nDriver: %s\n",
           dev_info.driver_name);


    printf("RX offload capability mask: 0x%lx\n",
           dev_info.rx_offload_capa);



    /*
     * Verify BUFFER_SPLIT support
     */
    if (!(dev_info.rx_offload_capa &
          RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT)) {

        printf("\nBUFFER_SPLIT is NOT supported\n");
        return -1;
    }


    printf("\nBUFFER_SPLIT supported\n");



    /*
     * Create header mempool
     *
     * Header data will be placed here.
     */
    header_pool =
        rte_pktmbuf_pool_create(
            "header_pool",
            NUM_MBUFS,
            MBUF_CACHE_SIZE,
            0,
            256,
            rte_socket_id());


    if (!header_pool)
        rte_exit(EXIT_FAILURE,
                 "Header mempool creation failed\n");



    /*
     * Create payload mempool
     *
     * Payload data will be placed here.
     */
    payload_pool =
        rte_pktmbuf_pool_create(
            "payload_pool",
            NUM_MBUFS,
            MBUF_CACHE_SIZE,
            0,
            2048,
            rte_socket_id());


    if (!payload_pool)
        rte_exit(EXIT_FAILURE,
                 "Payload mempool creation failed\n");



    /*
     * Enable RX buffer split at port level
     */
    port_conf.rxmode.offloads =
        RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT | RTE_ETH_RX_OFFLOAD_SCATTER ;



    ret = rte_eth_dev_configure(
            PORT_ID,
            1,          /* RX queues */
            0,          /* TX queues */
            &port_conf);


    if (ret < 0)
        rte_exit(EXIT_FAILURE,
                 "Port configure failed\n");



    /*
     * Get default RX configuration
     */
    rx_conf = dev_info.default_rxconf;



    /*
     * Enable BUFFER_SPLIT on RX queue
     */
    rx_conf.offloads |=
        RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT |
        RTE_ETH_RX_OFFLOAD_SCATTER;



    /*
     * Configure RX segments
     *
     * Segment 0:
     *   First 128 bytes
     *   Header buffer
     *
     * Segment 1:
     *   Remaining payload
     *   Payload buffer
     */
    rx_seg[0].split.offset = 0;
    rx_seg[0].split.length = 128;// 512; // 128;
    rx_seg[0].split.mp     = header_pool;


    rx_seg[1].split.offset = 0;
    rx_seg[1].split.length = 2048;
    rx_seg[1].split.mp     = payload_pool;



    /*
     * Attach RX segment configuration
     */
    rx_conf.rx_seg  = rx_seg;
    rx_conf.rx_nseg = 2;



    /*
     * Setup RX queue
     *
     * mb_pool argument is still required.
     * For buffer split, individual segments use
     * rx_seg[].split.mp pools.
     */ 
    printf("rx_seg count = %u\n", rx_conf.rx_nseg);

    for (int i = 0; i < rx_conf.rx_nseg; i++) {
       printf("segment %d: len=%u pool=%p\n",
              i,
              rx_conf.rx_seg[i].split.length,
            rx_conf.rx_seg[i].split.mp);
    }
    ret = rte_eth_rx_queue_setup(
            PORT_ID,
            0,
            RX_RING_SIZE,
            rte_eth_dev_socket_id(PORT_ID),
            &rx_conf,
            NULL);
            //header_pool);


    if (ret < 0)
        rte_exit(EXIT_FAILURE,
                 "RX queue setup failed: %d\n",
                 ret);



    /*
     * Start device
     */
    ret = rte_eth_dev_start(PORT_ID);


    if (ret < 0)
        rte_exit(EXIT_FAILURE,
                 "Port start failed\n");



    printf("\nRX BUFFER_SPLIT queue configured successfully\n");

    printf("RX segments:\n");
    printf(" Segment 0 : header length  %u bytes\n",
           rx_seg[0].split.length);

    printf(" Segment 1 : payload length %u bytes\n",
           rx_seg[1].split.length);



    /*
     * Keep port running so that:
     *
     * testpmd> show rxq info 0 0
     *
     * can be checked externally
     */
    while (1)
        sleep(1);



    return 0;
}
