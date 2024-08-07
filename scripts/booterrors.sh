#!/usr/bin/env bash

booterrors()
{
    printf "\nEmergency level:\n"
    journalctl -b -p emerg | grep -v "Journal begins" | ccze -m ansi
    printf "\n\nAlert level:\n"
    journalctl -b -p alert | grep -v "Journal begins" | ccze -m ansi
    printf "\n\nCritical level:\n"
    journalctl -b -p crit | grep -v "Journal begins" | ccze -m ansi
    printf "\nError level:\n"
    journalctl -b -p err | grep -v "Journal begins" | ccze -m ansi
}

booterrors
