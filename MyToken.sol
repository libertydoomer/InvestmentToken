// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MyToken
/// @author libertydoomer
/// @notice The MyToken contract is an ERC-20 token with the `call Receive Commissions` function, 
/// which allows the contract owner to transfer the commission to the Treasury contract
contract MyToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice This function is used to transfer a commission from the TokenSale contract to the Treasury contract
    /// @dev A function that can only be called by the MyToken contract
    /// @param treasury Address of the Treasury contract 
    function callReceiveCommission(address treasury, uint256 amount) external onlyOwner {
        ITreasury(treasury).receiveCommission(amount);
    }
}

interface ITreasury {
    function receiveCommission(uint256 amount) external;
}