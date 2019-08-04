/// join.sol -- Chi meets Dai. 

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

import "./lib.sol";


contract TokenLike {
    function mint(address,uint) public;
    function burn(address,uint) public;
}


contract VatLike {
    function move(address,address,uint) external;
    function hope(address) external;
}


contract PotLike {
    function chi() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

contract ChaiJoin {
    VatLike public vat;
    TokenLike public chai;
    PotLike public pot;

    uint256 constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        z = x / y;
    }

    constructor(address vat_, address chai_, address pot_) public {
        vat = VatLike(vat_);
        chai = TokenLike(chai_);
        pot = PotLike(pot_);
        vat.hope(pot_);
    }

    function join(address usr, uint wad) public {
        uint lot = div(mul(ONE, wad), pot.chi());
        pot.exit(lot);
        chai.burn(msg.sender, lot);
        vat.move(address(this), usr, mul(ONE, wad));
    }

    function exit(address usr, uint wad) public {
        vat.move(msg.sender, address(this), mul(ONE, wad));
        uint lot = div(mul(ONE, wad), pot.chi());
        pot.join(lot);
        chai.mint(usr, lot);
    }
}
