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

    function DeployBound() public {
        factory.boundDeploy(address(this));
    }

    function _setBoundBaseTokenURI(string memory uri) internal {
        IERC721Bound bound = IERC721Bound(factory.boundOf(address(this)));
        bound.setBaseTokenURI(uri);
    }

    function _setBoundContractURI(string memory uri) internal {
        IERC721Bound bound = IERC721Bound(factory.boundOf(address(this)));
        bound.setContractURI(uri);
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

        IERC721Bound bound = IERC721Bound(factory.boundOf(address(this)));
        if (expired != 0) {
            // lock mint
            if (operator != address(0)) {
                bound.safeMint(msg.sender, tokenId, "");
            }
        } else {
            // unlock
            if (bound.exists(tokenId)) {
                bound.burn(tokenId);
            }
        }
    }
}
