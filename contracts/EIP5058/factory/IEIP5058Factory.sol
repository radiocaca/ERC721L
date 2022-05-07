// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

interface IEIP5058Factory {
    event DeployedMutant(address indexed preimage, address mutant, bytes32 salt);

    function allMutantsLength(address preimage) external view returns (uint256);

    function mutantByIndex(address preimage, uint256 index) external view returns (address);

    function mutantOf(address preimage, bytes32 salt) external view returns (address);

    function existBound(address preimage) external view returns (bool);

    function boundOf(address preimage) external view returns (address);

    function boundDeploy(address preimage) external returns (address);

    function mutantDeploy(
        address preimage,
        bytes32 salt,
        bytes memory prefix
    ) external returns (address);
}
