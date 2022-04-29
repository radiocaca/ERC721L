// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenWithdraw is Ownable {
    using SafeERC20 for IERC20;

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }
}
