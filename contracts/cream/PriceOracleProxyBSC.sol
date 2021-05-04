pragma solidity ^0.5.16;

import "./libs/CErc20.sol";
import "./libs/CToken.sol";
import "./libs/PriceOracle.sol";
import "./libs/Exponential.sol";
import "./libs/EIP20Interface.sol";

interface V1PriceOracleInterface {
    function assetPrices(address asset) external view returns (uint);
}

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

contract PriceOracleProxy is PriceOracle, Exponential {
    address public admin;

    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /// @notice The v1 price oracle, which will continue to serve prices for v1 assets
    V1PriceOracleInterface public v1PriceOracle;

    /// @notice Chainlink Aggregators
    mapping(address => AggregatorInterface) public aggregators;

    address public cEthAddress;

    /**
     * @param admin_ The address of admin to set aggregators
     * @param v1PriceOracle_ The address of the v1 price oracle, which will continue to operate and hold prices for collateral assets
     * @param cEthAddress_ The address of cETH, which will return a constant 1e18, since all prices relative to ether
     */
    constructor(address admin_,
                address v1PriceOracle_,
                address cEthAddress_) public {
        admin = admin_;
        v1PriceOracle = V1PriceOracleInterface(v1PriceOracle_);
        cEthAddress = cEthAddress_;
    }

    /**
     * @notice Get the underlying price of a listed cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function getUnderlyingPrice(CToken cToken) public view returns (uint) {
        address cTokenAddress = address(cToken);

        if (cTokenAddress == cEthAddress) {
            // ether always worth 1
            return 1e18;
        }

        AggregatorInterface aggregator = aggregators[cTokenAddress];
        if (address(aggregator) != address(0)) {
            MathError mathErr;
            Exp memory price;
            (mathErr, price) = getPriceFromChainlink(aggregator);
            if (mathErr != MathError.NO_ERROR) {
                // Fallback to v1 PriceOracle
                return getPriceFromV1(cTokenAddress);
            }

            if (price.mantissa == 0) {
                return getPriceFromV1(cTokenAddress);
            }

            uint underlyingDecimals;
            underlyingDecimals = EIP20Interface(CErc20(cTokenAddress).underlying()).decimals();
            (mathErr, price) = mulScalar(price, 10**(18 - underlyingDecimals));
            if (mathErr != MathError.NO_ERROR ) {
                // Fallback to v1 PriceOracle
                return getPriceFromV1(cTokenAddress);
            }

            return price.mantissa;
        }

        return getPriceFromV1(cTokenAddress);
    }

    function getPriceFromChainlink(AggregatorInterface aggregator) internal view returns (MathError, Exp memory) {
        int256 chainLinkPrice = aggregator.latestAnswer();
        if (chainLinkPrice <= 0) {
            return (MathError.INTEGER_OVERFLOW, Exp({mantissa: 0}));
        }
        return (MathError.NO_ERROR, Exp({mantissa: uint(chainLinkPrice)}));
    }

    function getPriceFromV1(address cTokenAddress) internal view returns (uint) {
        address underlying = CErc20(cTokenAddress).underlying();
        return v1PriceOracle.assetPrices(underlying);
    }

    event AggregatorUpdated(address cTokenAddress, address source);

    function _setAggregators(address[] calldata cTokenAddresses, address[] calldata sources) external {
        require(msg.sender == admin, "only the admin may set the aggregators");
        for (uint i = 0; i < cTokenAddresses.length; i++) {
            aggregators[cTokenAddresses[i]] = AggregatorInterface(sources[i]);
            emit AggregatorUpdated(cTokenAddresses[i], sources[i]);
        }
    }
}
