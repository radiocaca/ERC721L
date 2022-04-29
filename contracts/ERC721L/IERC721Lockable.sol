// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev ERC-721 Non-Fungible Token Standard, optional lockable extension
 * ERC721 Token that can be locked for a certain period and cannot be transferred.
 * This is designed for a non-escrow staking contract that comes later to lock a user's NFT
 * while still letting them keep it in their wallet.
 * This extension can ensure the security of user tokens during the staking period.
 * If the nft lending protocol is compatible with this extension, the trouble caused by the NFT
 * airdrop can be avoided, because the airdrop is still in the user's wallet
 */
interface IERC721Lockable is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is locked from `from`.
     */
    event Locked(address indexed operator, address indexed from, uint256 indexed tokenId, uint256 expired);

    /**
     * @dev Emitted when `owner` enables `approved` to lock the `tokenId` token.
     */
    event LockApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to lock all of its tokens.
     */
    event LockApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the current locker of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function lockerOf(uint256 tokenId) external view returns (address locker);

    /**
     * @dev Lock `tokenId` token until `expired` from `from`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - `expired` must be greater than block.timestamp
     * - If the caller is not `from`, it must be approved to lock this token
     * by either {lockApprove} or {setLockApprovalForAll}.
     *
     * Emits a {Locked} event.
     */
    function lockFrom(
        address from,
        uint256 tokenId,
        uint256 expired
    ) external;

    /**
     * @dev Unlock `tokenId` token until `expired` from `from`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - `expired` must be less than the current expiration time.
     * - the caller must be the operator who locks the token by {lockFrom}
     *
     * Emits a {Locked} event.
     */
    function unlockFrom(
        address from,
        uint256 tokenId,
        uint256 expired
    ) external;

    /**
     * @dev Gives permission to `to` to lock `tokenId` token.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved lock operator.
     * - `tokenId` must exist.
     *
     * Emits an {LockApproval} event.
     */
    function lockApprove(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an lock operator for the caller.
     * Operators can call {lockFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {LockApprovalForAll} event.
     */
    function setLockApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account lock approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getLockApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to lock all of the assets of `owner`.
     *
     * See {setLockApprovalForAll}
     */
    function isLockApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Returns if the `tokenId` token is locked.
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isLocked(uint256 tokenId) external view returns (bool);
}
