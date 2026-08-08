# v4.7.3 bidirectional-stress correction

v4.7.2 successfully compiled and ran, but its reverse-direction stress had a
methodological contamination: STONKBROKER inventory was acquired by first
buying it through the same pool. That seed purchase shifted the pool before
the STONK->WETH trials.

v4.7.3 fixes this by:
- installing forge-std in the GitHub Actions fork workspace;
- sizing the reverse grid with a temporary 1 WETH swap, then reverting it;
- assigning synthetic STONKBROKER inventory with `deal()` on the fork only;
- starting every WETH->STONK and STONK->WETH trial from the same baseline;
- requiring WETH->STONK tick deltas to be <= 0 and STONK->WETH deltas >= 0;
- requiring both directions to show a non-zero move;
- adding these invariants to the decision gate.

No mainnet write path is introduced.
