// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../EIP5058/extensions/EIP5058Bound.sol";

contract EIP5058BoundMock is ERC721Enumerable, EIP5058Bound {
    constructor(
        string memory name,
        string memory symbol,
        address mutantFactory
    ) ERC721(name, symbol) EIP5058Bound(mutantFactory) {}

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external {
        _safeMint(to, tokenId, data);
    }

    function lockMint(
        address to,
        uint256 tokenId,
        uint256 expired
    ) external {
        _safeLockMint(to, tokenId, expired, "");
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");

        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Lockable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Lockable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721Lockable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
