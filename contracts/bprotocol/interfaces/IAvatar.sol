pragma solidity 0.5.16;

contract IERC20 {
    function transfer(address cToken, address dst, uint256 amount) external returns (bool);
    function transferFrom(address cToken, address src, address dst, uint256 amount) external returns (bool);
    function approve(address cToken, address spender, uint256 amount) public returns (bool);
}

contract IAvatar is IERC20 {

    function redeem(address cToken, uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(address cToken, uint256 redeemAmount) external returns (uint256);
    function borrow(address cToken, uint256 borrowAmount) external returns (uint256);
    function liquidateBorrow(address debtCToken, uint256 underlyingAmtToLiquidate, address collCToken) external payable;
}

// Workaround for issue https://github.com/ethereum/solidity/issues/526
// CEther
contract IAvatarCEther is IAvatar {
    function mint(address cEther) external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
}

// CErc20
contract IAvatarCErc20 is IAvatar {
    function mint(address cToken, uint256 mintAmount) external returns (uint256);
    function repayBorrow(address cToken, uint256 repayAmount) external returns (uint256);
    function repayBorrowBehalf(address cToken, address borrower, uint256 repayAmount) external returns (uint256);
}