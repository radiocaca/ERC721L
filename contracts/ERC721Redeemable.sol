// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721Redeemable is Ownable, ERC721 {
    using ERC721Redeemer for ERC721Redeemer.Claims;

    /**
    @dev This is specifically tracked because unclaimed tokens will be minted to
    the PROOF wallet, so the pool guarantees an upper bound.
     */
    uint256 public proofPoolRemaining;

    uint256 public redeemAllowance;

    IERC721 public immutable proof;

    ERC721Redeemer.Claims private redeemedPROOF;

    /**
    @notice Flag indicating whether holders of PROOF passes can mint.
     */
    bool public proofMintingOpen = false;

    /**
    @dev Used by both PROOF-holder and PROOF-admin minting from the pool.
     */
    modifier reducePROOFPool(uint256 n) {
        require(n <= proofPoolRemaining, "PROOF pool exhausted");
        proofPoolRemaining -= n;
        _;
    }

    constructor(
        IERC721 redeemProof,
        uint256 remaining,
        uint256 allowance
    ) {
        proof = redeemProof;
        proofPoolRemaining = remaining;
        redeemAllowance = allowance;
    }

    /**
    @notice Mint as a holder of a PROOF token.
    @dev Repeat a PROOF token ID twice to redeem both of its claims; recurring
    values SHOULD be adjacent for improved gas (eg [1,1,2,2] not [1,2,1,2]).
     */
    function mintPROOF(uint256[] calldata proofTokenIds) external reducePROOFPool(proofTokenIds.length) {
        require(proofMintingOpen, "PROOF minting closed");

        uint256 n = redeemedPROOF.redeem(redeemAllowance, msg.sender, proof, proofTokenIds);
        _safeMint(msg.sender, n);
    }

    /**
    @notice Returns how many additional tokens can be claimed with the PROOF token.
     */
    function proofClaimsRemaining(uint256 tokenId) external view returns (uint256) {
        require(tokenId < 1000, "Token doesn't exist");
        return redeemAllowance - redeemedPROOF.claimed(tokenId);
    }

    /**
    @notice Sets whether holders of PROOF passes can mint.
     */
    function setProofMintingOpen(bool open) external onlyOwner {
        proofMintingOpen = open;
    }
}
