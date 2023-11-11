//SPDX-license-Identifier: MIT
pragma solidity 0.8.20;

import {FORTStructs} from "./FORTStructs.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title FORTDeposit
 * @author Aditya
 * @notice Main point for traders to interect with protocol
 * @dev This contract takes USDC from traders as collateral and allow them to open position for BTC upto 15x leverage
 */
contract FORTDeposit {
    // ERRORS //
    error FORTDeposit_AssetNotMatched();
    error FORTDeposit_ZeroAmount();
    error FORTDeposit_MaxLeverageReached();

    // EVENTS //
    event PositionCreated(address trader, uint256 collateralAmount, uint256 sizeAmount, bool isLong);

    // STATE VARIABLES //
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant PRICE_FEED_ADJUSTMENT = 1e10;

    // STRUCT //
    FORTStructs.Protocol public protocol;

    // MAPPING //
    mapping(address trader => FORTStructs.Trader) public s_addressToTraderPosition;

    // PRICE FEED //
    /**
     * @dev Hardcoding the address of BTC/USD on sepolia network
     */
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);

    /**
     * @notice Sets the addresss of collateral token ie USDC and max leverage of the protocol
     * @param _asset address of the collateral token
     * @param _maxLeverage max leverage allowed for trader
     */
    constructor(address _asset, uint256 _maxLeverage) {
        protocol.asset = _asset;
        protocol.MAX_LEVERAGE = _maxLeverage;
    }

    /**
     * @dev This function allows traders to create position of given size for BTC by depositing collateral(USDC)
     * @param _asset address of collateral token ie USDC
     * @param _collateralAmount amount of collateral trader want to deposit
     * @param _sizeAmount amount for which trader wants to open position for
     */
    function createPosition(address _asset, uint256 _collateralAmount, uint256 _sizeAmount, bool isLong) external {
        // Checking if params are correct or not
        if (protocol.asset != _asset) {
            revert FORTDeposit_AssetNotMatched();
        }
        if (_collateralAmount == 0) {
            revert FORTDeposit_ZeroAmount();
        }
        // (10,000 * 1e18) / 1000 = 10e18
        uint256 leverage = (_sizeAmount * PRECISION) / _collateralAmount;
        // 10e18 < 15e18 ie Max leverage
        if (leverage > protocol.MAX_LEVERAGE) {
            revert FORTDeposit_MaxLeverageReached();
        }

        // creating trader position
        FORTStructs.Trader memory trader;
        trader.user = msg.sender; // think of removing it
        trader.collateral += _collateralAmount;
        trader.size += _sizeAmount;
        trader.leverage = leverage;
        //set the leverage which you get form health check
        if (isLong) {
            trader.strategy = FORTStructs.STRATEGY.LONG;
        }

        s_addressToTraderPosition[msg.sender] = trader;

        // updating the protocol data
        uint256 tokenAmount = _getTokenAmountFromSize(_sizeAmount);
        protocol.openInterest += _sizeAmount;
        protocol.openInterestInToken += tokenAmount;
        emit PositionCreated(msg.sender, _collateralAmount, _sizeAmount, isLong);
    }

    /**
     * @dev Calculates how much BTC token in given amount
     * @param _sizeAmount amount for which we are calculating BTC
     * @return tokenAmount amount of BTC that we get in _sizeAmount
     */
    function _getTokenAmountFromSize(uint256 _sizeAmount) internal view returns (uint256 tokenAmount) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        // price of BTC is in 8 decimal,so multiplying it by 1e10 to make 1e18
        tokenAmount = (_sizeAmount * PRECISION) / ((uint256(price)) * PRICE_FEED_ADJUSTMENT);
    }
}
