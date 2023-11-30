//SPDX-license-Identifier: MIT
pragma solidity 0.8.20;

import {FORTStructs} from "./FORTStructs.sol";
import {FORTVault} from "./FORTVault.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title FORTDeposit
 * @author Aditya
 * @notice Main point for traders to interect with protocol
 * @dev This contract takes USDC from traders as collateral and allow them to open position for BTC upto MAX_LEVERAGE
 */
contract FORTDeposit {
    // ERRORS //
    error FORTDeposit_AssetNotMatched();
    error FORTDeposit_ZeroAmount();
    error FORTDeposit_MaxLeverageReached();
    error FORTDeposit_UserNotExist();
    error FORTDeposit_NotEnoughLPBacking();
    error FORTDeposit_TransferFailed();
    error FORTDeposit_AlreadyExist();
    error FORTDeposit_StalePriceFeed();

    // EVENTS //
    event PositionCreated(
        address indexed trader, uint256 indexed collateralAmount, uint256 indexed sizeAmount, bool isLong
    );
    event SizeIncreased(address indexed trader, uint256 indexed sizeAmount);
    event CollateralIncreased(address indexed trader, uint256 indexed collateralAmount);

    // STATE VARIABLES //
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant PRICE_FEED_ADJUSTMENT = 1e10;
    uint256 internal constant MAX_UTILIZATION_PERCENTAGE = 8e17; // 80% of deposited liquidity

    FORTVault internal fortVault; // instance of vault contract

    // STRUCT //
    FORTStructs.Protocol public protocol;

    // MAPPING //
    mapping(address trader => FORTStructs.Trader) public s_addressToPosition;

    // PRICE FEED //
    /**
     * @dev Hardcoding the address of BTC/USD on sepolia network
     */
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);

    /**
     * @notice Sets the addresss of collateral token ie USDC and max leverage of the protocol and deploys vault contract
     * @param _asset address of the collateral token
     * @param _maxLeverage max leverage allowed for trader
     */
    constructor(address _asset, uint256 _maxLeverage) {
        protocol.asset = _asset;
        protocol.MAX_LEVERAGE = _maxLeverage;

        fortVault = new FORTVault(IERC20(_asset), address(this));
    }

    /**
     * @dev This function allows traders to create position of given size for BTC by depositing collateral(USDC)
     * @param _collateralAmount amount of collateral trader want to deposit
     * @param _sizeAmount amount for which trader wants to open position for
     */

    //@audit-issue what if a user wanted to create long and short both then he will not because of mapping because double msg.sender ho hajaye and that will replace the previous mapping
    function createPosition(uint256 _collateralAmount, uint256 _sizeAmount, bool isLong) external {
        FORTStructs.Trader memory trader = s_addressToPosition[msg.sender];
        if (trader.collateral != 0) {
            revert FORTDeposit_AlreadyExist();
        }
        // Checking if params are correct or not
        if (_collateralAmount == 0 || _sizeAmount == 0) {
            revert FORTDeposit_ZeroAmount();
        }

        // (10,000 * 1e18) / 1000 = 10e18
        uint256 _leverage = (_sizeAmount * PRECISION) / _collateralAmount;
        // 10e18 < 15e18 ie Max leverage
        if (_leverage > protocol.MAX_LEVERAGE) {
            revert FORTDeposit_MaxLeverageReached();
        }

        // creating trader position
        uint256 _tokenAmount = _getTokenAmountFromSize(_sizeAmount);
        trader.user = msg.sender; // think of removing it
        trader.collateral = _collateralAmount;
        trader.size = _sizeAmount;
        trader.sizeInToken = _tokenAmount;

        if (isLong) {
            trader.strategy = FORTStructs.STRATEGY.LONG;
            protocol.openInterestLong += _sizeAmount;
            protocol.openInterestLongInToken += _tokenAmount;
            //@audit-issue try to configure them as above as possible
            if (_isEnoughLPBacking(_tokenAmount, 0, 0)) {
                revert FORTDeposit_NotEnoughLPBacking();
            }
        } else {
            trader.strategy = FORTStructs.STRATEGY.SHORT;
            protocol.openInterestShort += _sizeAmount;
            protocol.openInterestShortInToken += _tokenAmount;
            if (_isEnoughLPBacking(0, _sizeAmount, 0)) {
                revert FORTDeposit_NotEnoughLPBacking();
            }
        }
        s_addressToPosition[msg.sender] = trader;

        bool success = IERC20(protocol.asset).transferFrom(msg.sender, address(this), _collateralAmount);
        if (!success) {
            revert FORTDeposit_TransferFailed();
        }

        emit PositionCreated(msg.sender, _collateralAmount, _sizeAmount, isLong);
    }

    /**
     * @dev Increases the size of position
     * @param _sizeAmount amount by which trader wanted to increase size
     */
    function increaseSizeOfPosition(uint256 _sizeAmount) external {
        FORTStructs.Trader memory trader = s_addressToPosition[msg.sender];
        if (trader.collateral == 0) {
            revert FORTDeposit_UserNotExist();
        }

        if (_sizeAmount == 0) {
            revert FORTDeposit_ZeroAmount();
        }

        uint256 totalSizeOfTrader = trader.size + _sizeAmount;
        // (10,000 * 1e18) / 1000 = 10e18
        uint256 _leverage = (totalSizeOfTrader * PRECISION) / trader.collateral;
        // 10e18 < 15e18 ie Max leverage
        if (_leverage > protocol.MAX_LEVERAGE) {
            revert FORTDeposit_MaxLeverageReached();
        }

        // Updating trader data
        uint256 _tokenAmount = _getTokenAmountFromSize(_sizeAmount);
        trader.size += _sizeAmount;
        trader.sizeInToken += _tokenAmount;

        // updating the protocol data
        if (trader.strategy == FORTStructs.STRATEGY.LONG) {
            protocol.openInterestLong += _sizeAmount;
            protocol.openInterestLongInToken += _tokenAmount;
            if (_isEnoughLPBacking(_tokenAmount, 0, 0)) {
                revert FORTDeposit_NotEnoughLPBacking();
            }
        } else {
            protocol.openInterestShort += _sizeAmount;
            protocol.openInterestShortInToken += _tokenAmount;
            if (_isEnoughLPBacking(0, _sizeAmount, 0)) {
                revert FORTDeposit_NotEnoughLPBacking();
            }
        }

        emit SizeIncreased(msg.sender, _sizeAmount);
    }

    /**
     * @dev increases the collateral of position
     * @param _collateralAmount amount by which trader wanted to increase the collateral
     */
    function increaseCollateralOfPosition(uint256 _collateralAmount) external {
        FORTStructs.Trader memory trader = s_addressToPosition[msg.sender];
        if (trader.collateral == 0) {
            revert FORTDeposit_UserNotExist();
        }
        if (_collateralAmount == 0) {
            revert FORTDeposit_ZeroAmount();
        }

        //@audit-issue check if we realy need to check leverage here
        uint256 totalCollateralOfTrader = trader.collateral + _collateralAmount;
        uint256 _leverage = (trader.size * PRECISION) / totalCollateralOfTrader;
        if (_leverage > protocol.MAX_LEVERAGE) {
            revert FORTDeposit_MaxLeverageReached();
        }

        // Updating trader data
        trader.collateral += _collateralAmount;
        bool success = IERC20(protocol.asset).transferFrom(msg.sender, address(this), _collateralAmount);
        if (!success) {
            revert FORTDeposit_TransferFailed();
        }
        emit CollateralIncreased(msg.sender, _collateralAmount);
    }

    /**
     * @dev Setting the totalAsset which is totalDeposit by LP - totalPnL of protocol for correct minting of lpToken ie vUSDC
     */
    function setTotalAsset() external view returns (uint256 totalAsset) {
        address _asset = protocol.asset;
        address _vault = address(fortVault);
        uint256 _totalPnLofProtocol = _getTotalPnLofProtocol();
        // 10,000(liquidityDeposited) - 3000(totalPnLofProtocol) = 7,000(totalAsset)
        totalAsset = IERC20(_asset).balanceOf(_vault) - _totalPnLofProtocol;
    }

    /**
     * @dev Calculates how much BTC token in given sizeAmount
     * @param _sizeAmount amount for which we are calculating BTC
     * @return tokenAmount amount of BTC that we get in _sizeAmount
     */
    function _getTokenAmountFromSize(uint256 _sizeAmount) internal view returns (uint256 tokenAmount) {
        (, int256 price,, uint256 updatedAt,) = priceFeed.latestRoundData();
        // Checking for stale price
        if (block.timestamp > updatedAt + 1 hours) {
            revert FORTDeposit_StalePriceFeed();
        }
        // price of BTC is in 8 decimal,so multiplying it by 1e10 to make 1e18
        tokenAmount = (_sizeAmount * PRECISION) / ((uint256(price)) * PRICE_FEED_ADJUSTMENT);
    }

    /**
     * @dev Checks if there is enough deposit in the vault to back the traders position
     * @param _tokenInLong token amount that we get while opening long position
     * @param _sizeInShort amount of size trader wanted to open short position
     * @return bool, if enough liquidity reserve is there then true otherwise false
     */
    function _isEnoughLPBacking(uint256 _tokenInLong, uint256 _sizeInShort, uint256 _asset)
        public
        view
        returns (bool)
    {
        uint256 openInterestShort = protocol.openInterestShort + _sizeInShort;
        uint256 openInterestLongInToken = protocol.openInterestLongInToken + _tokenInLong;
        //@audit-issue change this depositedLiquidity and do we need actual deposited or PnL excluded
        uint256 depositedLiquidity = fortVault.totalAssets() - _asset;
        (, int256 price,, uint256 updatedAt,) = priceFeed.latestRoundData();
        // Checking for stale price
        if (block.timestamp > updatedAt + 1 hours) {
            revert FORTDeposit_StalePriceFeed();
        }

        // I've used below formula to calculate liquidity reserve for backing traders position
        //(shortOpenInterest) + (longOpenInterestInTokens * currentIndexTokenPrice) < (depositedLiquidity * maxUtilizationPercentage)

        return (openInterestShort + (openInterestLongInToken * uint256(price) * PRICE_FEED_ADJUSTMENT) / PRECISION)
            < ((depositedLiquidity * MAX_UTILIZATION_PERCENTAGE) / PRECISION);
    }

    /**
     * @dev Calculates the total PnL of the protocol by adding both long PnL and short PnL
     * @return totalPnLofProtocol
     */
    function _getTotalPnLofProtocol() internal view returns (uint256 totalPnLofProtocol) {
        uint256 openInterestLong = protocol.openInterestLong;
        uint256 openInterestLongInToken = protocol.openInterestLongInToken;

        uint256 openInterestShort = protocol.openInterestShort;
        uint256 openInterestShortInToken = protocol.openInterestShortInToken;

        //@audit-issue PnL can be negative therefore use int256
        (, int256 price,, uint256 updatedAt,) = priceFeed.latestRoundData();
        // Checking for stale price
        if (block.timestamp > updatedAt + 1 hours) {
            revert FORTDeposit_StalePriceFeed();
        }
        uint256 PnLofLong =
            ((openInterestLongInToken * uint256(price) * PRICE_FEED_ADJUSTMENT) / PRECISION - (openInterestLong));

        uint256 PnLofShort =
            ((openInterestShort) - (openInterestShortInToken * uint256(price) * PRICE_FEED_ADJUSTMENT) / PRECISION);

        totalPnLofProtocol = PnLofLong + PnLofShort;
    }
}
