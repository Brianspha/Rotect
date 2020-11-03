/*global artifacts, contract, it*/
/**/
const schoolManagement = artifacts.require("schoolManagement");
const utils = require("web3-utils");
let accounts;
let schoolKeys = [],
  school_details = {},
  request_keys = [],
  official_keys,
  request_details = "";
const skynetId = web3.utils.asciiToHex(
  "IADUs8d9CQjUO34LmdaaNPK_STuZo24rpKVfYW3wPPM2uQ"
);
const description = web3.utils.asciiToHex(
  "IADUs8d9CQjUO34LmdaaNPK_STuZo24rpKVfYW3wPPM2uQ"
);

// For documentation please see https://framework.embarklabs.io/docs/contracts_testing.html
config(
  {
    contracts: {
      deploy: {
         schoolManagement:{
        args:[]
      }
      },
    },
  },
  (err, accs) => {
    accounts = accs;
    console.log("accounts: ", accounts, " error: ", err);
  }
);

contract("schoolManagement ", () => {
  console.log("accounts: ", accounts);
  var school = {
    name: utils.asciiToHex("Sample School"),
    province: utils.asciiToHex("Sample Province"),
    school_id: accounts[1],
    principle_no: utils.asciiToHex("0840838902"),
  };
  it("Should registered a school", async function() {
    let result = await schoolManagement.methods
      .registerSchool(school.name, school.province, school.school_id)
      .send();
    console.log(
      "school registered: ",
      result.events.school_registered.returnValues
    );
    assert.strictEqual(result.events.school_registered.returnValues, true);
  });

  it("Should get school keys", async function() {
    let result = await schoolManagement.methods
      .getRegisteredSchoolKeys()
      .call();
    console.log("getRegisteredSchoolKeys: ", result);
    schoolKeys = result;
    assert.strictEqual(result.length > 0, true);
  });

  it("Should get a schools details", async function() {
    school_details = await schoolManagement.methods
      .getSchool(schoolKeys[0])
      .call();
    assert.strictEqual(school_details !== null, true);
  });

  it("should log a new comlaint", async () => {
    var receipt = await schoolManagement.methods
      .logRequest(skynetId, accounts[1])
      .send();
    console.log(
      "results of logging a query: ",
      receipt.events.logged_request.returnValues
    );
    assert.strictEqual(receipt.events.logged_request.returnValues, true);
  });
  it("Should get requested keys", async () => {
    request_keys = await schoolManagement.methods.getRequestedKeys().call();
    console.log("requested_keys: ", request_keys);
    assert.strictEqual(request_keys.length > 0, true);
  });
  it("Should get requested details", async () => {
    request_details = await schoolManagement.methods
      .getRequestedDetails(request_keys[0])
      .call();
    console.log("request_details: ", request_details);
    assert.strictEqual(request_details !== null, true);
  });
  it("Should register official", async () => {
    var receipt = await schoolManagement.methods
      .registerOfficial()
      .send({ from: accounts[2] });
    assert.strictEqual(receipt !== null, true);
  });
  it("Should get official keys", async () => {
    official_keys = await schoolManagement.methods.getOfficialKeys().call();
    console.log("official keys: ", official_keys);
    assert.strictEqual(official_keys.length > 0, true);
  });
  it("Should get official", async () => {
    var official_details = await schoolManagement.methods
      .getOfficial(official_keys[0])
      .call();
    console.log("official_details: ", official_details);
    assert.strictEqual(official_details, true);
  });
  it("Should upload log request ", async () => {
    var updated = await schoolManagement.methods
      .updateLogRequest(request_keys[0], description)
      .send({ from: official_keys[0] });
    console.log(
      "updated log request: ",
      updated.events.request_resolved.returnValues
    );
    assert.strictEqual(updated.events.request_resolved.returnValues, true);
  });
});
