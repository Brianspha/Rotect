var RotectDAO = artifacts.require("RotectDAO");
var RotectToken = artifacts.require("RotectToken");
let accounts;
const skynetId = web3.utils.asciiToHex(
  "IADUs8d9CQjUO34LmdaaNPK_STuZo24rpKVfYW3wPPM2uQ"
);
const bigNumber = require("bignumber.js");
var proposalId;
var member1, member2, member3, member4;
config(
  {
    contracts: {
      deploy: {
        RotectDAO: {},
        RotectToken: {},
      },
    },
  },
  (err, accs) => {
    accounts = accs;
    console.log("accounts: ", accounts);
    member0 = accounts[0];
    member1 = accounts[1];
    member2 = accounts[2];
    member3 = accounts[3];
    member4 = accounts[4];
  }
);

contract("RotectDAO ", () => {
  it("should init token", async () => {
    var receipt = await RotectToken.methods
      .initialize(
        "RToken",
        "RT",
        18,
        new bigNumber(50000000000000000000000000000).toFixed()
      )
      .send({
        gas: 8000000,
      });
    assert.strictEqual(receipt !== null, true);
  });
  it("should transfer 2000000 tokens to member0", async () => {
    var receipt = await RotectToken.methods
      .transfer(member0, new bigNumber(2000000000000000000000000).toFixed())
      .send({
        gas: 8000000,
      });
    assert.strictEqual(receipt !== null, true);
  });
  it("should transfer 2000000 tokens to member1", async () => {
    var receipt = await RotectToken.methods
      .transfer(member1, new bigNumber(2000000000000000000000000).toFixed())
      .send({
        gas: 8000000,
      });
    assert.strictEqual(receipt !== null, true);
  });
  it("should transfer 2000000 tokens to member2", async () => {
    var receipt = await RotectToken.methods
      .transfer(member2, new bigNumber(2000000000000000000000000).toFixed())
      .send({
        gas: 8000000,
      });
    assert.strictEqual(receipt !== null, true);
  });
  it("should transfer 2000000 tokens to member3", async () => {
    var receipt = await RotectToken.methods
      .transfer(member3, new bigNumber(2000000000000000000000000).toFixed())
      .send({
        gas: 8000000,
      });
    assert.strictEqual(receipt !== null, true);
  });
  it("should transfer 2000000 tokens to member4", async () => {
    var receipt = await RotectToken.methods
      .transfer(member4, new bigNumber(2000000000000000000000000).toFixed())
      .send({
        gas: 8000000,
      });
  });
  it("should balance of member0", async () => {
    var balance = await RotectToken.methods.balanceOf(member0).call({
      gas: 8000000,
    });
    console.log("balance member0: ", balance);
    assert.strictEqual(balance > 0, true);
  });
  it("should balance of member1", async () => {
    var balance = await RotectToken.methods.balanceOf(member1).call({
      gas: 8000000,
      from: member1,
    });
    console.log("balance member1: ", balance);
    assert.strictEqual(balance > 0, true);
  });
  it("should balance of member2", async () => {
    var balance = await RotectToken.methods.balanceOf(member2).call({
      gas: 8000000,
      from: member2,
    });
    console.log("balance member2: ", balance);
    assert.strictEqual(balance > 0, true);
  });
  it("should balance of member3", async () => {
    var balance = await RotectToken.methods.balanceOf(member3).call({
      gas: 8000000,
      from: member3,
    });
    console.log("balance member3: ", balance);
    assert.strictEqual(balance > 0, true);
  });
  it("should balance of member4", async () => {
    var balance = await RotectToken.methods.balanceOf(member4).call({
      gas: 8000000,
      from: member4,
    });
    console.log("balance member4: ", balance);
    assert.strictEqual(balance > 0, true);
  });
});

contract("RotectDAO ", () => {
  it("should initialize the DAO", async () => {
    const receipt = await RotectDAO.methods
      .initialize(RotectToken.options.address)
      .send({
        gas: 8000000,
      });
    assert.strictEqual(receipt !== null, true);
  });
  it("should whitelist root user", async () => {
    const receipt = await RotectDAO.methods.whitelistAddress(member0).send({
      gas: 8000000,
      value: web3.utils.toWei("0.05", "ether"),
    });
    assert.strictEqual(receipt !== null, true);
  });
  it("should whitelist root member1", async () => {
    const receipt = await RotectDAO.methods.whitelistAddress(member1).send({
      gas: 8000000,
      value: web3.utils.toWei("0.05", "ether"),
    });
    assert.strictEqual(receipt !== null, true);
  });
  it("should whitelist root member2", async () => {
    const receipt = await RotectDAO.methods.whitelistAddress(member2).send({
      gas: 8000000,
      value: web3.utils.toWei("0.05", "ether"),
    });
    assert.strictEqual(receipt !== null, true);
  });
  it("should whitelist root member3", async () => {
    const receipt = await RotectDAO.methods.whitelistAddress(member3).send({
      gas: 8000000,
      value: web3.utils.toWei("0.05", "ether"),
    });
    assert.strictEqual(receipt !== null, true);
  });
  it("should whitelist root member4", async () => {
    const receipt = await RotectDAO.methods.whitelistAddress(member4).send({
      gas: 8000000,
      value: web3.utils.toWei("0.05", "ether"),
    });
    assert.strictEqual(receipt !== null, true);
  });
  it("should add Project Submission", async () => {
    const receipt = await RotectDAO.methods
      .addProjectSubmission(skynetId, 2500, 5000)
      .send({
        gas: 8000000,
        value: web3.utils.toWei("2", "ether"),
      });
    assert.strictEqual(receipt !== null, true);
  });

  it("should propose", async () => {
    const receipt = await RotectDAO.methods
      .propose(skynetId, "Proposal to accept project", 2)
      .send({
        gas: 8000000,
      });
    assert.strictEqual(receipt !== null, true);
    console.log(receipt.events.ProposalAdded.returnValues);
  });
  it("should vote", async () => {
    const receipt = await RotectDAO.methods
      .vote(0, true, "Proposal to accept project", 200)
      .send({
        gas: 8000000,
      });
    console.log("receipt: ", receipt.events.Voted.returnValues);
    assert.strictEqual(receipt !== null, true);
  });
  /* it(' member1 should vote', async () => {
         const receipt = await RotectDAO.methods.vote(0, true, "Proposal to accept project", Math.floor(Math.random()*1000)).send({
             gas: 8000000,
             from: member1
         })

         console.log('receipt: ', receipt.events.Voted.returnValues)
     })
     it(' member2 should vote', async () => {
         const receipt = await RotectDAO.methods.vote(0, true, "Proposal to accept project", Math.floor(Math.random()*1000)).send({
             gas: 8000000,
             from: member2
         })
         console.log('receipt: ', receipt.events.Voted.returnValues)
     })

     it(' member3 should vote', async () => {
         const receipt = await RotectDAO.methods.vote(0, true, "Proposal to accept project", Math.floor(Math.random()*1000)).send({
             gas: 8000000,
             from: member3
         })
         console.log('receipt: ', receipt.events.Voted.returnValues)
     })*/
  it(" should execute proposal", async () => {
    const receipt = await RotectDAO.methods.executeProposal(0).send({
      gas: 8000000,
    });
    assert.strictEqual(receipt !== null, true);
    console.log("receipt: ", receipt.events.ProposalExecuted.returnValues);
  });
  it(" should update Minimum Project Funds", async () => {
    const receipt = await RotectDAO.methods
      .updateMinimuProjectFunds(skynetId, 1000)
      .send({
        gas: 8000000,
        value: web3.utils.toWei("2", "ether"),
      });
    assert.strictEqual(receipt !== null, true);
    console.log("receipt: ", receipt.events.UpdateProjectMinFunds.returnValues);
  });
  it(" should update Max Project Funds", async () => {
    const receipt = await RotectDAO.methods
      .updateMaxProjectFunds(skynetId, 1000)
      .send({
        gas: 8000000,
        value: web3.utils.toWei("2", "ether"),
      });
    assert.strictEqual(receipt !== null, true);
    console.log("receipt: ", receipt.events.UpdateProjectMaxFunds.returnValues);
  });

  it("Should get a project submission", async()=>{
      var 
  })
});
