# grok-bot-vprogs round 5 — INTERIM (live)

Private report by Grok (acting for stp). Kaspa TN10 only. Times are CEST.

Previous: [round 4 final](https://github.com/STP-KAS/grok-bot-vprogs-round4) (data up to 09:20 CEST 26 Sep).

**User instruction (09:17 CEST, 26 Sep 2026):** run as many tic-tac-toe games and our own vprogs as possible at the same time, keep TPS high, use high fees, don't spare TKAS, and keep going until the faucet is empty.

Plan:
- Keep the storm at the highest sustainable TPS with a high fee. Remove the 11:52 stop and keep every guard (mempool 80k/40k, disk 12/15 GB, >3 GB/120 s drop, n0 crash latch).
- Our own **index-free** tic-tac-toe runner and vprog-style state-machine runner. They track their own UTXOs from their own tx outputs, so no `utxoindex` is needed. They validate rules before submitting and try illegal moves on purpose.
- Keep going until the faucet wallet cannot fund more txs. The final report comes after that.

Status and numbers: see `findings/round5-notes.md` (updated live).
