import { ethers, network } from "hardhat"
import { keccak256, toUtf8Bytes } from "ethers"
import {
    FUNC,
    NEW_STORE_VALUE,
    PROPOSAL_DESCRIPTION,
    MIN_DELAY,
    developmentChains,
} from "../helper-hardhat-config"
import { moveBlocks } from "../utils"
import { moveTime } from "../utils"

import {FursionGovernor} from "../typechain-types";

export async function queueAndExecute() {
    const args = [NEW_STORE_VALUE]
    const functionToCall = FUNC
    const box = await ethers.getContract("Box")
    const encodedFunctionCall = box.interface.encodeFunctionData(functionToCall, args)
    const descriptionHash = keccak256(toUtf8Bytes(PROPOSAL_DESCRIPTION))
    // could also use ethers.utils.id(PROPOSAL_DESCRIPTION)

    const governor: FursionGovernor = await ethers.getContract("FursionGovernor")
    console.log("Queueing...")
    const queueTx = await governor.queue([box.getAddress()], [0], [encodedFunctionCall], descriptionHash)
    await queueTx.wait(1)

    if (developmentChains.includes(network.name)) {
        await moveTime(MIN_DELAY + 1)
        await moveBlocks(1)
    }

    console.log("Executing...")
    // this will fail on a testnet because you need to wait for the MIN_DELAY!
    const executeTx = await governor.execute(
        [box.getAddress()],
        [0],
        [encodedFunctionCall],
        descriptionHash
    )
    await executeTx.wait(1)
    console.log(`Box value: ${await box.retrieve()}`)
}

queueAndExecute()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
