// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

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
        assertEq(fundMe.getOwner(), msg.sender);
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

    function testWithdrawFromActualOwnerSingleFunder() public {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 ownerPostWithdrawBalance = fundMe.getOwner().balance;
        uint256 fundMePostWithdrawalBalance = address(fundMe).balance;

        assertEq(fundMePostWithdrawalBalance, 0);
        assertEq(ownerPostWithdrawBalance, startingOwnerBalance + startingFundMeBalance); //since only one funding transaction was made
    }

    function testWithdrawFromActualOwnerMultipleFunders() public funded{
        uint160 numberOffunders = 10;
        uint160 startignFunderIndex = 1;
        for (uint160 i = startignFunderIndex; i < numberOffunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 fundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();


        assert(address(fundMe).balance == 0);
        assert(fundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }

    function testWithdrawFromActualOwnerMultipleFundersCheaper() public funded{
        uint160 numberOffunders = 10;
        uint160 startignFunderIndex = 1;
        for (uint160 i = startignFunderIndex; i < numberOffunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 fundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();


        assert(address(fundMe).balance == 0);
        assert(fundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }
}