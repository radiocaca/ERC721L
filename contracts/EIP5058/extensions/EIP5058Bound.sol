// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "../factory/IEIP5058Factory.sol";
import "../factory/IERC721Bound.sol";
import "../ERC721Lockable.sol";

abstract contract EIP5058Bound is ERC721Lockable {
    IEIP5058Factory public immutable factory;

    constructor(address _factory) {
        factory = IEIP5058Factory(_factory);
    }

    function _setBoundBaseTokenURI(string memory uri) internal {
        address bound = factory.boundOf(address(this));

        IERC721Bound(bound).setBaseTokenURI(uri);
    }

    function _setBoundContractURI(string memory uri) internal {
        address bound = factory.boundOf(address(this));

        IERC721Bound(bound).setContractURI(uri);
    }

    // NOTE:
    //
    // this will be called when `lockFrom` or `unlockFrom`
    function _afterTokenLock(
        address operator,
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual override {
        super._afterTokenLock(operator, from, tokenId, expired);

        if (expired != 0) {
            // lock mint
            if (operator != address(0)) {
                address bound = factory.boundOf(address(this));
                IERC721Bound(bound).safeMint(msg.sender, tokenId, "");
            }
        } else {
            // unlock
            address bound = factory.boundOf(address(this));
            if (IERC721Bound(bound).exists(tokenId)) {
                IERC721Bound(bound).burn(tokenId);
            }
        }
    }
}
