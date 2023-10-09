// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenSale is Ownable {
    using SafeMath for uint256;
    
    IERC20 public myToken;
    address payable public treasuryAddress;
    uint256 public tokenPrice;
    mapping(address => bool) public whitelist;

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

    // Функция для добавления адресов токенов в белый список
    function addToWhitelist(address _tokenAddress) external onlyOwner {
        whitelist[_tokenAddress] = true;
    }

    // Функция для удаления адресов токенов из белого списка
    function removeFromWhitelist(address _tokenAddress) external onlyOwner {
        whitelist[_tokenAddress] = false;
    }

    // Функция для установки цены токена
    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    // Функция для покупки myToken за определенный токен c отправкой комиссии в Treasury
    function buyMyToken(uint256 _tokenAmount, address _tokenAddress) external onlyWhitelisted(_tokenAddress) {
        uint256 totalCost = _tokenAmount.mul(tokenPrice);
        require(myToken.balanceOf(msg.sender) >= totalCost, "Insufficient balance");

        // Рассчитываем 10% комиссии
        uint256 fee = totalCost.div(10);
        uint256 purchaseAmount = totalCost.sub(fee);

        // Переводим 10% от суммы в контракт Treasury
        require(IERC20(_tokenAddress).transferFrom(msg.sender, treasuryAddress, fee), "Token transfer to Treasury failed");

        // Выпускаем myToken на баланс покупателя
        require(myToken.transfer(msg.sender, purchaseAmount), "myToken transfer to buyer failed");

        emit TokenPurchased(msg.sender, totalCost, purchaseAmount);
    }

    // Функция для получения остатка myToken на контракте
    function getMyTokenBalance() external view returns (uint256) {
        return myToken.balanceOf(address(this));
    }

    function buyMyTokenWithEther() external payable {
        uint256 totalCost = msg.value.mul(tokenPrice);
        require(myToken.balanceOf(address(this)) >= totalCost, "Insufficient myToken balance");

        // Рассчитываем 10% комиссии
        uint256 fee = totalCost.div(10);
        uint256 purchaseAmount = totalCost.sub(fee);

        // Переводим 10% от суммы в контракт Treasury
        treasuryAddress.transfer(fee);

        // Выпускаем myToken на баланс покупателя
        myToken.transfer(msg.sender, purchaseAmount);

        emit TokenPurchased(msg.sender, totalCost, purchaseAmount);
    }

}