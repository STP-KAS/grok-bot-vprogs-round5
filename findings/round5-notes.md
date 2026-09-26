# Round 5 interim notes (live; times CEST, 26 Sep 2026)

User 09:17: "implement as many tic-tac-toe games as you want and your own versions of vprogs simultaneously, keep TPS high, use high fees, do not spare TKAS, keep going until faucet is empty."

## Setup
- Node n0 only, **no utxoindex** (deleted in the round-4 07:10 disk emergency). Our runners never query an index. Each chain tracks its own UTXO from the outputs of the txs it built.
- **Faucet** = desk key 0 = our mining address. Its UTXOs are enumerated with the live public API `POST /addresses/utxos`. The `GET /addresses/<a>/utxos` endpoint is CDN-cached and was minutes stale, which gave us spent seeds and "orphan" rejects. Our miners refill the faucet at ~0.8–1.0k TKAS/min, and ~57% of chain-block coinbase value (incl. fees we burn) returns to it.
- `scripts/r5-engine.mjs`: shared engine. Funding tx from faucet UTXOs (≤16 inputs) → fresh key; then chained 1-in-1-out signed txs with the state in the payload. Latency is submit → acceptance via `virtual-chain-changed`. It has a rate-file token bucket, its own mempool pause (79k/70k), a live feerate file, chain keys persisted mode-600 (never committed), and halt files.
- `scripts/r5-ttt.mjs`: tic-tac-toe. Payload `TTT1|gid|seq|player|cell|board9`. Each lane recycles its chain across games. `illegalReason()` enforces the cell range, an empty cell, the correct turn, and game-not-over. Random illegal attempts (occupied / out-of-range / wrong player) are refused locally and never submitted.
- `scripts/r5-vprog.mjs`: vprog-style state machines. Kinds: C counter (+1..3 up to 30), E escrow (OPEN→FUNDED→RELEASED|REFUNDED, alternating actor), T turn-based (alternating player, 6 rounds). Payload `VPG1|kind|pid|step|sha256 hash-chain|state JSON`. `rule()` checks each transition. Illegal attempts: counter jump >3, escrow release before funding, wrong player.
- Storm: `tps-supervisor.py` + 8 P2SH workers + H pay lane. `scripts/r5-pacer.py` has no end time (TARGET 1500/s, soft disk taper 18→16 G for the ~18:50 pruning). It keeps all round-4 guards: mempool 80k/40k, disk 12/15 G, >3 G/120 s drop, n0 crash latch.

## Timeline
- 09:22 round 4 report final (856ae76). Storm restarted at **150x** fee (0.0965 TKAS/tx).
- 09:23–09:50 **150x was counterproductive**. P UTXOs are only ~0.25 TKAS, so the fee cut the outputs and KIP-9 storage mass jumped to ~69k grams/tx (effective feerate only ~140 sompi/g). Blocks were 87% storage-mass full, and net TPS fell to ~300–440. The H lane crash-looped: at 150x the 1-in-2-out fee exceeded the input (negative change). Fixed.
- 09:23+ an **external flood** (not ours: 12.6k sig 1-out txs at 0.249 TKAS, 25k 1-in-2-out, 10k p2sh) kept the mempool at 45–86k. Peak 85.8k at ~09:43 with the P2P relay throttling. It never reached 100k.
- 09:30–09:49 runner versions v1–D (tests + fixes: seed selection, stale API, chain recycling). Run D (7 min): **7,101 games / 54,725 moves + 5,637 programs / 49,033 steps**, 111k txs, 0 rejects, latency p50 0.57 s / p95 1.34 s, **illegal 21,900 attempted / 21,900 refused / 0 executed**, 40.3k TKAS fees.
- 09:51 storm back to **10x** (the user's usual). Runners at 20,000 sompi/g → 60,000 sompi/g (09:57; 60x the storm's 1,000). All mature faucet UTXOs go to runners from 10:01 (storm burns its own ~28k pool).
- 10:08 runners at 250 + 250 moves/s. The faucet is finally draining: mature 112k (10:01) → 57k (10:10).

## Snapshot 10:10
| | ttt-E | vprog-E |
|---|---:|---:|
| concurrent lanes (games/programs at once) | 250 | 250 |
| moves/s | ~250 | ~117 (funding-limited) |
| fee burn | ~15.3k TKAS/min | ~7.5k TKAS/min |
| latency p50 / p95 / p99 | 0.67 / 1.71 / 2.47 s | 1.66 / 3.20 / 4.43 s |
| games / programs finished (this run) | 6,032 of 7,927 | 2,483 of 3,323 |
| illegal attempts / executed | 12,681 / **0** | 5,564 / **0** |

Storm 10x: ~185–500 tx/s accepted (squeezed by the external backlog), network ~630 tx/s accepted. Disk 19.6 G free. RAM ~6.2 G available.

## Snapshot 10:15
- ttt-E: 250 concurrent games, **250 moves/s**, latency p50/p95/p99 0.68/1.73/2.48 s. 14,135 games started / 10,983 finished (this process since 10:05), 105.6k txs, illegal 22,821 tried / **0 executed**, 212 rejects (0.2%: orphan while funding).
- vprog-E: 250 concurrent programs, **219 steps/s**, latency 1.36/2.84/3.72 s. 6,600 programs / 5,395 halted, illegal 11,453 / **0 executed**.
- Runner fee burn ≈ **29.6k TKAS/min** at 60,000 sompi/g (≈0.104 TKAS/move). Faucet: mature (spendable) 112.5k (10:01) → 42k (10:12). Balance ~90–97k (immature coinbase + our miners' ~57% share of fees keeps refilling it).
- Storm 10x: ~280 tx/s accepted (mempool held ~62k by an external storage-mass flood). Network ~860 tx/s accepted. Disk 20 G free, RAM 6.5 G available.
- Faucet-empty rule (feeder): mature faucet < 3k TKAS for 15 min → `/tmp/r5-faucet-empty` → `r5-empty-watch.sh` runs `r5-stop.sh` (exact-pid stop of all senders, logs the end time in ramp.log).
