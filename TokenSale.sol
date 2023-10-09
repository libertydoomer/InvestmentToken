// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Stock market
/// @author libertydoomer
/// @notice The contract allows you to sell myToken tokens for ether or other tokens, 
/// manage the price of the token, a white list of addresses and charge a commission when selling
/// @dev The contract needs to be finalized
contract TokenSale is Ownable {
    using SafeMath for uint256;
    
    IERC20 public myToken;
    address payable public treasuryAddress;
    uint256 public tokenPrice;
    mapping(address => bool) public whitelist;

    /// @notice it is created upon successful purchase of tokens and contains information about the buyer, 
    /// the amount of payment and the number of tokens purchased
    /// @param address buyer address
    /// @param amountPaid the amount of payment
    /// @param amountPurchased the number of tokens purchased
    event TokenPurchased(address indexed buyer, uint256 amountPaid, uint256 amountPurchased);

    constructor(
        address payable _treasuryAddress,
        address _myTokenAddress,
        uint256 _initialTokenPrice
    ) {
        treasuryAddress = _treasuryAddress;
        myToken = IERC20(_myTokenAddress);
        tokenPrice = _initialTokenPrice;
    }

    modifier onlyWhitelisted(address _tokenAddress) {
        require(whitelist[_tokenAddress], "Token is not whitelisted");
        _;
    }

    /// @notice Function for adding token addresses to the whitelist
    function addToWhitelist(address _tokenAddress) external onlyOwner {
        whitelist[_tokenAddress] = true;
    }

    /// @notice Function for removing token addresses from the whitelist
    function removeFromWhitelist(address _tokenAddress) external onlyOwner {
        whitelist[_tokenAddress] = false;
    }

    /// @notice Function for setting the token price
    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    /// @notice Function for buying MyToken for a certain token with sending a commission to Treasury
    /// @param _tokenAmount the amount of the token to be purchased
    /// @param _tokenAddress the address of the token for which we buy MyToken
    function buyMyToken(uint256 _tokenAmount, address _tokenAddress) external onlyWhitelisted(_tokenAddress) {
        uint256 totalCost = _tokenAmount.mul(tokenPrice);
        require(myToken.balanceOf(msg.sender) >= totalCost, "Insufficient balance");

        /// @dev We expect 10% commission
        uint256 fee = totalCost.div(10);
        uint256 purchaseAmount = totalCost.sub(fee);

        /// @dev We transfer 10% of the amount to the Treasury contract
        require(IERC20(_tokenAddress).transferFrom(msg.sender, treasuryAddress, fee), "Token transfer to Treasury failed");

        /// @dev We issue MyToken to the buyer's balance
        require(myToken.transfer(msg.sender, purchaseAmount), "myToken transfer to buyer failed");

        emit TokenPurchased(msg.sender, totalCost, purchaseAmount);
    }

    /// @notice Function for getting the MyToken balance on the contract
    function getMyTokenBalance() external view returns (uint256) {
        return myToken.balanceOf(address(this));
    }

    /// @notice MyToken purchase function for Ether
    /// @dev needs to be finalized
    function buyMyTokenWithEther() external payable {
        uint256 totalCost = msg.value.mul(tokenPrice);
        require(myToken.balanceOf(address(this)) >= totalCost, "Insufficient myToken balance");

        /// @dev We expect 10% commission
        uint256 fee = totalCost.div(10);
        uint256 purchaseAmount = totalCost.sub(fee);

        /// @dev We transfer 10% of the amount to the Treasury contract
        treasuryAddress.transfer(fee);

        /// @dev We issue MyToken to the buyer's balance
        myToken.transfer(msg.sender, purchaseAmount);

        emit TokenPurchased(msg.sender, totalCost, purchaseAmount);
    }

}