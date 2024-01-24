import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { ADDRESS_ZERO } from "../helper-hardhat-config"

import {FursionTimeLock, FursionGovernor, FursionAccessManager, FurVote} from "../typechain-types";

const setupContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { ethers } = hre;
    // @ts-ignore
    const { getNamedAccounts, deployments  } = hre
    const { log, get } = deployments
    const { deployer } = await getNamedAccounts()

    // const timeLock = (await get("FursionTimeLock"))
    // const governor = (await get("FursionGovernor"))
    const accessManager: FursionAccessManager = await ethers.getContract("FursionAccessManager", deployer)
    const voteToken: FurVote = await ethers.getContract("FurVote", deployer)
    const timeLock: FursionTimeLock = await ethers.getContract("FursionTimeLock", deployer)
    const governor: FursionGovernor = await ethers.getContract("FursionGovernor", deployer)

    log("----------------------------------------------------")
    log("Setting up contracts for roles...")

    // would be great to use multicall here...
    const proposerRole = await timeLock.PROPOSER_ROLE()
    const executorRole = await timeLock.EXECUTOR_ROLE()
    const adminRole = await timeLock.DEFAULT_ADMIN_ROLE();

    const proposerTx = await timeLock.grantRole(proposerRole, await governor.getAddress())
    await proposerTx.wait(1)
    const executorTx = await timeLock.grantRole(executorRole, ADDRESS_ZERO)
    await executorTx.wait(1)
    const revokeTx = await timeLock.revokeRole(adminRole, deployer)
    await revokeTx.wait(1)
    // Guess what? Now, anything the timelock wants to do has to go through the governance process!

    let accessAdminRole = await accessManager.ADMIN_ROLE()
    await accessManager.grantRole(accessAdminRole, await timeLock.getAddress(), 0)
    // await accessManager.setRoleGuardian(await accessManager.ADMIN_ROLE(), timeLock.getAddress(), 0)
    // TODO: revoke accessAdminRole from deployer
    // await accessManager.revokeRole(accessAdminRole, deployer)
}

export default setupContracts
setupContracts.tags = ["all", "setup"]
