/// deal.sol -- Deal Chai and Dai 

// Copyright (C) 2019 Rain <rainbreak@riseup.net>, lucasvo
//
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

contract TokenLike {
    function transferFrom(address,address,uint) public;
}

contract VatLike {
    function move(address,address,uint) external;
    function hope(address) external;
}

contract PotLike {
    function chi() external returns (uint256);
}

contract JoinLike {
    function join(address, uint) external;
    function exit(address, uint) external;
}

contract Dealer {
    VatLike public vat;
    TokenLike public chai;
    TokenLike public dai;
    PotLike public pot;
    JoinLike public joinc;
    JoinLike public joind;

    uint256 constant ONE = 10 ** 27;

    function div(uint x, uint y) internal pure returns (uint z) {
        z = x / y / ONE;
    }

    constructor(address vat_, address dai_, address chai_, address joinc_, address joind_, address pot_) public {
        vat = VatLike(vat_);
        dai = TokenLike(dai_);
        chai = TokenLike(chai_);
        pot = PotLike(pot_);
        joinc = JoinLike(joinc_);
        joind = JoinLike(joind_);

        vat.hope(address(joinc));
        vat.hope(address(joind));
    }

    // move dai to chai 
    function make(uint wad) external {
        dai.transferFrom(msg.sender, address(this), wad);
        joind.join(address(this), wad);
        joinc.exit(msg.sender, wad); 
    }

    // move chai to dai
    function take(uint wad) external {
        uint lot = div(wad, pot.chi());
        chai.transferFrom(msg.sender, address(this), lot);
        joinc.join(address(this), wad);
        joind.exit(msg.sender, wad);
    }
}
