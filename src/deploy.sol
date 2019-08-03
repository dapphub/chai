/// deploy.sol -- Deploy Chai 

// Copyright (C) 2019 lucasvo
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

import {Dealer} from './deal.sol';
import './chai.sol';
import {ChaiJoin} from './join.sol';

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



contract Deploy {
    // -- Data --
    address public vat;
    address public dai;
    address public joind;
    address public pot;

    Chai      public chai;
    ChaiJoin  public joinc;
    Dealer    public dealer;

    constructor(address vat_, address dai_, address joind_, address pot_, uint256 chainId_) public {
        vat   = vat_;
        dai   = dai_;
        pot   = pot_;
        joind = joind_;

        chai   = new Chai(chainId_);
        joinc  = new ChaiJoin(vat,  address(chai), pot);
        chai.rely(address(joinc));
        chai.deny(address(this));
        dealer = new Dealer(vat, dai, address(chai), address(joinc), joind, pot);
    }
}
