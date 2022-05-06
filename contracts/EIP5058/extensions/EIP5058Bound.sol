// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "./IEIP5058Factory.sol";
import "./IERC721Bound.sol";
import "../ERC721Lockable.sol";

abstract contract EIP5058Bound is ERC721Lockable {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function _setBoundBaseTokenURI(string memory uri) internal {
        address bound = IEIP5058Factory(factory).boundOf(address(this));
        require(bound != address(0), "EIP5058Bound: bound nft not deployed");

        IERC721Bound(bound).setBaseTokenURI(uri);
    }

    function _setBoundContractURI(string memory uri) internal {
        address bound = IEIP5058Factory(factory).boundOf(address(this));
        require(bound != address(0), "EIP5058Bound: bound nft not deployed");

        IERC721Bound(bound).setContractURI(uri);
    }

    function _beforeTokenLock(
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual override {
        super._beforeTokenLock(from, tokenId, expired);

        address bound = IEIP5058Factory(factory).boundOf(address(this));
        require(bound != address(0), "EIP5058Bound: bound nft not deployed");
        if (expired != 0) {
            IERC721Bound(bound).safeMint(msg.sender, tokenId, "");
        }
        // NOTE:
        //
        // why burn? burn in mint or in unlock?
        //
        // TODO:
        //
        // this doens't work for unlockFrom
        // else {
        //     IERC721Bound(bound).burn(tokenId);
        // }
    }
}
