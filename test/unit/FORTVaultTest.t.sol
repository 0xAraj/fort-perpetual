//SPDX-license-Identifier: MIT
pragma solidity 0.8.20;

import {FORTDeposit} from "../../src/FORTDeposit.sol";
import {FORTVault} from "../../src/FORTVault.sol";
import {FORTStructs} from "../../src/FORTStructs.sol";
import {MockUSDC} from "../mocks/MockUSDC.sol";
import {Test, console2} from "forge-std/Test.sol";

contract FORTVaultTest is Test {
    uint256 public constant MAX_LEVERAGE = 15e18;

    FORTDeposit fortDeposit;
    FORTVault fortVault;
    MockUSDC USDC;

    function setUp() public {
        USDC = new MockUSDC();
        fortVault = new FORTVault(USDC, MAX_LEVERAGE);
        address fortDepositAddress = fortVault.getFortDepositAddress();
        fortDeposit = FORTDeposit(fortDepositAddress);
    }

    function test_return_underlying_token() public view {
        address asset = fortVault.asset();
        console2.log(asset);
        assert(asset == address(USDC));
    }
}
