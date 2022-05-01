// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "./ERC721Bound.sol";
import "../ERC721Lockable.sol";

abstract contract EIP5058Bound is ERC721Lockable {
    address public bound;

    event DeployedBound(address addr, bytes32 salt);

    function boundDeploy() public virtual {
        require(bound == address(0), "EIP5058Bound: bound nft is already deployed");

        bytes memory code = type(ERC721Bound).creationCode;
        bytes memory bytecode = abi.encodePacked(
            code,
            abi.encode(abi.encodePacked("Bound ", name()), abi.encodePacked("bound", symbol()))
        );

        _deploy(bytecode, keccak256(abi.encode(this)));
    }

    function _deploy(bytes memory bytecode, bytes32 salt) internal {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        bound = addr;
        emit DeployedBound(addr, salt);
    }

    function _setBoundBaseTokenURI(string memory uri) internal {
        require(bound != address(0), "EIP5058Bound: bound nft not deployed");

        ERC721Bound(bound).setBaseTokenURI(uri);
    }

    function _setBoundContractURI(string memory uri) internal {
        require(bound != address(0), "EIP5058Bound: bound nft not deployed");

        ERC721Bound(bound).setContractURI(uri);
    }

    function _beforeTokenLock(
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual override {
        super._beforeTokenLock(from, tokenId, expired);

        require(bound != address(0), "EIP5058Bound: bound nft not deployed");
        if (expired == 0) {
            ERC721Bound(bound).safeMint(msg.sender, tokenId, "");
        } else {
            ERC721Bound(bound).burn(tokenId);
        }
    }
}
