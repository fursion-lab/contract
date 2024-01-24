import {DeployFunction} from "hardhat-deploy/types"
import {deployments, network} from "hardhat"

const deployFunction: DeployFunction = async (hre) => {
    const {deploy, log, get} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId: number | undefined = network.config.chainId

    // If we are on a local development network, we need to deploy mocks!
    if (chainId === 31337) {
        log(`Local network detected! Deploying Test...`)

        const timelock = (await get("FursionTimeLock"))
        await deploy("Box", {
            from: deployer,
            args: [timelock.address],
            log: true,
            waitConfirmations: 1,
        })

        log(`Test Deployed!`)
    }
}

export default deployFunction
deployFunction.tags = [`all`, `test`]