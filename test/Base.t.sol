pragma solidity >=0.8.19;

import { Test } from "forge-std/Test.sol";

abstract contract Base is Test {
    /// User info
    struct Users {
        address payable alice;
        address payable bob;
    }
    
    Users internal users;

    function setUp() public virtual {
        users = Users({
            alice: createUser("alice"),
            bob: createUser("bob")
        });
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        return user;
    }
}
