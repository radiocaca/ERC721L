// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "../factory/IEIP5058Factory.sol";
import "../factory/IERC721Bound.sol";
import "../ERC721Lockable.sol";

abstract contract EIP5058Bound is ERC721Lockable {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function _setBoundBaseTokenURI(string memory uri) internal {
        address bound = IEIP5058Factory(factory).boundOf(address(this));

        IERC721Bound(bound).setBaseTokenURI(uri);
    }

    function _setBoundContractURI(string memory uri) internal {
        address bound = IEIP5058Factory(factory).boundOf(address(this));

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
                address bound = IEIP5058Factory(factory).boundOf(address(this));
                IERC721Bound(bound).safeMint(msg.sender, tokenId, "");
            }
        } else {
            // unlock
            if (IEIP5058Factory(factory).existBound(address(this))) {
                address bound = IEIP5058Factory(factory).boundOf(address(this));
                IERC721Bound(bound).burn(tokenId);
            }
        }
    }
}
