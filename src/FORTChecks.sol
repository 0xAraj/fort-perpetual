//SPDX-license-Identifier: MIT
pragma solidity 0.8.20;

import {FORTStructs} from "./FORTStructs.sol";

/**
 * @title FORTChecks
 * @author Aditya
 * @notice This contract contains all the checks required in the protocol
 */

contract FORTChecks {
    FORTStructs.Protocol internal _protocol;

    error AssetNotMatched();
    error ZeroAmount();

    function _checkBeforCreatePosition(
        FORTStructs.Protocol memory _protocolInfo,
        address _asset,
        uint256 _depositAmount
    ) public pure {
        if (_protocolInfo.asset != _asset) {
            revert AssetNotMatched();
        }
        if (_depositAmount == 0) {
            revert ZeroAmount();
        }
    }
}
