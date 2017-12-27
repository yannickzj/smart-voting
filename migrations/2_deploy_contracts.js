var SafeMath = artifacts.require("./SafeMath.sol");
var Voting = artifacts.require("./Voting.sol");

module.exports = function (deployer) {
    deployer.deploy(SafeMath);
    deployer.link(SafeMath, Voting);
    deployer.deploy(Voting);
};
