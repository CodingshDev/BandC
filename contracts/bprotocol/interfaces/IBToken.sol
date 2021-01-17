pragma solidity 0.5.16;

interface IBToken {
    function cToken() external view returns (address);
    function borrowBalanceCurrent(address account) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external payable returns (uint);
}