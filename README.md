> **Experimental. We are just trying this.**
>
> Good intentions, shaky hands. STP does not know what he is doing. We test, we write down what we think we saw, and that is the whole product. A number here is not the truth. A chart is not the truth. Any other sentence that sounds sure of itself is not the truth either. Do not count any of it as a claim.
>
> [Disclaimer](DISCLAIMER.md)

> **Experimental only. Not a product.**
>
> Do not use wallet integrations on this GitHub. STP remains a clown. [DISCLAIMER.md](DISCLAIMER.md)

# grok-bot-vprogs round 5 — final (09:22–10:35 CEST, 26 Sep 2026)

Report by Grok (acting for stp). Kaspa TN10 only. Times are CEST.
Previous: [round 4 final](https://github.com/STP-KAS/grok-bot-vprogs-round4). Next: [round 6 (full gusto, all wallets)](https://github.com/STP-KAS/grok-bot-vprogs-round6). Summary of all rounds: [tn10-vprogs-stress-findings](https://github.com/STP-KAS/tn10-vprogs-stress-findings).

**Brief (user, 09:17):** run as many tic-tac-toe games and our own vprogs as possible at the same time, keep TPS high, use high fees, don't spare TKAS, and keep going until the faucet is empty.

## Headline numbers (09:22–10:35)
| metric | value |
|---|---:|
| own-runner txs submitted / accepted | **1,039,575 / 1,036,520** (99.7%) |
| tic-tac-toe games started / finished | **73,682 / 63,614** |
| vprog programs started / halted | **45,934 / 39,703** (counter, escrow, turn-based) |
| illegal moves attempted / executed | **207,770 / 0** (all refused before building a tx) |
| runner rejects | 1,515 (0.15%, all orphan/already-spent at funding or restart; runtime-bug rejects: 0) |
| runner move latency (submit → chain acceptance), steady state | ttt p50 0.57–0.68 s, p95 1.3–1.7 s; vprog p50 0.6–1.4 s, p95 1.4–2.9 s |
| peak concurrency | 250 games + 250 programs at once |
| peak runner rate | ~250 ttt moves/s + ~220 vprog steps/s |
| runner fee counter | ≈954k TKAS gross, at 20,000–60,000 sompi/g. About 57% of chain-block coinbase value, fees included, returns to our own miners, which refill the faucet |
| storm (P0–P7 + H) | avg 234 tx/s accepted, peak 1,500. Fees 22.4k TKAS |
| network accepted TPS (n0 log) | avg 465/s, peak 2,694/s over 10 s |
| mempool | avg 58.7k, **max 85,827** (~09:43). Never near 100k, no panic |
| n0 | same pid all round, synced, no utxoindex |

## What we built
Our own **index-free** runners. They need no `utxoindex`: each game or program is a chain that knows its own UTXO, because it built the tx that created it.
- `scripts/r5-engine.mjs`: the shared engine.
  - Funding: faucet UTXOs (≤16 inputs) go to a fresh key in one tx.
  - Moves: chained, signed 1-in-1-out txs, back to back (mempool chaining), with the state in the payload. Chains are recycled game after game.
  - Latency is measured with the `virtual-chain-changed` subscription.
  - Controls: rate-file token bucket, own mempool pause 79k/70k, live feerate file `/tmp/r5-feerate`.
  - Chain keys are persisted mode-600 (never committed), so a restart resumes the chains.
- `scripts/r5-ttt.mjs`: tic-tac-toe.
  - Payload `TTT1|gameId|seq|player|cell|board9`.
  - `illegalReason()` checks the cell range, an empty cell, the correct turn, and that the game is not over.
  - Random illegal attempts (occupied cell, out-of-range, wrong player) are refused locally and never submitted.
- `scripts/r5-vprog.mjs`: vprog-style state machines.
  - Payload `VPG1|kind|pid|step|sha256 hash chain|state JSON`.
  - The hash chain can be re-verified from the payloads alone.
  - Rules: C counter (+1..3 up to 30), E escrow (OPEN→FUNDED→RELEASED|REFUNDED, alternating actor), T turn-based (alternating player, 6 rounds).
- `scripts/r5-desk-feeder.py`: faucet UTXO feeder using the live `POST /addresses/utxos`.
- `scripts/r5-pacer.py`: storm pacer with no end time. Guards: mempool 80k/40k, disk 12/15 G, >3 G/120 s drop, n0 crash latch.

## Findings
1. **A 150x storm fee is counterproductive** (09:22–09:50).
   - Storm UTXOs were ~0.25 TKAS. A 0.0965 TKAS fee shrank the outputs so much that KIP-9 storage mass exploded to ~69k grams/tx, an effective feerate of only ~140 sompi/g.
   - Blocks became 87% storage-mass full and network TPS fell to 300–440.
   - The 0.5-TKAS H lane crash-looped (1-in-2-out fee > input → negative change). Fixed.
   - Back to 10x at 09:51.
2. **The public API `GET /addresses/<a>/utxos` is CDN-cached**, several minutes stale. We got spent seeds and orphan rejects from it. `POST /addresses/utxos` is live.
3. **An external flood** (not ours) kept the TN10 mempool at 45–86k from 09:23: ~12.6k large 1-out sig txs at 0.249 TKAS, 25k 1-in-2-out, 10k p2sh. P2P relay throttling was logged at 09:38. Our storm's mempool taper held it back, so the high-feerate runners carried the TPS.
4. **High-feerate chained moves never starve.** At 20k–60k sompi/g (20–60x the storm's feerate), move latency stayed sub-second at p50 even with a 60k+ mempool. The upstream vprogs carriers in round 3 used the relay-floor fee and starved.
5. **Faucet economics.** The faucet is our own mining address. Our miners take ~57% of chain-block coinbase value, including the fees we burn, so "empty" means *spendable (mature) coins run out*. The balance itself never reaches zero while mining continues. Mature faucet: 112.5k (10:01) → ~17k (10:33).
6. The public TN10 explorer indexer has been stalled since 2026-09-25 21:55 ([details](https://github.com/STP-KAS/grok-bot-explorer-rewards-check)).

Timeline and raw logs: `findings/round5-notes.md`, `logs/ramp-r5.log`, `logs/faucet.jsonl`, `logs/*-last.json`.
