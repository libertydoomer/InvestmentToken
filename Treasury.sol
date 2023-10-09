// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Treasury is Ownable, ERC721 {
    using SafeMath for uint256;

    IERC20 public myToken;
    uint256 public totalCommission;
    uint256 public depositNftId = 1;
    
    struct Deposit {
        address user;
        uint256 tokenAmount;
        uint256 timestamp;
    }

    mapping(uint256 => Deposit) public deposits;

    event CommissionReceived(address indexed sender, uint256 amount);
    event NftIssued(address indexed user, uint256 tokenId, uint256 depositAmount, uint256 timestamp);
    event NftRedeemed(address indexed user, uint256 tokenId, uint256 depositAmount, uint256 rewardAmount, uint256 timestamp);

    constructor(address _myTokenAddress) ERC721("DepositNFT", "DEP") {
        myToken = IERC20(_myTokenAddress);
    }

    // Функция для получения остатка комиссии на контракте Treasury
    function getCommissionBalance() external view returns (uint256) {
        return myToken.balanceOf(address(this));
    }

    // Функция для снятия комиссии владельцем контракта Treasury
    function withdrawCommission() external onlyOwner {
        uint256 commissionBalance = myToken.balanceOf(address(this));
        require(commissionBalance > 0, "No commission to withdraw");

        // Переводим комиссию владельцу
        require(myToken.transfer(owner(), commissionBalance), "Commission transfer to owner failed");

        // Обновляем общую сумму комиссии
        totalCommission = totalCommission.add(commissionBalance);
    }

    function receiveCommission() external payable {
        require(msg.value > 0, "Commission amount must be greater than zero");

        // Увеличиваем общую сумму комиссии
        totalCommission = totalCommission.add(msg.value);

        emit CommissionReceived(msg.sender, msg.value);
    }

    // Функция для вложения токенов и выпуска NFT
    function depositAndIssueNft(uint256 _tokenAmount) external {
        require(_tokenAmount > 0, "Deposit amount must be greater than zero");
        require(myToken.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer to Treasury failed");

        deposits[depositNftId] = Deposit({
            user: msg.sender,
            tokenAmount: _tokenAmount,
            timestamp: block.timestamp
        });

        _mint(msg.sender, depositNftId);
        emit NftIssued(msg.sender, depositNftId, _tokenAmount, block.timestamp);

        depositNftId++;
    }

    // Функция для погашения NFT и получения депозита и вознаграждения
    function redeemNft(uint256 _tokenId) external {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");

        Deposit storage deposit = deposits[_tokenId];
        require(deposit.tokenAmount > 0, "No deposit available for this NFT");
        
        uint256 rewardAmount = deposit.tokenAmount.mul(2).div(100); // 2% reward
        
        require(myToken.transfer(msg.sender, deposit.tokenAmount.add(rewardAmount)), "Token transfer to user failed");

        delete deposits[_tokenId];
        _burn(_tokenId);
        
        emit NftRedeemed(msg.sender, _tokenId, deposit.tokenAmount, rewardAmount, block.timestamp);
    }

}