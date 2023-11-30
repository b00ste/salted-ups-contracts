// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// utils
import {LSP2Utils} from "@lukso/lsp-smart-contracts/contracts/LSP2ERC725YJSONSchema/LSP2Utils.sol";

// constants
import "./constants.sol";
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
import {LSP0ERC725Account} from "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import {ILSP23LinkedContractsFactory} from "@lukso/lsp-smart-contracts/contracts/LSP23LinkedContractsFactory/ILSP23LinkedContractsFactory.sol";
import {LSP23LinkedContractsFactory} from "@lukso/lsp-smart-contracts/contracts/LSP23LinkedContractsFactory/LSP23LinkedContractsFactory.sol";
import {UniversalProfileInit} from "@lukso/lsp-smart-contracts/contracts/UniversalProfileInit.sol";
import {UniversalProfile} from "@lukso/lsp-smart-contracts/contracts/UniversalProfile.sol";
import {LSP6KeyManagerInit} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManagerInit.sol";

// errors
error CallerNotUniversalProfileOwner(address caller, address universalProfile);
error ValueSentIsLessThanPrice(uint256 valueSent, uint256 price);

// events
event SaltedUniversalProfileDeployed(
	address indexed deployer,
	address indexed universalProfileAddress
);
event SaltedUniversalProfileExported(
	address indexed deployer,
	address indexed universalProfileAddress
);

contract SaltedUniversalProfileFactory is LSP0ERC725Account {
	/**
	 * @dev Used to store the owner of each deployed up.
	 */
    mapping (address => address) private universalProfilesOwners;

	/**
	 * @dev Vefify if the sent value is at least 1 ether, revert otherwise.
	 */
	modifier OnlyPricePaid() {
		if (msg.value < 1 ether) {
			revert ValueSentIsLessThanPrice(msg.value, 1 ether);
		}
		_;
	}

	constructor (address newOwner) LSP0ERC725Account(newOwner) {}

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
    function deploy(
		bytes32 salt
	)
		public
		payable
		OnlyPricePaid
		returns(address universalProfileAddress)
	{
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

		uint128 deployedUniversalProfilesCount = uint128(bytes16(
			_getData(DEPLOYED_SALTED_UP_ARRAY_KEY)
		));

		_setData(
			DEPLOYED_SALTED_UP_ARRAY_KEY,
			abi.encodePacked(bytes16(deployedUniversalProfilesCount + 1)));
		_setData(
			LSP2Utils.generateArrayElementKeyAtIndex(
				DEPLOYED_SALTED_UP_ARRAY_KEY,
				deployedUniversalProfilesCount
			),
			abi.encodePacked(universalProfileAddress)
		);
		_setData(
			LSP2Utils.generateMappingKey(
				DEPLOYED_SALTED_UP_ARRAY_MAP_PREFIX,
				bytes20(universalProfileAddress)
			),
			abi.encodePacked(msg.sender, false)
		);
		
		emit SaltedUniversalProfileDeployed(msg.sender, universalProfileAddress);
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
	) public {
		address unviersalProfileOwner = address(bytes20(_getData(
			LSP2Utils.generateMappingKey(
				DEPLOYED_SALTED_UP_ARRAY_MAP_PREFIX,
				bytes20(universalProfileAddress)
			)
		)));

		if (msg.sender != unviersalProfileOwner) {
			revert CallerNotUniversalProfileOwner(msg.sender, universalProfileAddress);
		}

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

		_setData(
			LSP2Utils.generateMappingKey(
				DEPLOYED_SALTED_UP_ARRAY_MAP_PREFIX,
				bytes20(universalProfileAddress)
			),
			abi.encodePacked(unviersalProfileOwner, true)
		);

		emit SaltedUniversalProfileExported(msg.sender, universalProfileAddress);
	}

	function setData(bytes32 dataKey, bytes memory dataValue) public payable override {
		if (bytes16(dataKey) == bytes16(DEPLOYED_SALTED_UP_ARRAY_KEY)) {
			revert("Cannot manually edit `DeployedSaltedUniversalProfiles[]` data key");
		}
		if (bytes10(dataKey) == DEPLOYED_SALTED_UP_ARRAY_MAP_PREFIX) {
			revert("Cannot manually edit `DeployedSaltedUniversalProfileMap` data key");
		}

		super.setData(dataKey, dataValue);
	}
}