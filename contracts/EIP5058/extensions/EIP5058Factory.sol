// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./ERC721Bound.sol";
import "./IEIP5058Factory.sol";

contract EIP5058Factory is IEIP5058Factory {
    // Mapping from preimage to list of mutants
    mapping(address => address[]) private _mutants;

    // preimage => salt => mutant
    mapping(address => mapping(bytes32 => address)) private _allMutants;

    function allMutantsLength(address preimage) public view virtual override returns (uint256) {
        return _mutants[preimage].length;
    }

    /**
     * @dev See {IEIP5058Factory-mutantByIndex}.
     */
    function mutantByIndex(address preimage, uint256 index) public view virtual override returns (address) {
        require(index < allMutantsLength(preimage), "EIP5058Factory: index out of bounds");

        return _mutants[preimage][index];
    }

    function boundOf(address preimage) public view virtual override returns (address) {
        address bound = mutantOf(preimage, keccak256(abi.encode(preimage)));
        require(bound != address(0), "EIP5058Factory: query for nonexistent bound");
        return bound;
    }

    function mutantOf(address preimage, bytes32 salt) public view virtual override returns (address) {
        address mutant = _allMutants[preimage][salt];
        require(mutant != address(0), "EIP5058Factory: query for nonexistent mutant");
        return mutant;
    }

    function boundDeploy(address preimage) public virtual override returns (address) {
        bytes32 salt = keccak256(abi.encode(preimage));
        require(_allMutants[preimage][salt] == address(0), "EIP5058Factory: bound nft is already deployed");

        return _deploy(preimage, salt, "Bound");
    }

    function mutantDeploy(
        address preimage,
        bytes32 salt,
        bytes memory prefix
    ) public virtual override returns (address) {
        require(_allMutants[preimage][salt] == address(0), "EIP5058Factory: mutant nft is already deployed");

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

        _mutants[preimage].push(addr);
        _allMutants[preimage][salt] = addr;
        return addr;
    }
}
