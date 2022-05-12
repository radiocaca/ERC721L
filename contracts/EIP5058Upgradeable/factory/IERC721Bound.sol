// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721Bound is IERC721Upgradeable {
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
