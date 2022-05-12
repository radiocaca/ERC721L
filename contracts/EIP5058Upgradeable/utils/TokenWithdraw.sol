// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

abstract contract TokenWithdraw is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function withdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        AddressUpgradeable.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner nonReentrant {
        IERC721Upgradeable(token).safeTransferFrom(address(this), to, tokenId);
    }
}
