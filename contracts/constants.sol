// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// LSP23 Deployer
address constant LSP23_ADDRESS =
    0x2300000A84D25dF63081feAa37ba6b62C4c89a30;
address constant POST_DEPLOYMENT_MODULE_ADDRESS =
    0x000000000066093407b6704B89793beFfD0D8F00;

// Base Contract addresses
address constant UP_INIT_ADDRESS =
    0x52c90985AF970D4E0DC26Cb5D052505278aF32A9;
address constant KM_INIT_ADDRESS =
    0xa75684d7D048704a2DB851D05Ba0c3cbe226264C;
address constant URD_UP_ADDRESS  =
    0xA5467dfe7019bF2C7C5F7A707711B9d4cAD118c8;

// Custom permissions
bytes constant URD_PERMISSIONS =
    hex"0000000000000000000000000000000000000000000000000000000000060080";

// keccak256("DeployedSaltedUniversalProfiles[]")
bytes32 constant DEPLOYED_SALTED_UP_ARRAY_KEY =
    0xe848445aa7ca9465c1c671cd8ee04ad9fd7163f3f0dbe68ed0b90fb27a62e20a;

// bytes10(keccak256("DeployedSaltedUniversalProfileMap"))
bytes10 constant DEPLOYED_SALTED_UP_ARRAY_MAP_PREFIX =
    0x557dbfb3a1fb723a48d7;
