import { expect } from "chai";
import { network, deployments, ethers, run } from "hardhat"
import { developmentChains } from "../helper-hardhat-config"
import {FurCommissionToken} from "../typechain-types";

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("FurCommissionToken", async function () {
        let token: FurCommissionToken;

        beforeEach(async () => {
            await deployments.fixture(["mocks", "governor", "token"])
            const accounts = await ethers.getSigners()
            token = await ethers.getContract("FurCommissionToken")
        })

        it("Should return name Token", async function () {
            expect(await token.name()).to.equal("FurCommissionToken");
        });
    });