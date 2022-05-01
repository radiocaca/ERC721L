// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

interface IEIP5058Factory {
    function allMutantsLength(address preimage) external view returns (uint256);

    function mutants(address preimage, uint256 index) external view returns (address);

    function getMutant(address preimage, bytes32 salt) external view returns (address);

    function getBound(address preimage) external view returns (address);

    function boundDeploy(address preimage) external returns (address);

    function mutantDeploy(
        address preimage,
        bytes32 salt,
        bytes memory prefix
    ) external returns (address);
}
