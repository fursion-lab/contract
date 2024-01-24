import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../helper-functions"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployGovernanceToken: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { ethers } = hre

    // @ts-ignore
    const { getNamedAccounts, deployments, network, upgrades } = hre
    const { deploy, log, get } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    const erc721Token = (await get("ERC721Token"))
    const accessManager = (await get("FursionAccessManager"))
    log("Deploying FursionToken and waiting for confirmations...")
    const Token = await deploy("FurVote", {
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
    console.log("Proxy of FursionToken deployed to:", Token.address)
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(Token.address, [deployer, erc721Token.address])
    }
    // log(`Delegating to ${deployer}`)
    // await delegate(governanceToken.address, deployer)
    // log("Delegated!")
}

// const delegate = async (governanceTokenAddress: string, delegatedAccount: string) => {
//     const governanceToken = await ethers.getContractAt("GovernanceToken", governanceTokenAddress)
//     const transactionResponse = await governanceToken.delegate(delegatedAccount)
//     await transactionResponse.wait(1)
//     console.log(`Checkpoints: ${await governanceToken.numCheckpoints(delegatedAccount)}`)
// }

export default deployGovernanceToken
deployGovernanceToken.tags = ["all", "governor"]
