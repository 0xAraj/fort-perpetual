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
        uint256 sizeInToken; // amount of token from size of position
        STRATEGY strategy; // strategy selected by user like LONG OR SHORT
    }

    /**
     * @dev `Protocol` keeps track of all info at protocol level
     */
    struct Protocol {
        address asset; // asset address protocol is taking as collateral ie USDC
        uint256 MAX_LEVERAGE; // max leverage, a trader is allowed to take
        uint256 openInterestLong; // open position of whole protocol in  LONG
        uint256 openInterestShort; // open position of whole protocol in  SHORT
        uint256 openInterestLongInToken; // open position of whole protocol of LONG in BTC
        uint256 openInterestShortInToken; // open position of whole protocol of SHORT in BTC
    }

    /**
     * @dev `STRATEGY` that protocol is offering
     */
    enum STRATEGY {
        LONG,
        SHORT
    }
}
