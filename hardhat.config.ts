import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
	networks: {
		lukso_testnet: {
			chainId: 4201,
			url: "https://rpc.testnet.lukso.gateway.fm",
			accounts: [
				"0x5ceb698df85f33cfe0295b39534a1489b166fd409f159617c04cb0785d8f1bff",
			],
		},
		lukso: {
			chainId: 42,
			url: "https://rpc.lukso.gateway.fm",
			accounts: [
				"0x5ceb698df85f33cfe0295b39534a1489b166fd409f159617c04cb0785d8f1bff",
			],
		},
	},
	etherscan: {
		apiKey: "no-api-key-needed",
		customChains: [
			{
				network: "lukso_testnet",
				chainId: 4201,
				urls: {
					apiURL: "https://api.explorer.execution.testnet.lukso.network/api",
					browserURL:
						"https://explorer.execution.testnet.lukso.network/",
				},
			},
			{
				network: "lukso",
				chainId: 42,
				urls: {
					apiURL: "https://api.explorer.execution.mainnet.lukso.network/api",
					browserURL:
						"https://explorer.execution.mainnet.lukso.network/",
				},
			},
		],
	},
	solidity: {
		version: "0.8.22",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};

export default config;
