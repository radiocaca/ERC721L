// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IBoundERC721Receiver {
    function onBoundERC721Received(
        address operator,
        address to,
        uint256 boundTokenId,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC721Attachable is ERC721 {
    struct BoundToken {
        address collection;
        uint256 tokenId;
    }

    // attached tokenId => host token
    mapping(uint256 => BoundToken) public attachedTokens;
    // host tokenId => attached token
    mapping(uint256 => BoundToken[]) public hostTokens;

    mapping(address => bool) public attachableCollections;

    mapping(address => bool) public allowTransferIn;

    function _setAttachableCollection(address collection, bool isAttach) internal virtual {
        attachableCollections[collection] = isAttach;
    }

    function _setAllowTransferIn(address white, bool isAllow) internal virtual {
        allowTransferIn[white] = isAllow;
    }

    function _attachedMint(
        address to,
        uint256 tokenId,
        address collection,
        uint256 hostTokenId
    ) internal virtual {
        BoundToken storage bt = attachedTokens[tokenId];
        bt.collection = collection;
        bt.tokenId = hostTokenId;

        require(
            _checkOnBoundERC721Received(collection, to, tokenId, hostTokenId, ""),
            "ERC721Attachable: transfer to non BoundERC721Receiver implementer"
        );

        _mint(to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (attachedTokens[tokenId].collection != address(0)) {
            if (msg.sender == attachedTokens[tokenId].collection) {
                _transfer(from, to, tokenId);
            } else {
                require(allowTransferIn[msg.sender], "ERC721Attachable: attached token transfer not allowed");
                super.transferFrom(from, to, tokenId);
            }
        } else {
            super.transferFrom(from, to, tokenId);

            for (uint256 i = 0; i < hostTokens[tokenId].length; i++) {
                IERC721(hostTokens[tokenId][i].collection).transferFrom(from, to, hostTokens[tokenId][i].tokenId);
            }
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (attachedTokens[tokenId].collection != address(0)) {
            if (msg.sender == attachedTokens[tokenId].collection) {
                _safeTransfer(from, to, tokenId, data);
            } else {
                require(allowTransferIn[msg.sender], "ERC721Attachable: attached token transfer not allowed");
                super.safeTransferFrom(from, to, tokenId, data);
            }
        } else {
            super.safeTransferFrom(from, to, tokenId, data);

            for (uint256 i = 0; i < hostTokens[tokenId].length; i++) {
                IERC721(hostTokens[tokenId][i].collection).safeTransferFrom(
                    from,
                    to,
                    hostTokens[tokenId][i].tokenId,
                    data
                );
            }
        }
    }

    function onBoundERC721Received(
        address, /*operator*/
        address, /*to*/
        uint256 boundTokenId,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external returns (bytes4) {
        require(attachableCollections[_msgSender()], "ERC721Attachable: attached to non boundERC721 receiver");

        hostTokens[tokenId].push(BoundToken(_msgSender(), boundTokenId));

        return this.onBoundERC721Received.selector;
    }

    function _checkOnBoundERC721Received(
        address from,
        address to,
        uint256 tokenId,
        uint256 hostTokenId,
        bytes memory _data
    ) private returns (bool) {
        try IBoundERC721Receiver(from).onBoundERC721Received(_msgSender(), to, tokenId, hostTokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == IBoundERC721Receiver.onBoundERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721Attachable: transfer to non BoundERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}
