//SPDX-license-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FORTDeposit} from "./FORTDeposit.sol";

/**
 * @title FORTVult
 * @author Aditya
 * @notice Main point for LP(liquidity providers) to interect with vault
 * @dev This contract take USDC as deposit from LP and mint them vUSDC proportion to their deposit
 */
contract FORTVault is ERC4626 {
    FORTDeposit fortDeposit;

    // ERRORS //
    error FORTVault_MaxWithdrawLimitReached();

    /**
     * @dev Sets LpToken(vUSDC) and FortDeposit contract
     * @param _asset token that LP will provide as liquidity ie USDC
     * @param _depositAddress address of deployed FORTDeposit contract
     */
    constructor(IERC20 _asset, address _depositAddress) ERC4626(_asset) ERC20("Vault USDC", "vUSDC") {
        fortDeposit = FORTDeposit(_depositAddress);
    }

    /**
     * @dev Override the totalAssets function of ERC4626
     */
    function totalAssets() public view override returns (uint256) {
        return fortDeposit.setTotalAsset();
    }

    /**
     * @dev Override the withdraw function to limit LP not to withdraw more than limit
     * @param _asset  amount asset LP wanted to withdraw
     * @param receiver address who will receice the token ie USDC
     * @param owner owner of the token
     */
    function withdraw(uint256 _asset, address receiver, address owner) public override returns (uint256) {
        bool isWithdrawable = fortDeposit._isEnoughLPBacking(0, 0, _asset);
        if (!isWithdrawable) {
            revert FORTVault_MaxWithdrawLimitReached();
        }
        super.withdraw(_asset, receiver, owner);
    }
}
