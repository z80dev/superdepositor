// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./interfaces/IBeetVault.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title Greeter
/// @author andreas@nascent.xyz
contract SuperDepositor {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable balVault;

    // this will hold all the data we need to:
    // 1. Deposit our funds into Beethoven and obtain LPs
    // 2. Deposit those LPs into reaper and obtain vault shares
    // 3. Transfer those vault shares to the intended recipient
    struct DepositParams {
        IAsset[] underlyings;
        uint256 depositTokenIndex;
        bytes32 beetsPoolId;
        address lpToken; // needed for approval to deposit
        address vault;
        address recipient;
    }

    constructor(address _balVault) {
        balVault = _balVault;
    }

    function singleSideDeposit(DepositParams memory details, uint256 amount) public {
        IERC20Upgradeable inputToken = IERC20Upgradeable(address(details.underlyings[details.depositTokenIndex]));
        inputToken.safeTransferFrom(msg.sender, address(this), amount);
        _joinPool(details.underlyings, amount, details.depositTokenIndex, details.beetsPoolId); // contract has lp tokens
        _depositLPToVault(details.lpToken, details.vault, details.recipient);
    }

    function _depositLPToVault(address lp, address vault, address recipient) internal {

        // approve lp
        _approveIfNeeded(vault, lp); // sets to max if needed

        // deposit lp
        IVault(vault).depositAll();

        // transfer to user
        IERC20Upgradeable shares = IERC20Upgradeable(vault);
        shares.safeTransfer(recipient, shares.balanceOf(address(this)));
    }

    function _approveIfNeeded(address spender, address token) internal {
        IERC20Upgradeable token = IERC20Upgradeable(token);
        if (token.allowance(address(this), spender) == uint256(0)) {
            token.safeIncreaseAllowance(spender, type(uint256).max);
        }
    }

    /**
     * @dev Joins {beetsPoolId} using {underlyings[tokenIndex]} balance;
     */
    function _joinPool(IAsset[] memory underlyings, uint256 amtIn, uint256 tokenIndex, bytes32 beetsPoolId) internal {
        uint8 joinKind = 1;

        // default values of 0 for all assets except one we're depositing with
        uint256[] memory amountsIn = new uint256[](underlyings.length);
        amountsIn[tokenIndex] = amtIn;

        uint256 minAmountOut = 1; // fix this later, slippage protection

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBeetVault.JoinPoolRequest memory request;
        request.assets = underlyings;
        request.maxAmountsIn = amountsIn;
        request.userData = userData;
        request.fromInternalBalance = false;

        IERC20Upgradeable(address(underlyings[tokenIndex])).safeIncreaseAllowance(balVault, amtIn);
        IBeetVault(balVault).joinPool(beetsPoolId, address(this), address(this), request);
    }

}
