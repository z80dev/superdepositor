// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import {SuperDepositor} from "../SuperDepositor.sol";

import "@std/Test.sol";
import "solmate/tokens/ERC20.sol";
import "../interfaces/IBeetVault.sol";

contract DummyToken is ERC20 {
    constructor() ERC20("Test", "TST", 18) {}

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

contract SuperDepositorTest is Test {

    SuperDepositor depositor;
    DummyToken dummyToken;

    address balVault = address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);

    address alice = address(0xc5ed2333f8a2C351fCA35E5EBAdb2A82F5d254C3);
    address bob = address(0xbb);

    ERC20 usdc = ERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    ERC20 dai = ERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);

    bytes32 steadybeets2 = bytes32(0xecaa1cbd28459d34b766f9195413cb20122fb942000200000000000000000120);
    ERC20 steadybeets2lp = ERC20(0xeCAa1cBd28459d34B766F9195413Cb20122Fb942);
    ERC20 steadybeets2crypt = ERC20(0x77A495c99Df9d945Ca0D407eE04749cCDe6EEaa0);


    function setUp() public {
        console.log(unicode"🧪 Testing Depositor...");
        depositor = new SuperDepositor(balVault);
        dummyToken = new DummyToken();
        dummyToken.mint(alice, 100000000);
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    function testSetup() public {
        assertEq(dummyToken.balanceOf(alice), 100000000);
    }

    function testLogBalance() public {
        console.log(usdc.balanceOf(alice));
    }

    function testSingleSideDepositTakesTokens() public {
        vm.startPrank(alice);
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(address(usdc));
        assets[1] = IAsset(address(dai));
        SuperDepositor.DepositParams memory deposit = SuperDepositor.DepositParams(assets,
                                                                            0,
                                                                            steadybeets2,
                                                                                   address(steadybeets2lp),
                                                                            address(steadybeets2crypt),
                                                                            alice
                                                                            );
        usdc.approve(address(depositor), 100);
        depositor.singleSideDeposit(deposit, 100);
        console.log(steadybeets2crypt.balanceOf(alice));
    }

}
