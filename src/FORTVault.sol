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

    constructor(IERC20 _asset, uint256 _maxLeverage) ERC4626(_asset) ERC20("Vault USDC", "vUSDC") {
        fortDeposit = new FORTDeposit(address(_asset), _maxLeverage);
    }

    function getFortDepositAddress() public view returns (address) {
        return address(fortDeposit);
    }
}
