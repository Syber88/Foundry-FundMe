// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 100000000000000000; //0.1eth
    uint256 constant STARTING_BALANCE = 10 ether;
    

    function setUp() external{
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);  
    }

    function testOwnerIsMsgSender()public view{
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view{
        uint256 version = fundMe.getVersion();
        if (block.chainid == 1){
            assertEq(version, 6);
        }else {
            assertEq(version, 4);
        }
    }

    function testFundFailsWithInsufficientFunds()public{
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructures() public funded{
        uint256 amountFunded = fundMe.getAddressToAmountfunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanCallWithdrawFunction() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }
}