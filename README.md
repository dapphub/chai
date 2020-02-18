# 🍵

_1 Chai = 1 Dai * Pot.chi_

`chai` is an ERC20 token representing a claim on deposits in the DSR. It can be freely converted to and from `dai`: the amount of `dai` claimed by one `chai` is always increasing, at the Dai Savings Rate. Like any well-behaved token, a user's `chai` _balance_ won't change unexpectedly, while the `chai`'s _value_ grows day by day.

`chai` is a very simple contract. Apart from the standard ERC20 functionality, it also implements the same `permit` off-chain approval as `dai` itself. You can also call `dai(address usr)` to check how many `dai` a given user's `chai` balance claims. The token has no owner or authority. That's all there is to it.

## mainnet deployment

`chai` is live on the mainnet since December 1st at [0x06af07097c9eeb7fd685c692751d5c66db49c215](https://etherscan.io/token/0x06af07097c9eeb7fd685c692751d5c66db49c215)

You can interact with the Chai contract at [chai.money](https://chai.money). The source for the ui is hosted [here](https://github.com/lucasvo/chui).

## audit

The deployed `chai` contract underwent a two day audit by Trail Of Bits in the beginning of February, finding no security related issues.
A summary can be found [here](./ToBToB_Letter_of_Attestation_Chai.pdf).

## building and testing

This contract is built using [dapptools](http://dapp.tools/), and follows the standard dapptools procedure for building and testing.

To compile:
```sh
$ make all
```

To run the tests:
```sh
$ make test
```

## documentation

### ERC20 functions

Chai.sol implements the standard ERC20 functions (balanceOf, allowance, approve, transfer, transferFrom). 

Similar to tokens like `WETH`, `MKR` and `DAI`, an allowance of `uint(-1)` is treated as "infinity", so `transferFrom` calls from an address that has been given an allowance of `uint(-1)` will not cause the allowance to decrease.

### Join 

The chai contract is an ERC20 token where minting happens in a function called `join`, which converts a users Dai balance into Chai:
```sol
    function join(address dst, uint wad) external {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        uint pie = rdiv(wad, chi);
        balanceOf[dst] = add(balanceOf[dst], pie);
        totalSupply    = add(totalSupply, pie);

        daiToken.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(address(this), wad);
        pot.join(pie);
        emit Transfer(address(0), dst, pie);
    }
```

Calling this function transfers `wad` Dai into the `pot` contract from `msg.sender`, granting the `dst` address a Chai balance representing their claim of Dai in the `pot` contract.

### Exit

Chai is burned (converted into Dai) through a function called `exit`:
```sol
    function exit(address src, uint wad) public {
        require(balanceOf[src] >= wad, "chai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "chai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        totalSupply    = sub(totalSupply, wad);

        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        pot.exit(wad);
        daiJoin.exit(msg.sender, rmul(chi, wad));
        emit Transfer(src, address(0), wad);
    }
```
A `msg.sender` with sufficient approval from the address `src` can call this function to decrease their Chai balance by `wad` and transfer its underlying Dai value to the `msg.sender`.

### Draw

Since the `wad` argument to the `exit` function above is denominated in chai, the exact Dai transferred will be determined at the time the transaction is included in a block. If you want to ensure that a specific Dai amount must be transfered, you can use the draw function instead, which takes a dai denominated argument:

```sol
    // wad is denominated in dai
    function draw(address src, uint wad) external {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        // rounding up ensures usr gets at least wad dai
        exit(src, rdivup(wad, chi));
    }
```


### Move

Similarly to `draw`, there is a transferFrom function with a dai denominated argument, ensuring that the receiving address will receive Chai worth at least `wad` dai:

```sol
    // like transferFrom but dai-denominated
    function move(address src, address dst, uint wad) external returns (bool) {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        // rounding up ensures dst gets at least wad dai
        return transferFrom(src, dst, rdivup(wad, chi));
    }
```

### Permit

The permit method lets a user approve an address to spend on their behalf by signing a ERC712 typed message called `permit`.

A `permit` consists of the following components:

- `holder`, the address granting the permission and the signer of the message
- `spender`, the address to which permission is being granted or denied
- `nonce`, for replay attack protection
- `allowed`, whether the `spender`s permission is being granted or revoked

Messages are signed using the procedure described in [ERC712](https://eips.ethereum.org/EIPS/eip-712), using the `PERMIT_TYPEHASH` and `DOMAIN_SEPARATOR` constants:
```sol
    bytes32 public constant DOMAIN_SEPARATOR = 0x0b50407de9fa158c2cba01a99633329490dfd22989a150c20e8c7b4c1fb0fcc3;
    // keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"));
    bytes32 public constant PERMIT_TYPEHASH  = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
```

`permit` are processed by calling the `permit` method, which increments the `holder` nonce and approves the `spender` to spend on the behalf of `holder` if `allowed` is true, and revokes it otherwise:

```sol
    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH,
                                 holder,
                                 spender,
                                 nonce,
                                 expiry,
                                 allowed))));
        require(holder != address(0), "chai/invalid holder");
        require(holder == ecrecover(digest, v, r, s), "chai/invalid-permit");
        require(expiry == 0 || now <= expiry, "chai/permit-expired");
        require(nonce == nonces[holder]++, "chai/invalid-nonce");

        uint can = allowed ? uint(-1) : 0;
        allowance[holder][spender] = can;
        emit Approval(holder, spender, can);
    }
```
