#!/bin/bash
# round5: when r5-desk-feeder.py writes /tmp/r5-faucet-empty (faucet <5k TKAS and storm pool <5k for 15 min), stop all senders.
D=/workspace/tn10-break-test-2026-09-25
while [ ! -e /tmp/r5-faucet-empty ]; do sleep 20; done
echo "$(date +%FT%T%z) R5 FAUCET-EMPTY detected: $(cat /tmp/r5-faucet-empty)" >> $D/logs/storm/ramp.log
bash $D/scripts/r5-stop.sh faucet-empty
