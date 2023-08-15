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

contract Revoke is Base {
    bytes32 internal revocableVestingScheduleId;
    bytes32 internal unrevocableVestingScheduleId;
    
    function setUp() public override {
        Base.setUp();
    }

    modifier withCreatedVestingSchedule(uint256 amount, bool revocable) {
        vm.assume(amount > 0);
        deal(address(erc20Token), address(tokenVesting), amount);

        if (revocable) {
            // create a revocable vesting schedule
            revocableVestingScheduleId = tokenVesting.computeNextVestingScheduleIdForHolder(users.alice);
            tokenVesting.createVestingSchedule(users.alice, block.timestamp, 0, 300, 1, true, amount);
        } else {
            // create a unrevocable vesting schedule
            unrevocableVestingScheduleId = tokenVesting.computeNextVestingScheduleIdForHolder(users.alice);
            tokenVesting.createVestingSchedule(users.alice, block.timestamp, 0, 300, 1, false, amount);
        }
        _;
    }

    function test_RevertWhen_VestingScheduleIsNotRevocable() external whenOwner withCreatedVestingSchedule(100, false) {
        vm.expectRevert(bytes("TokenVesting: vesting is not revocable"));
        tokenVesting.revoke(unrevocableVestingScheduleId);
    }

    function testFuzz_WhenRevokeWithZeroVestedAmount_VestingScheduleTotalAmountShouldBeDecreased_ByAnAmount(uint256 amount) external whenOwner withCreatedVestingSchedule(amount, true) {
        uint256 vestingScheduleTotalAmount = tokenVesting.getVestingSchedulesTotalAmount();
        tokenVesting.revoke(revocableVestingScheduleId);
        assertEq(tokenVesting.getVestingSchedulesTotalAmount(), vestingScheduleTotalAmount - amount);
    }

    function testFuzz_WhenRevokeWithSomeVestedAmount_ShouldReleaseTokens(uint256 amount, uint256 nextTimestamp) external whenOwner withCreatedVestingSchedule(amount, true) {
        nextTimestamp = bound(nextTimestamp, 1, 300);
        vm.warp(nextTimestamp);

        uint256 releasableAmount = tokenVesting.computeReleasableAmount(revocableVestingScheduleId);

        assertEq(erc20Token.balanceOf(users.alice), 0);
        tokenVesting.revoke(revocableVestingScheduleId);
        assertEq(erc20Token.balanceOf(users.alice), releasableAmount);
    } 
}

contract Withdraw is Base {
    function setUp() public override {
        Base.setUp();
    }

    function testFuzz_ShouldWithdrawable(uint256 amount) external whenOwner {
        deal(address(erc20Token), address(tokenVesting), amount);
        tokenVesting.withdraw(amount);

        assertEq(erc20Token.balanceOf(tokenVesting.owner()), amount);
    }
}
