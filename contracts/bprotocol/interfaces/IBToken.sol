pragma solidity 0.5.16;

interface IBToken {
    function cToken() external view returns (address);
}