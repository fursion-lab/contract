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
    const furCoin = (await get("FurCoin"))
    log("Deploying FurWorkToken and waiting for confirmations...")
    const FurWork = await deploy("FurWorkToken", {
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
        await verify(FurWork.address, [accessManager.address])
    }
    log("----------------------------------------------------")
    log("Deploying FurCommissionToken and waiting for confirmations...")
    const FurComm = await deploy("FurCommissionToken", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
        proxy: {
            proxyContract: "OpenZeppelinTransparentProxy",
            execute: {
                methodName: "initialize",
                args: [accessManager.address, erc721Token.address, furCoin.address, FurWork.address],
            },
        }
    })
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(FurComm.address, [accessManager.address])
    }
}

export default deployToken
deployToken.tags = ["all", "token"]
