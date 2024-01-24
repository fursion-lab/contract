import { ethers, network } from "hardhat"
import {
    developmentChains,
    VOTING_DELAY,
    proposalsFile,
    FUNC,
    PROPOSAL_DESCRIPTION,
    NEW_STORE_VALUE,
} from "../helper-hardhat-config"
import * as fs from "fs"
import {moveBlocks} from "../utils/move-blocks";
import {Box, ERC721Token, FursionGovernor, FursionToken} from "../typechain-types";

export async function propose() {
    const token: ERC721Token = await ethers.getContract("ERC721Token")
    const vote: FursionToken = await ethers.getContract("FursionToken")
    const [deployer, voter] = await ethers.getSigners();

    await token.safeMint(deployer, 1);
    await vote.safeMint(deployer, 1, "");
    console.log(await vote.getVotes(deployer));
    await vote.delegate(deployer);
    console.log(await vote.getVotes(deployer));
    await token.safeMint(deployer, 2);
    await vote.safeMint(deployer, 2, "");
    console.log(await vote.getVotes(deployer));
}

propose()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
