/// join.t.sol -- test for join.sol

// Copyright (C) 2019 lucasvo

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

import "ds-test/test.sol";

import "../join.sol";


contract Hevm {
    function warp(uint256) public;
}


contract MockVat {
    address public  src;
    address public  dst;
    uint    public  wad;

    function move(address src_, address dst_, uint wad_) external {
        src = src_;
        dst = dst_;
        wad = wad_;
        return; 
    }
}

contract MockPot {
    uint public chi;
    uint public wad;

    function file(uint chi_) external {
        chi = chi_;
    }
    function join(uint256 wad_) external {
        wad = wad_;
    }
    function exit(uint256 wad_) external {
        wad = wad_;
    }
}

contract MockChai{
    address public usr;
    uint    public wad;

    function mint(address usr_, uint wad_) public {
        usr = usr_;
        wad = wad_;
    }

    function burn(address usr_, uint wad_) public {
        usr = usr_;
        wad = wad_;
    }
}

contract JoinUser {
    ChaiJoin join;
    constructor (ChaiJoin join_) public {
        join = join_;
    }

    function doJoin(address usr, uint wad) public {
        join.join(usr, wad);
    }
    function doExit(address usr, uint wad) public {
        join.exit(usr, wad);
    }
}

contract ChaiTest is DSTest {
    ChaiJoin  join;
    Hevm      hevm;
    JoinUser  user;

    MockPot   pot;
    MockVat   vat;
    MockChai  chai;

    function setUp() public {
        pot  = new MockPot();
        vat  = new MockVat();
        chai = new MockChai();
        join = new ChaiJoin(address(vat), address(chai), address(pot));
        user = new JoinUser(join);
    }

    function testJoin() public {
        pot.file(5);
        user.doJoin(address(0), 10);
        assertEq(vat.src(), address(join));
        assertEq(vat.dst(), address(0));
        assertEq(vat.wad(), 10*10**27);
        assertEq(chai.usr(), address(user));
        assertEq(chai.wad(), 2);
        assertEq(pot.wad(), 2);
    }
    
    function testExit() public {
        pot.file(5);
        user.doExit(address(0), 10);
        assertEq(vat.src(), address(user));
        assertEq(vat.dst(), address(join));
        assertEq(vat.wad(), 10*10**27);
        assertEq(chai.usr(), address(0));
        assertEq(chai.wad(), 2);
        assertEq(pot.wad(), 2);
    }
    

}   
