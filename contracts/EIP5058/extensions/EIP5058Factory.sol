// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./ERC721Bound.sol";

contract EIP5058Factory {
    mapping(address => address[]) public mutants;

    mapping(address => mapping(bytes32 => address)) public getMutant;

    event DeployedMutant(address indexed preimage, address mutant, bytes32 salt);

    function allMutantsLength(address preimage) public view returns (uint256) {
        return mutants[preimage].length;
    }

    function getBound(address preimage) public view returns (address) {
        return getMutant[preimage][keccak256(abi.encode(preimage))];
    }

    function boundDeploy(address preimage) external returns (address) {
        bytes32 salt = keccak256(abi.encode(preimage));
        require(getMutant[preimage][salt] == address(0), "EIP5058Bound: bound nft is already deployed");

        return _deploy(preimage, salt, "Bound");
    }

    function mutantDeploy(
        address preimage,
        bytes32 salt,
        bytes memory prefix
    ) external returns (address) {
        require(getMutant[preimage][salt] == address(0), "EIP5058Bound: mutant nft is already deployed");

        return _deploy(preimage, salt, prefix);
    }

    function _deploy(
        address preimage,
        bytes32 salt,
        bytes memory prefix
    ) internal returns (address) {
        IERC721Metadata collection = IERC721Metadata(preimage);
        bytes memory code = type(ERC721Bound).creationCode;
        bytes memory bytecode = abi.encodePacked(
            code,
            abi.encode(
                preimage,
                abi.encodePacked(prefix, " ", collection.name()),
                abi.encodePacked(prefix, collection.symbol())
            )
        );

        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        emit DeployedMutant(preimage, addr, salt);

        return addr;
    }
}
