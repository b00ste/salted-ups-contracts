import { ethers } from 'hardhat';
import { Signer, ZeroHash } from 'ethers';
import LSP23LinkedContractsFactory from '@lukso/lsp-smart-contracts/artifacts/LSP23LinkedContractsFactory.json';
import { UPDeployer, UPDeployer__factory } from '../typechain-types';

describe('testing UPDeployer', () => {
	before('Setting LSP23 code at the standardized address', async () => {
		await ethers.provider.send('hardhat_setCode', [
			'0x2300000a84d25df63081feaa37ba6b62c4c89a30',
			LSP23LinkedContractsFactory.bytecode,
		]);
	});

	describe('testing `deploy(...)`', async () => {
		let context: {
			signers: Signer[];
			upDeployer: UPDeployer;
		};

		before(async () => {
			const signers = await ethers.getSigners();

			const upDeployer = await new UPDeployer__factory(
				signers[0],
			).deploy();

			context = {
				signers,
				upDeployer,
			};
		});

		it('should deploy Universal Profile', async () => {
			const tx = await context.upDeployer.deploy(ZeroHash);
			console.log(tx);
		});
	});
});
