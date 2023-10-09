// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    // Функция, которая может быть вызвана только контрактом MyToken
    function callReceiveCommission(address treasury, uint256 amount) external onlyOwner {
        ITreasury(treasury).receiveCommission(amount);
    }
}

interface ITreasury {
    function receiveCommission(uint256 amount) external;
}