// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico, lucasvo

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.0;

contract VatLike {
    function hope(address) external;
}

contract PotLike {
    function chi() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

contract JoinLike {
    function join(address, uint) external;
    function exit(address, uint) external;
}

contract GemLike {
    function transferFrom(address,address,uint) external returns (bool);
}

contract Chai {
    // --- Data ---
    VatLike  public vat;
    PotLike  public pot;
    GemLike  public dai;
    JoinLike public daiJoin;

    // --- ERC20 Data ---
    string  public constant name     = "Chai";
    string  public constant symbol   = "CHAI";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    uint constant ONE = 10 ** 27;
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function div(uint x, uint y) internal pure returns (uint z) {
        z = x / y;
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"));
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    // keccak256("Join(address usr,uint256 wad,uint256 fee,uint256 nonce,uint256 expiry)"));
    bytes32 public constant JOIN_TYPEHASH = 0x701f8b62cdcbd2bd6d6bd1865186d960c371ab604e92406ac3d6a22ad8ed0547;
    // keccak256("Exit(address usr,uint256 wad,uint256 fee,uint256 nonce,uint256 expiry)"));
    bytes32 public constant EXIT_TYPEHASH = 0xab009dd688ed654007de4a45b77e1314a1efa28c92cfd01f6c132d967f3a27da;


    constructor(uint256 chainId_, address vat_, address join_, address pot_, address dai_) public {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));

        vat = VatLike(vat_);
        pot = PotLike(pot_);
        daiJoin = JoinLike(join_);
        dai = GemLike(dai_);

        vat.hope(join_);
        vat.hope(pot_);

    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad)
        public returns (bool)
    {
        require(balanceOf[src] >= wad, "chai/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "chai/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint wad) external {
        transferFrom(msg.sender, usr, wad);
    }
    function pull(address usr, uint wad) external {
        transferFrom(usr, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }


    // --- Magic ---
    // wad is denominated in dai
    function join(address usr, address dst, uint wad) internal {
        dai.transferFrom(usr, address(this), wad);

        daiJoin.join(address(this), wad);
        uint pie = div(mul(ONE, wad), pot.chi());
        pot.join(pie);

        balanceOf[dst] = add(balanceOf[dst], pie);
        totalSupply    = add(totalSupply, pie);
        emit Transfer(address(0), dst, pie);
    }
    function join(address dst, uint wad) external {
        join(msg.sender, dst, wad);
    }
    function join(address usr, uint wad, uint fee, uint nonce, uint expiry, bytes32 r, bytes32 s, uint8 v, address taxman) external {
         bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(JOIN_TYPEHASH,
                                     usr,
                                     wad,
                                     fee,
                                     nonce,
                                     expiry))
        ));
        require(usr == ecrecover(digest, v, r, s), "chai/invalid-permit");
        require(expiry == 0 || now <= expiry, "chai/permit-expired");
        require(nonce == nonces[usr]++, "chai/invalid-nonce");
        join(usr, wad);
        dai.transferFrom(usr, taxman, fee);
    }

    // wad is denominated in pie
    function exit(address usr, uint wad) public {
        require(balanceOf[usr] >= wad, "chai/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint(-1)) {
            require(allowance[usr][msg.sender] >= wad, "chai/insufficient-allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply    = sub(totalSupply, wad);

        pot.exit(wad);
        daiJoin.exit(msg.sender, div(mul(pot.chi(), wad), ONE));
        emit Transfer(usr, address(0), wad);
    }
    function exit(address usr, uint wad, uint fee, uint nonce, uint expiry,
                  bytes32 r, bytes32 s, uint8 v, address taxman)  external {
         bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(EXIT_TYPEHASH,
                                     usr,
                                     wad,
                                     fee,
                                     nonce,
                                     expiry))
        ));
        require(usr == ecrecover(digest, v, r, s), "chai/invalid-permit");
        require(expiry == 0 || now <= expiry, "chai/permit-expired");
        require(nonce == nonces[usr]++, "chai/invalid-nonce");
        exit(usr, wad);
        dai.transferFrom(usr, taxman, fee);
    }

    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));
        require(holder == ecrecover(digest, v, r, s), "chai/invalid-permit");
        require(expiry == 0 || now <= expiry, "chai/permit-expired");
        require(nonce == nonces[holder]++, "chai/invalid-nonce");
        uint wad = allowed ? uint(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}
