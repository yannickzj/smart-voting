var Voting = artifacts.require("./Voting.sol");

contract('Voting', function (accounts) {

    var ballot;
    var stateNum = 2;
    var candidateList = ["Trump", "Clinton"];
    var voterIDList = [101, 102, 103, 104, 105, 106, 107, 108, 109, 110];
    var voterStateList = [0, 0, 0, 0, 0, 0, 0, 1, 1, 1];

    before(function () {
        console.info("===========================================================");
        console.info("set up the voting contract");
        return Voting.new().then(function (instance) {
            ballot = instance;
            console.info("assign stateNum = " + stateNum);
            return ballot.assignStateNum(stateNum);
        }).then(function () {
            console.info("candidateList = " + candidateList);
            return ballot.nominate(candidateList);
        }).then(function () {
            for (i = 0; i < accounts.length && i < 10; i++) {
                console.info("register voter (" + accounts[i] + ", " + voterIDList[i] + ", " + voterStateList[i] + ")");
                ballot.registerVoter(accounts[i], voterIDList[i], voterStateList[i]);
            }
        }).then(function() {
            return ballot.startVoting();
        }).then(function() {
            return ballot.delegateVote(accounts[3], {from: accounts[1]});
        }).then(function() {
            return ballot.delegateVote(accounts[8], {from: accounts[9]});
        }).then(function() {
            return ballot.delegateVote(accounts[1], {from: accounts[5]});
        }).then(function () {
            return ballot.vote(0, {from: accounts[3]});
        }).then(function () {
            return ballot.delegateVote(accounts[0], {from: accounts[2]});
        }).then(function () {
            return ballot.delegateVote(accounts[2], {from: accounts[4]});
        }).then(function () {
            return ballot.vote(1, {from: accounts[0]});
        }).then(function() {
            return ballot.delegateVote(accounts[7], {from: accounts[8]});
        }).then(function() {
            return ballot.delegateVote(accounts[5], {from: accounts[6]});
        }).then(function () {
            return ballot.vote(1, {from: accounts[7]});
        }).then(function () {
            console.info("===========================================================");
        });
    });

    it("should succeed if the voter tries to access its voter information", function () {
        return ballot.getVoterInfo.call(accounts[2], {from: accounts[2]}).then(function (val) {
            assert.equal(voterIDList[2], val[0].toNumber(), "voter's id doesn't match");
            assert.equal(voterStateList[2], val[5].toNumber(), "voter's state info doesn't match");
        });
    });

    it("should fail if someone tries to access other voter's information", function () {
        return ballot.getVoterInfo.call(accounts[1], {from: accounts[2]}).catch(function (e) {
            console.info(e.stack);
        });
    });

    it("should fail if voter tries to \"double vote\"", function () {
        return ballot.vote(0, {from: accounts[3]}).catch(function (e) {
            console.info(e.stack);
        });
    });

    it("should succeed when checking voting status in state1", function () {
        return ballot.getStateCount(0).then(function (result) {
            assert.equal(4, result[0].toNumber(), "stateCount0 doesn't match for candidate1");
            assert.equal(3, result[1].toNumber(), "stateCount0 doesn't match for candidate2");
        });
    });

    it("should succeed when checking voting status in state2", function () {
        return ballot.getStateCount(1).then(function (result) {
            assert.equal(0, result[0].toNumber(), "stateCount1 doesn't match for candidate1");
            assert.equal(3, result[1].toNumber(), "stateCount1 doesn't match for candidate2");
        });
    });

    it("should fail if voter tries to vote when creator stops voting", function () {
        return ballot.stopVoting().then(function () {
            return ballot.finished.call();
        }).then(function (result) {
            assert.equal(true, result, "voting has not been stopped");
        }).then(function () {
            return ballot.vote(0, {from: accounts[3]});
        }).catch(function (e) {
            console.info(e.stack);
        });
    });

    it("candidate2 should win when counting votes based on number of vote", function () {
        return ballot.countWinner.call().then(function (result) {
            assert.equal(1, result.toNumber(), "candidate2 doesn't win");
        });
    });

    it("candidate1 should win when counting votes base on state voting results", function () {
        return ballot.countWinnerByState.call().then(function (result) {
            assert.equal(0, result.toNumber(), "candidate1 doesn't win");
        });
    });
});
