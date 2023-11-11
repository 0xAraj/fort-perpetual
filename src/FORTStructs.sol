//SPDX-license-Identifier: MIT

pragma solidity 0.8.20;

/**
 * @title FORTStructs
 * @author Aditya
 * @notice This library contains all the structs used all across the protocol
 */
library FORTStructs {
    /**
     * @dev `Trader` struct contains all the related info about a particulat trader
     */
    struct Trader {
        address user; // address of the trader
        uint256 collateral; // collateral deposited by trader
        uint256 size; // open size of the trader
        uint256 leverage; // leverage of the trader
        STRATEGY strategy; // strategy selected by user like LONG OR SHORT
    }

    /**
     * @dev `Protocol` keeps track of all info at protocol level
     */
    struct Protocol {
        address asset; // asset address protocol is taking as collateral ie USDC
        uint256 MAX_LEVERAGE; // max leverage, a trader is allowed to take
        uint256 openInterest; // open position of whole protocol including LONG and SHORT in USD;
        uint256 openInterestInToken; // open position of whole protocol including LONG and SHORT in index token ie BTC
    }

    /**
     * @dev `STRATEGY` that protocol is offering
     */
    enum STRATEGY {
        LONG,
        SHORT
    }
}
