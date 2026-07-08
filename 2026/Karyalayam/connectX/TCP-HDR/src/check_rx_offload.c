#include <stdio.h>
#include <stdint.h>

#include <rte_eal.h>
#include <rte_ethdev.h>

int main(int argc, char **argv)
{
    uint16_t port_id;
    struct rte_eth_dev_info dev_info;
    int ret;

    ret = rte_eal_init(argc, argv);
    if (ret < 0) {
        rte_exit(EXIT_FAILURE, "EAL initialization failed\n");
    }

    if (rte_eth_dev_count_avail() == 0) {
        rte_exit(EXIT_FAILURE, "No Ethernet devices found\n");
    }

    RTE_ETH_FOREACH_DEV(port_id) {

        printf("\n====================================\n");
        printf("Port %u\n", port_id);
        printf("====================================\n");

        ret = rte_eth_dev_info_get(port_id, &dev_info);
        if (ret != 0) {
            printf("rte_eth_dev_info_get failed: %d\n", ret);
            continue;
        }

        printf("Driver: %s\n", dev_info.driver_name);

        printf("\nRX offload capability mask : 0x%016lx\n",
               dev_info.rx_offload_capa);

        printf("RX queue offload capability : 0x%016lx\n",
               dev_info.rx_queue_offload_capa);

        printf("\nChecking capabilities:\n");

        if (dev_info.rx_offload_capa &
            RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT) {
            printf("[YES] RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT supported\n");
        } else {
            printf("[NO ] RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT NOT supported\n");
        }

        if (dev_info.rx_offload_capa &
            RTE_ETH_RX_OFFLOAD_SCATTER) {
            printf("[YES] RTE_ETH_RX_OFFLOAD_SCATTER supported\n");
        } else {
            printf("[NO ] RTE_ETH_RX_OFFLOAD_SCATTER NOT supported\n");
        }

        printf("\nMaximum RX segments per packet: %u\n",
               dev_info.rx_desc_lim.nb_max);
    }

    return 0;
}
