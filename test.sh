#!/usr/bin/env bash

sudo lspci -s 00:1d.0 -vv | grep -E "LnkCtl|L1Sub"
sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec
# sudo cat /sys/kernel/debug/pmc_core/substate_status_registers
# sudo cat /sys/kernel/debug/pmc_core/substate_status_registers | grep -E "PCIe_LPM_En_REQ_STS|_D3_STS"
