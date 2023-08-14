pragma solidity >=0.8.19;

import { Base } from "./Base.t.sol";
import "forge-std/console2.sol";
import {stdError} from "forge-std/stdError.sol";

contract GetWithdrawableAmount is Base {
    function setUp() public override {
        Base.setUp();
    }

    function testFuzz_RevertWhen_TokenBalanceLessThanVestingSchedulesTotalAmount(uint256 tokenBalance, uint256 vestingSchedulesTotalAmount) whenOwner whenTokenBalanceInContract_LessThan_VestingSchedulesTotalAmount(tokenBalance, vestingSchedulesTotalAmount) external {

        vm.expectRevert(stdError.arithmeticError);
        tokenVesting.getWithdrawableAmount();
    }

}

contract CreateVestingSchedule is Base {
    function setUp() public override {
        Base.setUp();
    }

    function testFuzz_RevertWhen_InputAmountGreaterThan_WithdrawableAmount(uint256 inputAmount, uint256 tokenBalance) external whenOwner whenHaveTokenBalance(tokenBalance) {
        vm.assume(inputAmount > tokenBalance);
        vm.expectRevert(bytes("TokenVesting: cannot create vesting schedule because not sufficient tokens"));
        tokenVesting.createVestingSchedule(users.alice, block.timestamp, 0, 300, 1, false, inputAmount); 
    }

    function test_RevertWhen_AmountIsZero() external whenOwner whenHaveTokenBalance(100) {
        vm.expectRevert(bytes(
            "TokenVesting: amount must be > 0"
        ));
        tokenVesting.createVestingSchedule(users.alice, block.timestamp, 0, 300, 1, false, 0);
    }


    function test_RevertWhen_BeneficiaryIsZeroAddress() external whenOwner whenHaveTokenBalance(100) {
        vm.expectRevert(bytes(
            "TokenVesting: beneficiary is zero address"
        ));
        tokenVesting.createVestingSchedule(address(0), block.timestamp, 0, 300, 1, false, 100);
    }

    function test_RevertWhen_DurationIsZero() external whenOwner whenHaveTokenBalance(100) {
        vm.expectRevert(bytes(
            "TokenVesting: duration must be > 0"
        ));
        tokenVesting.createVestingSchedule(users.alice, block.timestamp, 0, 0, 1, false, 100);
    }

    function test_RevertWhen_SlicePerPeriodsIsZero() external whenOwner whenHaveTokenBalance(100) {
        vm.expectRevert(bytes(
            "TokenVesting: slicePeriodSeconds must be >= 1"
        ));
        tokenVesting.createVestingSchedule(users.alice, block.timestamp, 0, 300, 0, false, 100);
    }

    function testFuzz_RevertWhen_DurationIsLessThanCliff(uint256 duration, uint256 cliff) external whenOwner whenHaveTokenBalance(100) {
        vm.assume(duration > 0);
        vm.assume(duration < cliff);
        vm.expectRevert(bytes(
            "TokenVesting: duration must be >= cliff"
        ));
        tokenVesting.createVestingSchedule(users.alice, block.timestamp, cliff, duration, 1, false, 100);
    }
}
