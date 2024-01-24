import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../helper-functions"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployGovernanceToken: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { ethers } = hre

    // @ts-ignore
    const { getNamedAccounts, deployments, network, upgrades } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    log("Deploying FursionAccessManager and waiting for confirmations...")
    const Token = await deploy("FursionAccessManager", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
        proxy: {
            proxyContract: "OpenZeppelinTransparentProxy",
            execute: {
                methodName: "initialize",
                args: [deployer],
            },
        }
    })
    console.log("Proxy of FursionAccessManager deployed to:", Token.address)
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(Token.address, [deployer])
    }
}


export default deployGovernanceToken
deployGovernanceToken.tags = ["all", "governor"]
