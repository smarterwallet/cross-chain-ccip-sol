![image](https://github.com/Solidityarchitect/cross-chain-erc20/assets/125990317/7a2125c0-f253-403d-b2b9-e62ab06c13b9)
![image](https://github.com/Solidityarchitect/cross-chain-erc20/assets/125990317/ede6f805-bd37-4c45-9b3f-f4ff084c170d)
![image](https://github.com/Solidityarchitect/cross-chain-erc20/assets/125990317/ee584f5e-f996-46bf-8a18-56252d98661f)
![image](https://github.com/Solidityarchitect/cross-chain-erc20/assets/125990317/03e78f66-bdb3-4339-aa34-af3b5265afe7)

```shell
git clone https://github.com/Solidityarchitect/cross-chain-erc20.git
yarn
settings .env
yarn hardhat run scripts/01-deploy-lp.js --network "yourtestnet"
yarn hardhat run scripts/02-deploy-receiver.js --network "yourtestnet"
yarn hardhat run scripts/03-transferowner.js --network "yourtestnet"  (Pass in the deployed DestChainReceiverAddress and liquidityPoolAddress)
yarn hardhat run scripts/04-deploy-sender.js --network "yourtestnet"
```
