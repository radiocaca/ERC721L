// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC721Lockable.sol";

/**
 * @dev Implementation ERC721 Lockable Token
 */
abstract contract ERC721Lockable is Context, ERC721, IERC721Lockable {
    // Default unlock time is 0, it means unlocked, set type(uint256).max to lock forever.
    // Mapping from token ID to unlock time
    mapping(uint256 => uint256) public lockedTokens;

    // Mapping from token ID to lock approved address
    mapping(uint256 => address) private _lockApprovals;

    // Mapping from owner to lock operator approvals
    mapping(address => mapping(address => bool)) private _lockOperatorApprovals;

    /**
     * @dev See {IERC721Lockable-lockApprove}.
     */
    function lockApprove(address to, uint256 tokenId) public virtual override {
        require(!isLocked(tokenId), "ERC721L: token is locked");
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721L: lock approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721L: lock approve caller is not owner nor approved for all"
        );

        _lockApprove(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721Lockable-getLockApproved}.
     */
    function getLockApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721L: lock approved query for nonexistent token");

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC721Lockable-lockerOf}.
     */
    function lockerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721L: locker query for nonexistent token");
        if (!isLocked(tokenId)) return address(0);

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC721Lockable-setLockApprovalForAll}.
     */
    function setLockApprovalForAll(address operator, bool approved) public virtual override {
        _setLockApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721Lockable-isLockApprovedForAll}.
     */
    function isLockApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _lockOperatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721Lockable-isLocked}.
     */
    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return lockedTokens[tokenId] > block.timestamp;
    }

    /**
     * @dev See {IERC721Lockable-lockFrom}.
     */
    function lockFrom(
        address from,
        uint256 tokenId,
        uint256 expired
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isLockApprovedOrOwner(_msgSender(), tokenId), "ERC721L: lock caller is not owner nor approved");
        require(expired > block.timestamp && expired > lockedTokens[tokenId], "ERC721L: invalid lock time");

        if (isLocked(tokenId)) {
            require(getLockApproved(tokenId) == _msgSender(), "ERC721L: lock caller is not occupied operator");
        }

        _lock(from, tokenId, expired);
    }

    /**
     * @dev See {IERC721Lockable-unlockFrom}.
     */
    function unlockFrom(
        address from,
        uint256 tokenId,
        uint256 expired
    ) public virtual override {
        require(
            isLocked(tokenId) && getLockApproved(tokenId) == _msgSender(),
            "ERC721L: unlock caller is not occupied operator"
        );
        require(expired < lockedTokens[tokenId], "ERC721L: invalid unlock time");

        _lock(from, tokenId, expired);
    }

    /**
     * @dev Locks `tokenId` from `from`  until `expired`.
     *
     * Requirements:
     *
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Locked} event.
     */
    function _lock(
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721L: lock from incorrect owner");

        if (_lockApprovals[tokenId] != _msgSender()) {
            _lockApprovals[tokenId] = _msgSender();
        }

        lockedTokens[tokenId] = expired;

        /*if (duration == 0) {
            lockedTokens[tokenId] = type(uint256).max;
        } else {
            unchecked {
                uint256 a = lockedTokens[tokenId];
                if (a == 0) {
                    uint256 b = duration + block.timestamp;
                    if (b < block.timestamp) revert("ERC721L: lock time overflow");

                    lockedTokens[tokenId] = b;
                } else {
                    uint256 c = a + duration;
                    if (c < a) revert("ERC721L: lock time overflow");

                    lockedTokens[tokenId] = c;
                }
            }
        }*/

        emit Locked(_msgSender(), from, tokenId, expired);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`, but the `tokenId` is locked and cannot be transferred.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     *
     * Emits {Locked} and {Transfer} event.
     */
    function _safeLockMint(
        address to,
        uint256 tokenId,
        uint256 expired,
        bytes memory _data
    ) internal virtual {
        require(expired > block.timestamp, "ERC721L: lock mint for invalid lock time");

        lockedTokens[tokenId] = expired;
        _lockApprovals[tokenId] = _msgSender();

        emit Locked(_msgSender(), to, tokenId, expired);

        _safeMint(to, tokenId, _data);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the lock approvals for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        // clear lock approvals
        delete lockedTokens[tokenId];
        delete _lockApprovals[tokenId];
    }

    /**
     * @dev Approve `to` to lock operate on `tokenId`
     *
     * Emits a {LockApproval} event.
     */
    function _lockApprove(
        address owner,
        address to,
        uint256 tokenId
    ) internal virtual {
        _lockApprovals[tokenId] = to;
        emit LockApproval(owner, to, tokenId);
    }

    /**
     * @dev Approve `operator` to lock operate on all of `owner` tokens
     *
     * Emits a {LockApprovalForAll} event.
     */
    function _setLockApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721L: lock approve to caller");
        _lockOperatorApprovals[owner][operator] = approved;
        emit LockApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `spender` is allowed to lock `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isLockApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721L: lock operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isLockApprovedForAll(owner, spender) || getLockApproved(tokenId) == spender);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the `tokenId` must not be locked.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!isLocked(tokenId), "ERC721L: token transfer while locked");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Lockable).interfaceId || super.supportsInterface(interfaceId);
    }
}
