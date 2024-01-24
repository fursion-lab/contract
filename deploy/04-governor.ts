import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../helper-functions"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployGovernor: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { ethers } = hre

    // @ts-ignore
    const { getNamedAccounts, deployments, network, upgrades } = hre
    const { deploy, log, get } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    const token = (await get("FurVote"))
    const timelock = (await get("FursionTimeLock"))
    log("Deploying Governor and waiting for confirmations...")
    const Governor = await deploy("FursionGovernor", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
        proxy: {
            proxyContract: "OpenZeppelinTransparentProxy",
            execute: {
                methodName: "initialize",
                args: [token.address, timelock.address],
            },
        }
    })
    console.log("Proxy of FursionTimelock deployed to:", Governor.address)
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(Governor.address, [token.address, timelock.address])
    }
}

export default deployGovernor
deployGovernor.tags = ["all", "governor"]
