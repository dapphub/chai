# 🍵

_1 Chai = 1 Dai * Pot.chi_

`chai` is an ERC20 token representing a claim on deposits in the DSR. It can be freely converted to and from `dai`: the amount of `dai` claimed by one `chai` is always increasing, at the Dai Savings Rate. Like any well-behaved token, a user's `chai` balance won't change unexpectedly.

`chai` is a very simple contract. Apart from the standard ERC20 functionality, it also implements the same `permit` off-chain approval as `dai` itself. You can also call `dai(address usr)` to check how many `dai` a given user's `chai` balance claims. The token has no owner or authority. That's all.
