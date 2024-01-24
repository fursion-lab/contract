import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../helper-functions"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployToken: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { ethers } = hre

    // @ts-ignore
    const { getNamedAccounts, deployments, network, upgrades } = hre
    const { deploy, log, get } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    const erc721Token = (await get("ERC721Token"))
    const accessManager = (await get("FursionAccessManager"))
    log("Deploying FurCoinToken and waiting for confirmations...")
    const FurCoin = await deploy("FurCoin", {
        from: deployer,
        args: [accessManager.address],
        log: true,
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
    })
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(FurCoin.address, [accessManager.address])
    }
    log("----------------------------------------------------")
    log("Deploying FurPointToken and waiting for confirmations...")
    const FurPoint = await deploy("FurPoint", {
        from: deployer,
        args: [accessManager.address],
        log: true,
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
    })
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(FurPoint.address, [accessManager.address])
    }
    log("----------------------------------------------------")
    log("Deploying FurFan and waiting for confirmations...")
    const FurFan = await deploy("FurFan", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
        proxy: {
            proxyContract: "OpenZeppelinTransparentProxy",
            execute: {
                methodName: "initialize",
                args: [accessManager.address, erc721Token.address],
            },
        }
    })
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(FurFan.address, [accessManager.address])
    }
}

export default deployToken
deployToken.tags = ["all", "token"]
