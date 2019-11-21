/// chai.t.sol -- tests for chai.sol

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico, lucasvo, livnev

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
import {Vat} from 'dss/vat.sol';
import {Pot} from 'dss/pot.sol';
import {Dai} from 'dss/dai.sol';
import {DaiJoin} from 'dss/join.sol';
import "../chai.sol";

contract Hevm {
    function warp(uint256) public;
}

contract ChaiSetup {
    Chai chai;

    Vat vat;
    Pot pot;
    Dai dai;
    DaiJoin daiJoin;
    address vow;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }

    function setUp() public {
        // set up Vat, Pot, and Dai
        vat = new Vat();
        pot = new Pot(address(vat));
        dai = new Dai(99);
        daiJoin = new DaiJoin(address(vat), address(dai));
        vat.rely(address(pot));
        // vat.hope(address(pot));
        dai.rely(address(daiJoin));

        // use a dummy vow
        vow = address(bytes20("vow"));
        pot.file("vow", vow);

        // set up Chai
        chai = new Chai(99, address(vat), address(pot), address(dai), address(daiJoin));

        // gives this 100 dai to play with
        vat.suck(address(this), address(this), rad(100 ether));
        vat.hope(address(daiJoin));
        daiJoin.exit(address(this), 100 ether);

        dai.approve(address(daiJoin), uint(-1));
        dai.approve(address(chai), uint(-1));
    }
}

contract ChaiTest is DSTest, ChaiSetup {
    Hevm hevm;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);
        super.setUp();
    }

    function test_initial_balance() public {
        assertEq(dai.balanceOf(address(this)), 100 ether);
    }

    function test_join_then_exit() public {
        chai.join(address(this), 10 ether);
        assertEq(dai.balanceOf(address(this)),  90 ether);
        assertEq(chai.balanceOf(address(this)), 10 ether);
        chai.exit(address(this), 10 ether);
        assertEq(chai.balanceOf(address(this)),  0 ether);
        assertEq(dai.balanceOf(address(this)), 100 ether);
    }

    function testFail_join_then_exit_too_much() public {
        chai.join(address(this), 10 ether);
        chai.exit(address(this), 10 ether + 1);
    }

    function test_save_1d() public {
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        chai.join(address(this), 10 ether);
        assertEq(chai.balanceOf(address(this)), 10 ether);
        hevm.warp(now + 1 days);
        assertEq(chai.balanceOf(address(this)), 10 ether);
        chai.exit(address(this), 10 ether);
        assertEq(dai.balanceOf(address(this)), 100 ether + 0.5 ether);
    }

    function test_save_2d() public {
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        chai.join(address(this), 10 ether);
        assertEq(chai.balanceOf(address(this)), 10 ether);
        hevm.warp(now + 1 days);
        assertEq(chai.balanceOf(address(this)), 10 ether);

        pot.drip();
        pot.file("dsr", uint(1000001103127689513476993127));  // 10% / day

        hevm.warp(now + 1 days);
        assertEq(chai.balanceOf(address(this)), 10 ether);
        chai.exit(address(this), 10 ether);
        assertEq(dai.balanceOf(address(this)), 100 ether + 1.55 ether);
    }
}

contract ChaiUser {
    Chai token;

    constructor(Chai token_) public {
        token = token_;
    }

    function doTransferFrom(address from, address to, uint amount)
        public
        returns (bool)
    {
        return token.transferFrom(from, to, amount);
    }

    function doTransfer(address to, uint amount)
        public
        returns (bool)
    {
        return token.transfer(to, amount);
    }

    function doApprove(address recipient, uint amount)
        public
        returns (bool)
    {
        return token.approve(recipient, amount);
    }

    function doAllowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return token.allowance(owner, spender);
    }

    function doBalanceOf(address who) public view returns (uint) {
        return token.balanceOf(who);
    }

    function doApprove(address guy)
        public
        returns (bool)
    {
        return token.approve(guy, uint(-1));
    }
}

contract TokenTest is DSTest, ChaiSetup {
    Hevm hevm;

    uint constant initialBalanceThis = 20 ether;
    uint constant initialBalanceCal = 10 ether;

    address user1;
    address user2;
    address self;

    uint amount = 2;
    uint fee = 1;
    uint nonce = 0;
    uint deadline = 0;
    address cal = 0x29C76e6aD8f28BB1004902578Fb108c507Be341b;
    address del = 0xdd2d5D3f7f1b35b7A0601D6A00DbB7D44Af58479;
    bytes32 r = 0x66ac2e2213059ebd3d1d05027122eeb18ef4d80ba256499014479c3facc19df9;
    bytes32 s = 0x5fed942c61fa87fd050619f947ce59cb3157f90d1279de9ec8d2f3edec639fd8;
    uint8 v = 27;
    bytes32 _r = 0x3168c59cb4fa9b54016ebf3d56dcca900ccfb92fb55b0af86dfe919c125e4755;
    bytes32 _s = 0x013d4a55b43099981f7fed3af5606e1c8469f6f18ccea62d412809376f0a57a3;
    uint8 _v = 27;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);
        super.setUp();
        chai.join(address(this), initialBalanceThis);
        // have to join via this because cal can't approve chai
        chai.join(address(this), initialBalanceCal);
        chai.transfer(cal, initialBalanceCal);
        user1 = address(new ChaiUser(chai));
        user2 = address(new ChaiUser(chai));
        self = address(this);
    }

    function testSetupPrecondition() public {
        assertEq(chai.balanceOf(self), initialBalanceThis);
    }

    function testTransferCost() public logs_gas {
        chai.transfer(address(0), 10);
    }

    function testAllowanceStartsAtZero() public logs_gas {
        assertEq(chai.allowance(user1, user2), 0);
    }

    function testValidTransfers() public logs_gas {
        uint sentAmount = 250;
        emit log_named_address("chai11111", address(chai));
        chai.transfer(user2, sentAmount);
        assertEq(chai.balanceOf(user2), sentAmount);
        assertEq(chai.balanceOf(self), initialBalanceThis - sentAmount);
    }

    function testFailWrongAccountTransfers() public logs_gas {
        uint sentAmount = 250;
        chai.transferFrom(user2, self, sentAmount);
    }

    function testFailInsufficientFundsTransfers() public logs_gas {
        uint sentAmount = 250;
        chai.transfer(user1, initialBalanceThis - sentAmount);
        chai.transfer(user2, sentAmount + 1);
    }

    function testApproveSetsAllowance() public logs_gas {
        emit log_named_address("Test", self);
        emit log_named_address("Chai", address(chai));
        emit log_named_address("Me", self);
        emit log_named_address("User 2", user2);
        chai.approve(user2, 25);
        assertEq(chai.allowance(self, user2), 25);
    }

    function testChargesAmountApproved() public logs_gas {
        uint amountApproved = 20;
        chai.approve(user2, amountApproved);
        assertTrue(ChaiUser(user2).doTransferFrom(self, user2, amountApproved));
        assertEq(chai.balanceOf(self), initialBalanceThis - amountApproved);
    }

    function testFailTransferWithoutApproval() public logs_gas {
        chai.transfer(user1, 50);
        chai.transferFrom(user1, self, 1);
    }

    function testFailChargeMoreThanApproved() public logs_gas {
        chai.transfer(user1, 50);
        ChaiUser(user1).doApprove(self, 20);
        chai.transferFrom(user1, self, 21);
    }
    function testTransferFromSelf() public {
        chai.transferFrom(self, user1, 50);
        assertEq(chai.balanceOf(user1), 50);
    }
    function testFailTransferFromSelfNonArbitrarySize() public {
        // you shouldn't be able to evade balance checks by transferring
        // to yourself
        chai.transferFrom(self, self, chai.balanceOf(self) + 1);
    }
    function testFailUntrustedTransferFrom() public {
        assertEq(chai.allowance(self, user2), 0);
        ChaiUser(user1).doTransferFrom(self, user2, 200);
    }
    function testTrusting() public {
        assertEq(chai.allowance(self, user2), 0);
        chai.approve(user2, uint(-1));
        assertEq(chai.allowance(self, user2), uint(-1));
        chai.approve(user2, 0);
        assertEq(chai.allowance(self, user2), 0);
    }
    function testTrustedTransferFrom() public {
        chai.approve(user1, uint(-1));
        ChaiUser(user1).doTransferFrom(self, user2, 200);
        assertEq(chai.balanceOf(user2), 200);
    }
    function testApproveWillModifyAllowance() public {
        assertEq(chai.allowance(self, user1), 0);
        assertEq(chai.balanceOf(user1), 0);
        chai.approve(user1, 1000);
        assertEq(chai.allowance(self, user1), 1000);
        ChaiUser(user1).doTransferFrom(self, user1, 500);
        assertEq(chai.balanceOf(user1), 500);
        assertEq(chai.allowance(self, user1), 500);
    }
    function testApproveWillNotModifyAllowance() public {
        assertEq(chai.allowance(self, user1), 0);
        assertEq(chai.balanceOf(user1), 0);
        chai.approve(user1, uint(-1));
        assertEq(chai.allowance(self, user1), uint(-1));
        ChaiUser(user1).doTransferFrom(self, user1, 1000);
        assertEq(chai.balanceOf(user1), 1000);
        assertEq(chai.allowance(self, user1), uint(-1));
    }
    function testDaiAddress() public {
        //The dai address generated by hevm
        //used for signature generation testing
        assertEq(address(chai), address(0x0F1c6673615352379AFC1a60e3D0234101D67eb2));
    }

    function testTypehash() public {
        assertEq(chai.PERMIT_TYPEHASH(), 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb);
    }

    function testDomain_Separator() public {
        assertEq(chai.DOMAIN_SEPARATOR(), 0x12bf37c2cc038856d7efae7381c12376dea490731e8ad8d1f38179218de0e433);
    }

    function testPermit() public {
        assertEq(chai.nonces(cal), 0);
        assertEq(chai.allowance(cal, del), 0);
        chai.permit(cal, del, 0, 0, true, v, r, s);
        assertEq(chai.allowance(cal, del),uint(-1));
        assertEq(chai.nonces(cal),1);
    }

    function testFailPermitAddress0() public {
        v = 0;
        chai.permit(address(0), del, 0, 0, true, v, r, s);
    }

    function testPermitWithExpiry() public {
        assertEq(now, 604411200);
        chai.permit(cal, del, 0, 604411200 + 1 hours, true, _v, _r, _s);
        assertEq(chai.allowance(cal, del),uint(-1));
        assertEq(chai.nonces(cal),1);
    }

    function testFailPermitWithExpiry() public {
        hevm.warp(now + 2 hours);
        assertEq(now, 604411200 + 2 hours);
        chai.permit(cal, del, 0, 1, true, _v, _r, _s);
    }

    function testFailReplay() public {
        chai.permit(cal, del, 0, 0, true, v, r, s);
        chai.permit(cal, del, 0, 0, true, v, r, s);
    }
}
