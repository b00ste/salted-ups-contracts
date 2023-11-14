import { ethers, network } from 'hardhat';
import { exec } from 'child_process';
import {
	LSP16UniversalFactory,
	LSP16UniversalFactory__factory,
	SaltedUniversalProfileFactory__factory,
} from '../typechain-types';
import { keccak256 } from 'ethers';

const universalFactoryAddress = '0x160000700D62B8dDC65FaeD5AC5Add2d2e30A803';
const salt =
	'0x5017000050170000501750170000501700005017501700005017000050170000';

async function main() {
	const signer = await ethers.getSigner(
		'0x42f61368744CA0079E9c6BdFb520c92031EEcFDc',
	);

	const universalFactory = new LSP16UniversalFactory__factory()
		.attach(universalFactoryAddress)
		.connect(signer) as LSP16UniversalFactory;

	const saltedUniversalProfileFactoryAddress =
		await universalFactory.computeAddress(
			keccak256(SaltedUniversalProfileFactory__factory.bytecode),
			salt,
			false,
			'0x',
		);

	const tx = await universalFactory.deployCreate2(
		SaltedUniversalProfileFactory__factory.bytecode,
		salt,
	);

	console.log(
		`https://explorer.execution.${
			network.name === 'lukso' ? 'mainnet' : 'testnet'
		}.lukso.network/address/${saltedUniversalProfileFactoryAddress}`,
	);

	await tx.wait(1);
	console.log(
		`SaltedUniversalProfileFactory addres: ${saltedUniversalProfileFactoryAddress}`,
	);

	exec(
		`npx hardhat verify ${saltedUniversalProfileFactoryAddress} --network ${network.name} --contract contracts/SaltedUniversalProfileFactory.sol:SaltedUniversalProfileFactory`,
		() => {
			console.log('SaltedUniversalProfileFactory contract is verified!');
		},
	);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
