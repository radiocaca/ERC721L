// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IPreimage {
    /**
     * @dev Returns if the `tokenId` token of preimage is locked. [MUST]
     */
    function isLocked(uint256 tokenId) external view returns (bool);

    /**
     * @dev Opensea-contract-level metadata. [OPTIONAL]
     * Details: https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() external view returns (string memory);
}

/**
 * @dev This implements an optional extension of {ERC721Lockable} defined in the EIP.
 * The bound token is exactly the same as the locked token metadata, the bound token can be transferred,
 * but it is guaranteed that only one bound token and the original token can be traded in the market at
 * the same time. When the original token lock expires, the bound token must be destroyed.
 */
contract ERC721Bound is ERC721Enumerable, IERC2981 {
    address public preimage;

    string private _contractURI;

    string public baseTokenURI;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        preimage = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the preimage.
     */
    modifier onlyPreimage() {
        require(preimage == msg.sender, "ERC721Bound: caller is not the preimage");
        _;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(baseTokenURI).length > 0) {
            return super.tokenURI(tokenId);
        }

        return IERC721Metadata(preimage).tokenURI(tokenId);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        return IERC2981(preimage).royaltyInfo(tokenId, salePrice);
    }

    /**
     * @dev See {IPreimage-contractURI}.
     */
    function contractURI() public view returns (string memory) {
        if (bytes(_contractURI).length > 0) {
            return _contractURI;
        }

        if (IERC165(preimage).supportsInterface(IPreimage.contractURI.selector)) {
            return IPreimage(preimage).contractURI();
        }

        return "";
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) external onlyPreimage {
        baseTokenURI = _baseTokenURI;
    }

    // @dev Sets the contract URI.
    function setContractURI(string memory uri) external onlyPreimage {
        _contractURI = uri;
    }

    /**
     * @dev Mints bound `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * caller must be preimage contract.
     *
     * Emits a {Transfer} event.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external onlyPreimage {
        _safeMint(to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * caller must be preimage contract.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) external onlyPreimage {
        _burn(tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to != address(0)) {
            require(IPreimage(preimage).isLocked(tokenId), "ERC721Bound: token transfer while preimage not locked");
        } else {
            require(!IPreimage(preimage).isLocked(tokenId), "ERC721Bound: token burn while preimage locked");
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == IPreimage.contractURI.selector ||
            super.supportsInterface(interfaceId);
    }
}
