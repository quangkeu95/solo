pragma solidity >=0.8.19;

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {TokenVesting} from "src/utils/TokenVesting.sol";
import { Base as GlobalBase } from "../Base.t.sol";

abstract contract Base is GlobalBase {
    MockERC20 internal erc20Token;
    TokenVesting internal tokenVesting;

    function setUp() public virtual override {
        GlobalBase.setUp();
        erc20Token = new MockERC20("MOCK", "MOCK", 18);
        tokenVesting = new TokenVesting(address(erc20Token));
        vm.label(address(erc20Token), "MockERC20");
        vm.label(address(tokenVesting), "TokenVesting");
    }

    modifier whenCallerIsNotOwner {
        vm.startPrank(users.alice);
        _;
        vm.stopPrank();
    }

    modifier whenOwner {
        vm.startPrank(tokenVesting.owner());
        _;
        vm.stopPrank();
    }

    modifier whenTokenBalanceInContract_LessThan_VestingSchedulesTotalAmount(uint256 tokenBalance, uint256 vestingSchedulesTotalAmount) {
        vm.assume(tokenBalance > 0);
        vm.assume(tokenBalance < vestingSchedulesTotalAmount);
        
        deal(address(erc20Token), address(tokenVesting), tokenBalance);
        vm.store(address(tokenVesting), bytes32(uint(1)), bytes32(vestingSchedulesTotalAmount));
        assertEq(vestingSchedulesTotalAmount, tokenVesting.getVestingSchedulesTotalAmount());
        assertLt(erc20Token.balanceOf(address(tokenVesting)), tokenVesting.getVestingSchedulesTotalAmount());
        _;
    }

    modifier whenHaveTokenBalance(uint256 tokenBalance) {
        vm.assume(tokenBalance > 0);
        vm.assume(tokenBalance > tokenVesting.getWithdrawableAmount());
        deal(address(erc20Token), address(tokenVesting), tokenBalance);
        _;
    }

}
