// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// utils
import {LSP2Utils} from "@lukso/lsp-smart-contracts/contracts/LSP2ERC725YJSONSchema/LSP2Utils.sol";

// constants
import  {
    _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY
} from "@lukso/lsp-smart-contracts/contracts/LSP1UniversalReceiver/LSP1Constants.sol";
import {
    _LSP3_SUPPORTED_STANDARDS_KEY,
    _LSP3_SUPPORTED_STANDARDS_VALUE,
    _LSP3_PROFILE_KEY
} from "@lukso/lsp-smart-contracts/contracts/LSP3ProfileMetadata/LSP3Constants.sol";
import {
    _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
    _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
    _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
    ALL_REGULAR_PERMISSIONS
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

// modules
import {ILSP23LinkedContractsFactory} from "@lukso/lsp-smart-contracts/contracts/LSP23LinkedContractsFactory/ILSP23LinkedContractsFactory.sol";
import {LSP23LinkedContractsFactory} from "@lukso/lsp-smart-contracts/contracts/LSP23LinkedContractsFactory/LSP23LinkedContractsFactory.sol";
import {UniversalProfileInit} from "@lukso/lsp-smart-contracts/contracts/UniversalProfileInit.sol";
import {UniversalProfile} from "@lukso/lsp-smart-contracts/contracts/UniversalProfile.sol";
import {LSP6KeyManagerInit} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManagerInit.sol";

// errors
error CallerNotUniversalProfileOwner(address caller, address universalProfile);

// events
event SaltedUniversalProfileDeployed(
	address indexed deployer,
	address indexed universalProfileAddress
);
event SaltedUniversalProfileExported(
	address indexed deployer,
	address indexed universalProfileAddress
);

contract SaltedUniversalProfileFactory {
	/// ------ Constants - DO NOT CHANGE ------
    address constant LSP23_ADDRESS = 0x2300000A84D25dF63081feAa37ba6b62C4c89a30;
    address constant POST_DEPLOYMENT_MODULE_ADDRESS = 0x000000000066093407b6704B89793beFfD0D8F00;
    address constant UP_INIT_ADDRESS = 0x52c90985AF970D4E0DC26Cb5D052505278aF32A9;
    address constant KM_INIT_ADDRESS = 0xa75684d7D048704a2DB851D05Ba0c3cbe226264C;
    address constant URD_UP_ADDRESS  = 0xA5467dfe7019bF2C7C5F7A707711B9d4cAD118c8;
    bytes constant URD_PERMISSIONS = hex"0000000000000000000000000000000000000000000000000000000000060080"; 
	/// ---------------------------------------

	/**
	 * @dev Used to store the owner of each deployed up.
	 */
    mapping (address => address) private universalProfilesOwners;
	mapping (address => address[]) private deployedUniversalProfiles;
	mapping (address => address[]) private exportedUniversalProfiles;

	/**
	 * @dev Gatekeeper, doen't allow modifying the Universal Profile unless the caller is the one that deployed it. 
	 */
	modifier OnlyUniversalProfileOwner(address universalProfileAddress) {
		if (msg.sender != universalProfilesOwners[universalProfileAddress]) {
			revert CallerNotUniversalProfileOwner(msg.sender, universalProfileAddress);
		}
		_;
	}

	/**
	 * @notice Deployed a 🧂 (salted) Universal Profile.
	 * 
	 * @dev Deploy a Universal Profile owned by a Key Manager and make this contract the main controller.
	 * 
	 * @custom:info
	 * - The deployed Universal Profile will also have a default URD set with some permissions.
	 * - The deployed Unviersal Profile also supports LSP3 Profile Metadata, but does not have the metadata set at this point.
	 * 
	 * @param salt A 32 bytes value used to deploy the Universal Profile at a pre-deterministic address.
	 * 
	 * @return universalProfileAddress The address of the 🧂 (salted) Universal Profile.
	 */
    function deploy(bytes32 salt) public payable returns(address universalProfileAddress) {
		address caller = msg.sender;

		/// ------ Data for Universal Profile deployment ------
		ILSP23LinkedContractsFactory.PrimaryContractDeploymentInit memory primaryContractDeploymentInit = ILSP23LinkedContractsFactory.PrimaryContractDeploymentInit({
			salt: salt,
			fundingAmount: 0,
			implementationContract: UP_INIT_ADDRESS,
			initializationCalldata: abi.encodeCall(UniversalProfileInit.initialize, POST_DEPLOYMENT_MODULE_ADDRESS)
		});
		/// ---------------------------------------------------

		/// ------ Data for Key Manager deployment ------
		ILSP23LinkedContractsFactory.SecondaryContractDeploymentInit memory secondaryContractDeploymentInit = ILSP23LinkedContractsFactory.SecondaryContractDeploymentInit({
			fundingAmount: 0,
			implementationContract: KM_INIT_ADDRESS,
			addPrimaryContractAddress: true,
			initializationCalldata: abi.encodePacked(LSP6KeyManagerInit.initialize.selector),
			extraInitializationParams: ""
		});
		/// ---------------------------------------------

		/// ------ Encode Data Keys & Values for updating permissions & LSP3Metadata ------
		bytes32[] memory dataKeys = new bytes32[](7);
		// ------ LSP1 ------
		dataKeys[0] = _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY;
		// ------------------

		// ------ LSP3 ------
		dataKeys[1] = _LSP3_SUPPORTED_STANDARDS_KEY;
		// ------------------

		// ------ LSP6 ------
		dataKeys[2] = _LSP6KEY_ADDRESSPERMISSIONS_ARRAY;
		dataKeys[3] = LSP2Utils.generateArrayElementKeyAtIndex(
			_LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
			0
		);
		dataKeys[4] = LSP2Utils.generateMappingKey(
			_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
			bytes20(address(this))
		);
		dataKeys[5] = LSP2Utils.generateArrayElementKeyAtIndex(
			_LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
			1
		);
		dataKeys[6] = LSP2Utils.generateMappingKey(
			_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
			bytes20(URD_UP_ADDRESS)
		);
		// ------------------

		bytes[] memory dataValues = new bytes[](7);
		// ------ LSP1 ------
		dataValues[0] = abi.encodePacked(URD_UP_ADDRESS);
		// ------------------

		// ------ LSP3 ------
		dataValues[1] = abi.encodePacked(_LSP3_SUPPORTED_STANDARDS_VALUE);
		// ------------------

		// ------ LSP6 ------
		dataValues[2] = abi.encodePacked(bytes16(uint128(2)));
		dataValues[3] = abi.encodePacked(address(this));
		dataValues[4] = abi.encodePacked(ALL_REGULAR_PERMISSIONS);
		dataValues[5] = abi.encodePacked(URD_UP_ADDRESS);
		dataValues[6] = URD_PERMISSIONS;
		// ------------------

		bytes memory postDeploymentModuleCalldata = abi.encode(
			dataKeys,
			dataValues
		);
		/// -------------------------------------------------------------------------------

		/// ------ Deploy the Universal Profile with Key Manager ------
        (universalProfileAddress, ) = LSP23LinkedContractsFactory(LSP23_ADDRESS)
			.deployERC1167Proxies(
				primaryContractDeploymentInit,
				secondaryContractDeploymentInit,
				POST_DEPLOYMENT_MODULE_ADDRESS,
				postDeploymentModuleCalldata
			);
		/// -----------------------------------------------------------

		universalProfilesOwners[universalProfileAddress] = caller;
		deployedUniversalProfiles[caller].push(universalProfileAddress);
		
		emit SaltedUniversalProfileDeployed(caller, universalProfileAddress);
    }

	/**
	 * @dev Add the LSP3 Profile Metadata for the Unviersal Profile and change the main controller from this address to a new address.
	 * 
	 * @custom:warning The caller must be the deployer of the Universal Profile at address: `universalProfileAddress`.
	 * 
	 * @param universalProfileAddress The address of the Universal profile that was deployed using this contract.
	 * @param newMainController The controller that will replace this contract for the Universal Profile.
	 * @param LSP3ProfileMetadata Universal Profile metadata.
	 */
	function changeMainController(
		address universalProfileAddress,
		address newMainController,
		bytes memory LSP3ProfileMetadata
	) public OnlyUniversalProfileOwner(universalProfileAddress) {
		/// ------ Encode Data Keys & Values for updating permissions & LSP3Metadata ------
		bytes32[] memory dataKeys = new bytes32[](4);
		// ------ LSP3 ------
		dataKeys[0] = _LSP3_PROFILE_KEY;
		// ------------------

		// ------ LSP6 ------
		// Adding permissions for the new main controller
		dataKeys[1] = LSP2Utils.generateArrayElementKeyAtIndex(
			_LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
			0
		);
		dataKeys[2] = LSP2Utils.generateMappingKey(
			_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
			bytes20(newMainController)
		);
		// Removing permissions for this contract
		dataKeys[3] = LSP2Utils.generateMappingKey(
			_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
			bytes20(address(this))
		);
		// ------------------

		bytes[] memory dataValues = new bytes[](4);
		// ------ LSP3 ------
		dataValues[0] = LSP3ProfileMetadata;
		// ------------------

		// ------ LSP6 ------
		dataValues[1] = abi.encodePacked(newMainController);
		dataValues[2] = abi.encodePacked(ALL_REGULAR_PERMISSIONS);
		// Removing permissions for this contract
		dataValues[3] = "";
		// ------------------
		/// -------------------------------------------------------------------------------

		UniversalProfile(payable(universalProfileAddress)).setDataBatch(dataKeys, dataValues);

		exportedUniversalProfiles[msg.sender].push(universalProfileAddress);
		emit SaltedUniversalProfileExported(msg.sender, universalProfileAddress);
	}

	function getUniversalProfilesOwner(
		address universalProfileAddress
	) public view returns(address owner) {
		return universalProfilesOwners[universalProfileAddress];
	}

	function getDeployedUniversalProfiles(
		address universalProfileAddress
	) public view returns(address[] memory owner) {
		return deployedUniversalProfiles[universalProfileAddress];
	}
	
	function getExportedUniversalProfiles(
		address universalProfileAddress
	) public view returns(address[] memory owner) {
		return exportedUniversalProfiles[universalProfileAddress];
	}

}