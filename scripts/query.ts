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
import {Box, FursionGovernor} from "../typechain-types";

export async function query(args: any[], functionToCall: string, proposalDescription: string) {
    const governor: FursionGovernor = await ethers.getContract("FursionGovernor")
    // check the logs for the proposalId
    let events = await governor.queryFilter(governor.filters.ProposalCreated);
    // console.log(events)
    // console.log(events[0].args)
    const proposalId = events[0].args.proposalId
    console.log(`Proposed with proposal ID:\n  ${proposalId}`)

    const proposalState = await governor.state(proposalId)
    const proposalSnapShot = await governor.proposalSnapshot(proposalId)
    const proposalDeadline = await governor.proposalDeadline(proposalId)
    // save the proposalId
    storeProposalId(proposalId);

    const { againstVotes, forVotes, abstainVotes } = await governor.proposalVotes(proposalId)
    console.log(`Votes For: ${forVotes.toString()}`)
    console.log(`Votes Against: ${againstVotes.toString()}`)
    console.log(`Votes Neutral: ${abstainVotes.toString()}\n`)

    // the Proposal State is an enum data type, defined in the IGovernor contract.
    // 0:Pending, 1:Active, 2:Canceled, 3:Defeated, 4:Succeeded, 5:Queued, 6:Expired, 7:Executed
    console.log(`Current Proposal State: ${proposalState}`)
    // What block # the proposal was snapshot
    console.log(`Current Proposal Snapshot: ${proposalSnapShot}`)
    // The block number the proposal voting expires
    console.log(`Current Proposal Deadline: ${proposalDeadline}`)
}

function storeProposalId(proposalId: any) {
    const chainId = network.config.chainId!.toString();
    let proposals:any;

    if (fs.existsSync(proposalsFile)) {
        proposals = JSON.parse(fs.readFileSync(proposalsFile, "utf8"));
    } else {
        proposals = { };
        proposals[chainId] = [];
    }
    proposals[chainId].push(proposalId.toString());
    fs.writeFileSync(proposalsFile, JSON.stringify(proposals), "utf8");
}

query([NEW_STORE_VALUE], FUNC, PROPOSAL_DESCRIPTION)
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
