pragma solidity ^0.4.18;

import './SafeMath.sol';

contract Voting {

    using SafeMath for uint;

    // type for voter
    struct Voter {
    uint id;
    uint accumulatedVote;
    bool voted;
    address delegate;
    uint candidate;
    uint state;
    }

    // type for candidate
    struct Candidate {
    bytes32 name;
    uint numVote;
    }

    // current ballot creator
    address public creator;

    // mapping from address to voter
    mapping (address => Voter) voters;

    // mapping from state index to candidate list
    mapping (uint => Candidate[]) public candidateTable;

    // mapping for voteCountByState
    mapping (uint => uint) voteCountByState;

    // number of state
    uint public stateNum;

    // number of candidates
    uint public candidateNum;

    // flag to indicate the election starts
    bool public started;

    // flog to indicate the election finished
    bool public finished;

    // create a new ballot
    function Voting() public {
        creator = msg.sender;
        started = false;
    }

    // assign state number
    function assignStateNum(uint _stateNum) onlyCreator public {
        require(_stateNum > 0);
        stateNum = _stateNum;
    }

    // nominate candidates
    function nominate(bytes32[] candidateNames) onlyCreator public {
        require(stateNum > 0);
        for (uint i = 0; i < stateNum; i++) {
            Candidate[] storage candidates = candidateTable[i];
            for (uint j = 0; j < candidateNames.length; j++) {
                candidates.push(Candidate({
                name : candidateNames[j],
                numVote : 0
                }));
            }
            candidateTable[i] = candidates;
        }
        candidateNum = candidateNames.length;
    }

    // register voter
    function registerVoter(address _voter, uint _id, uint _state) onlyCreator public {
        require(!voters[_voter].voted && voters[_voter].accumulatedVote == 0);
        require(_state < stateNum && _state >= 0);
        voters[_voter] = Voter({
        id : _id,
        accumulatedVote : 1,
        voted : false,
        delegate : 0x0,
        candidate : 0,
        state : _state
        });
        Register(_voter, _id, _state);
    }

    // start to vote
    function startVoting() onlyCreator public {
        started = true;
    }

    // finish voting
    function stopVoting() onlyCreator onlyStarted public {
        finished = true;
    }

    // delegate vote
    function delegateVote(address _to) onlyStarted public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        require(msg.sender != _to);
        require(voters[_to].delegate != msg.sender);
        require(voters[_to].state == sender.state);

        // find the root delegate with path compression
        address next = voters[_to].delegate;
        while (next != address(0)) {
            if (voters[next].delegate != address(0)) {
                voters[_to].delegate = voters[next].delegate;
            }
            _to = voters[_to].delegate;
            next = voters[_to].delegate;
            require(_to != msg.sender);
        }

        sender.voted = true;
        sender.delegate = _to;
        Voter storage delegate = voters[sender.delegate];
        if (delegate.voted) {
            candidateTable[delegate.state][delegate.candidate].numVote += sender.accumulatedVote;
        }
        else {
            delegate.accumulatedVote += sender.accumulatedVote;
        }
        Delegate(msg.sender, _to);
    }

    // give your vote to the candidate
    function vote(uint _candidate) onlyStarted public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.candidate = _candidate;
        candidateTable[sender.state][_candidate].numVote += sender.accumulatedVote;
        Vote(msg.sender, _candidate, sender.accumulatedVote);
    }

    // get creator address
    function getCreatorAddress() public constant returns (address) {
        return creator;
    }

    // get the candidate voting information
    function getCandidateInfo(uint _candidate) public constant returns (string name, uint voteCount) {
        name = bytes32ToString(candidateTable[0][_candidate].name);
        for (uint i = 0; i < stateNum; i++) {
            voteCount += candidateTable[i][_candidate].numVote;
        }
    }

    // get the voter information
    function getVoterInfo(address _voter) public constant returns (
    uint id, uint accumulatedVote, bool voted, address delegate, uint candidate, uint state) {
        require(msg.sender == creator || msg.sender == _voter);
        Voter storage voter = voters[_voter];
        id = voter.id;
        accumulatedVote = voter.accumulatedVote;
        voted = voter.voted;
        delegate = voter.delegate;
        candidate = voter.candidate;
        state = voter.state;
    }

    // get the state voting result
    function getStateCount(uint _state) public constant returns (uint[] voteCount) {
        voteCount = new uint[](candidateNum);
        for (uint i = 0; i < candidateNum; i++) {
            voteCount[i] = candidateTable[_state][i].numVote;

        }
    }

    // compute the winner based on the vote number
    function countWinner() public constant returns (uint winnerIndex) {
        uint maxVoteCount = 0;
        for (uint i = 0; i < candidateNum; i++) {
            uint voteCount = 0;
            for (uint j = 0; j < stateNum; j++) {
                voteCount += candidateTable[j][i].numVote;
            }
            if (voteCount > maxVoteCount) {
                maxVoteCount = voteCount;
                winnerIndex = i;
            }
        }
    }

    // compute the winner base on the state voting results, all votes will belong to the winner of the state
    function countWinnerByState() public returns (uint winner){
        for (uint i = 0; i < stateNum; i++) {
            uint totalCount = 0;
            uint maxCount = 0;
            uint maxIndex = 0;
            for (uint j = 0; j < candidateNum; j++) {
                uint curCount = candidateTable[i][j].numVote;
                totalCount += curCount;
                if (curCount > maxCount) {
                    maxCount = curCount;
                    maxIndex = j;
                }
            }
            voteCountByState[j] += totalCount;
        }

        uint maxVoteCount = 0;
        for (uint k = 0; k < candidateNum; k++) {
            if (voteCountByState[k] > maxVoteCount) {
                maxVoteCount = voteCountByState[k];
                winner = k;
            }
        }
    }

    // convert bytes32 to string
    function bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    // modifier
    modifier onlyCreator {
        require(msg.sender == creator);
        _;
    }

    modifier onlyStarted {
        require(started && !finished);
        _;
    }

    modifier onlyFinished {
        require(started && finished);
        _;
    }

    // events
    event Vote(address _voter, uint _candidate, uint _vote);
    event Delegate(address _voter, address _delegate);
    event Register(address _voter, uint _id, uint _state);

}
