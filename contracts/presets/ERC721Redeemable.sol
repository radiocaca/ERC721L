// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721Redeemable is Ownable {
    using ERC721Redeemer for ERC721Redeemer.Claims;

    /**
    @dev This is specifically tracked because unclaimed tokens will be minted to
    the PROOF wallet, so the pool guarantees an upper bound.
     */
    uint256 public proofPoolRemaining;

    uint256 public proofPoolBeginTokenId;

    uint256 public redeemAllowance;

    uint256 public lockDuration;

    IERC721 public redeemProof;

    ERC721Redeemer.Claims private redeemedProof;

    /**
    @notice Flag indicating whether holders of PROOF passes can mint.
     */
    bool public proofMintOpen = false;

    /**
    @dev Used by both PROOF-holder and PROOF-admin minting from the pool.
     */
    modifier reducePROOFPool(uint256 n) {
        require(n <= proofPoolRemaining, "PROOF pool exhausted");
        proofPoolRemaining -= n;
        _;
    }

    /**
    @notice Mint as a holder of a PROOF token.
    @dev Repeat a PROOF token ID twice to redeem both of its claims; recurring
    values SHOULD be adjacent for improved gas (eg [1,1,2,2] not [1,2,1,2]).
     */
    function _proofMint(uint256[] calldata proofTokenIds)
        internal
        reducePROOFPool(proofTokenIds.length)
        returns (uint256)
    {
        require(proofMintOpen, "proof mint closed");

        return redeemedProof.redeem(redeemAllowance, msg.sender, redeemProof, proofTokenIds);
    }

    /**
    @notice Returns how many additional tokens can be claimed with the PROOF token.
     */
    function proofClaimsRemaining(uint256 tokenId) external view returns (uint256) {
        return redeemAllowance - redeemedProof.claimed(tokenId);
    }

    /**
    @notice Sets whether holders of PROOF passes can mint.
     */
    function setProofMintOpen(bool open) external onlyOwner {
        proofMintOpen = open;
    }

    function setProofInfo(
        address _redeemProof,
        uint256 _remaining,
        uint256 _allowance,
        uint256 _lockDuration
    ) external onlyOwner {
        redeemProof = IERC721(_redeemProof);
        proofPoolRemaining = _remaining;
        redeemAllowance = _allowance;
        lockDuration = _lockDuration;
    }
}
