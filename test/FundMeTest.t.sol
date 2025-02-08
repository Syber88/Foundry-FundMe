// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;
    

    function setUp() external{
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    
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

    function testFundUpdatesFundedDataStructures() public {
        fundMe.fund{value: 7e18}();
    }
}