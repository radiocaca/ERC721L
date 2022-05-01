// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Bound is IERC721Enumerable, IERC2981 {
    function preimage() external view returns (address);

    function contractURI() external view returns (string memory);

    function exists(uint256 tokenId) external view returns (bool);

    function setBaseTokenURI(string memory _baseTokenURI) external;

    function setContractURI(string memory uri) external;

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function burn(uint256 tokenId) external;
}
