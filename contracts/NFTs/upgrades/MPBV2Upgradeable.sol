// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "../../EIP5058Upgradeable/extensions/EIP5058Bound.sol";
import "../../EIP5058Upgradeable/utils/ERC721Attachable.sol";
import "../../EIP5058Upgradeable/utils/TokenWithdraw.sol";

contract MPBV2Upgradeable is
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable,
    EIP5058Bound,
    ERC721Attachable,
    ERC721RoyaltyUpgradeable,
    AccessControlEnumerableUpgradeable,
    TokenWithdraw
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    function initialize() external initializer {
        __ERC721_init("Matrix Plus Box", "MPB");

        baseTokenURI = "https://api.bakeryswap.org/nft/matrix-plus-box/";

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId, data);
    }

    function lockMint(
        address to,
        uint256 tokenId,
        uint256 expired
    ) external onlyRole(MINTER_ROLE) {
        _safeLockMint(to, tokenId, expired, "");
    }

    function mint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    function mintBatch(address to, uint256[] calldata tokenIds) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
        }
    }

    function mintRange(
        address to,
        uint256 fromId,
        uint256 toId
    ) external onlyRole(MINTER_ROLE) {
        for (; fromId <= toId; fromId++) {
            _mint(to, fromId);
        }
    }

    function burn(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) ||
                hasRole(BURNER_ROLE, _msgSender()) ||
                masterOf(tokenId) == msg.sender,
            "ERC721: caller is not owner nor approved"
        );

        _burn(tokenId);
    }

    function slaveMint(
        address to,
        uint256 tokenId,
        address collection,
        uint256 hostTokenId
    ) external onlyRole(MINTER_ROLE) {
        _slaveMint(to, tokenId, collection, hostTokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable, ERC721Attachable) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721Upgradeable, ERC721Attachable) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setRoleAdmin(bytes32 roleId, bytes32 adminRoleId) external onlyOwner {
        _setRoleAdmin(roleId, adminRoleId);
    }

    function setFactory(address factory) external onlyOwner {
        _setFactory(factory);
    }

    function setDefaultRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint96 fraction
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable, ERC721Lockable, ERC721Attachable)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable, ERC721Lockable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721Lockable,
            ERC721RoyaltyUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
