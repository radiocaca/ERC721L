// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IBoundERC721Receiver {
    function onBoundERC721Received(
        address operator,
        address to,
        uint256 boundTokenId,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC721Attachable is Ownable, ERC721 {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct BoundToken {
        address collection;
        uint256 tokenId;
    }

    // attached tokenId => host token
    mapping(uint256 => BoundToken) public attachedTokens;
    // host tokenId => attached token
    mapping(uint256 => BoundToken[]) private _hostTokens;
    // collection => tokenId => index
    mapping(address => mapping(uint256 => uint256)) private _attachedTokenIndex;

    EnumerableSet.AddressSet private _attachableCollections;

    EnumerableSet.AddressSet private _transferApprovals;

    event CollectionRemoved(address indexed collection);
    event CollectionAttached(address indexed collection);

    event TransferApprove(address indexed operator);
    event TransferDisapprove(address indexed operator);

    function allAttachedTokenLength(uint256 tokenId) public view returns (uint256) {
        return _hostTokens[tokenId].length;
    }

    function addCollection(address collection) external onlyOwner {
        require(!_attachableCollections.contains(collection), "ERC721Attachable: collection already attached");
        _attachableCollections.add(collection);

        emit CollectionAttached(collection);
    }

    function removeCollection(address collection) external onlyOwner {
        require(_attachableCollections.contains(collection), "ERC721Attachable: collection not attached");
        _attachableCollections.remove(collection);

        emit CollectionRemoved(collection);
    }

    function isAttachedCollection(address collection) public view returns (bool) {
        return _attachableCollections.contains(collection);
    }

    function addTransferApproval(address operator) external onlyOwner {
        require(!_transferApprovals.contains(operator), "ERC721Attachable: already approved");
        _transferApprovals.add(operator);

        emit TransferApprove(operator);
    }

    function removeTransferApproval(address operator) external onlyOwner {
        require(_transferApprovals.contains(operator), "ERC721Attachable: not approved");
        _transferApprovals.remove(operator);

        emit TransferDisapprove(operator);
    }

    function isTransferApproval(address operator) public view returns (bool) {
        return _transferApprovals.contains(operator);
    }

    function isAttachedToken(uint256 tokenId) public view returns (bool) {
        return attachedTokens[tokenId].collection != address(0);
    }

    function attachedTokenByIndex(uint256 tokenId, uint256 index) public view returns (uint256) {
        require(index < _hostTokens[tokenId].length, "ERC721Attachable: tokenId index out of bounds");
        return _hostTokens[tokenId][index];
    }

    function _attachedMint(
        address to,
        uint256 tokenId,
        address collection,
        uint256 hostTokenId
    ) internal virtual {
        BoundToken storage at = attachedTokens[tokenId];
        at.collection = collection;
        at.tokenId = hostTokenId;

        require(
            _checkOnBoundERC721Received(collection, to, tokenId, hostTokenId, ""),
            "ERC721Attachable: transfer to non BoundERC721Receiver implementer"
        );

        _mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        BoundToken storage at = attachedTokens[tokenId];
        if (at.collection != address(0)) {
            require(
                _checkOnBoundERC721Received(at.collection, address(0), tokenId, at.tokenId, ""),
                "ERC721Attachable: transfer to non BoundERC721Receiver implementer"
            );

            delete attachedTokens[tokenId];
        }
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
                require(isTransferApproval(msg.sender), "ERC721Attachable: attached token transfer not allowed");
                super.transferFrom(from, to, tokenId);
            }
        } else {
            super.transferFrom(from, to, tokenId);

            for (uint256 i = 0; i < _hostTokens[tokenId].length; i++) {
                IERC721(_hostTokens[tokenId][i].collection).transferFrom(from, to, _hostTokens[tokenId][i].tokenId);
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
                require(isTransferApproval(msg.sender), "ERC721Attachable: attached token transfer not allowed");
                super.safeTransferFrom(from, to, tokenId, data);
            }
        } else {
            super.safeTransferFrom(from, to, tokenId, data);

            for (uint256 i = 0; i < _hostTokens[tokenId].length; i++) {
                IERC721(_hostTokens[tokenId][i].collection).safeTransferFrom(
                    from,
                    to,
                    _hostTokens[tokenId][i].tokenId,
                    data
                );
            }
        }
    }

    function onBoundERC721Received(
        address, /*operator*/
        address to,
        uint256 boundTokenId,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external returns (bytes4) {
        require(isAttachedCollection(msg.sender), "ERC721Attachable: attached to non boundERC721 receiver");

        if (to != address(0)) {
            _attachedTokenIndex[msg.sender][boundTokenId] = _hostTokens[tokenId].length;

            _hostTokens[tokenId].push(BoundToken(msg.sender, boundTokenId));
        } else {
            _removeTokenFromHostTokens(tokenId, msg.sender, boundTokenId);
        }

        return this.onBoundERC721Received.selector;
    }

    function _checkOnBoundERC721Received(
        address from,
        address to,
        uint256 tokenId,
        uint256 hostTokenId,
        bytes memory _data
    ) private returns (bool) {
        try IBoundERC721Receiver(from).onBoundERC721Received(msg.sender, to, tokenId, hostTokenId, _data) returns (
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

    function _removeTokenFromHostTokens(
        uint256 tokenId,
        address collection,
        uint256 boundTokenId
    ) private {
        uint256 lastTokenIndex = _hostTokens[tokenId].length - 1;
        uint256 tokenIndex = _attachedTokenIndex[collection][boundTokenId];

        BoundToken storage bToken = _hostTokens[tokenId][lastTokenIndex];
        _hostTokens[tokenId][tokenIndex] = BoundToken(bToken.collection, bToken.tokenId);
        _attachedTokenIndex[bToken.collection][bToken.tokenId] = tokenIndex;

        delete _attachedTokenIndex[collection][boundTokenId];
        _hostTokens[tokenId].pop();
    }
}
