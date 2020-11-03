pragma solidity >=0.5.0;
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./tokens/RotectToken.sol";
pragma experimental ABIEncoderV2;

contract RotectDAO is Ownable {
    using SafeMath for uint256;
    using SafeMath for int256;

    /**===================================================Structs Definitions =================================================== */
    enum State {Rejected, InProgress, AssesmentPhase, Completed}
    /**===================================================Structs Definitions =================================================== */
    struct Project {
        bytes id; //@dev referes to the skynet id for the project file
        uint256 minimumFunds; //@dev funds required to start the project
        uint256 maximumFunds; //@dev funds required for the project
        address owner;
        uint256 index;
        State state; //@dev 1= rejected 2= in progress 3= assesment phases 4=completed
        bool canChangeState; //@dev used to check if the project state can be changed after vote has been approved
        bool canUpdateFundsRequirement;
        bool exists;
    }
    struct Vote {
        bool inSupport;
        address voter;
        string justification;
        uint256 power;
    }
    struct Proposal {
        string description;
        bool executed;
        uint256 currentResult;
        bytes target; //@dev project id stored on skynet to be used for submissions[hash] when deleting
        uint256 creationDate;
        uint256 deadline;
        uint256 proposalType; //@dev 1= delete 2= Rejected 3= InProgress 4= AssesmentPhase 5= changeMinFunds =6 changeMaxFunds
        mapping(address => bool) voters;
        Vote[] votes;
        address submitter;
    }
    /**===================================================Events Definitions =================================================== */
    event Whitelisted(address addr, bool status);
    event Blacklisted(address addr, bool status);
    event TokenAddressChange(address token);
    event ProposalExecuted(uint256 id);
    event Voted(address voter, bool vote, uint256 power, string justification);
    event ProjectSubmissionCommissionChanged(uint256 newFee);
    event WhitelistFeeChanged(uint256 newFee);
    event ProjectFeeChanged(uint256 newFee);
    event ProjectSubmissionCreated(
        uint256 index,
        bytes id,
        uint256 minFunds,
        uint256 maxFunds,
        address submitter,
        State state
    );
    event ProjectSubmissionDeleted(
        uint256 index,
        bytes id,
        address submitter,
        State state
    );
    event ProjectStateChanged(State state);
    event UpdateProjectMinFunds(bytes id, uint256 amount);
    event UpdateProjectMaxFunds(bytes id, uint256 amount);
    event FeeChanged(uint256 amount);
    event ProposalAdded(
        uint256 id,
        uint8 proposalType,
        bytes hash,
        string description,
        address submitter
    );

    /**===================================================Modifiers Definitions =================================================== */
    modifier daoActive() {
        require(active == true);
        _;
    }
    modifier onlyOwner() {
        require(daoOwner == msg.sender);
        _;
    }
    modifier memberOnly() {
        require(whitelist[msg.sender]);
        require(!blacklist[msg.sender]);
        _;
    }
    modifier tokenHolderOnly() {
        require(token.balanceOf(msg.sender) >= 10**token.decimals());
        _;
    }
    /**===================================================Contract Variables Definitions =================================================== */
    address daoOwner;
    bool active = false;
    RotectToken public token;
    uint256 public submissionZeroFee = 0.0001 ether;
    uint256 public fundsUpdateFee = 0.0005 ether;
    uint256 public nonDeletedSubmissions = 0;
    uint256 public whitelistedNumber = 0;
    uint256 public tokenToWeiRatio = 10000;
    uint256 public daofee = 100; // hundredths of a percent, i.e. 100 is 1%
    uint256 public whitelistfee = 10000000000000000; // in Wei, this is 0.01 ether
    uint256 public withdrawableByDaoOwner = 0;
    uint256 proposalCount = 0;
    uint256 deadLineDays=7 days;
    uint256 projectStatusChange = 80; //@dev the project can only be changed to approved once it reaches 80% vote
    mapping(bytes => Project) projectSubmissions;
    mapping(address => uint256) deletions;
    mapping(address => bool) public whitelist;
    mapping(address => bool) blacklist;
    bytes[] public projectSubmissionKeys;
    Proposal[] public proposals;

    /**===================================================Contract Functions Definitions =================================================== */
    function initialize(address tokenAddress) public initializer {
        require(msg.sender != address(0), "Invalid sender address");
        require(tokenAddress != address(0), "Invalid token address");
        require(msg.sender != tokenAddress, "Token and sender address match");
        active = true;
        daoOwner = msg.sender;
        token = RotectToken(tokenAddress);
    }

    function addProjectSubmission(
        bytes memory id,
        uint256 minFunds,
        uint256 maxFunds
    ) public payable {
        require(
            token.balanceOf(msg.sender) >= 10**token.decimals(),
            "insufficient token balance"
        );
        require(minFunds > 0, "Invalid min project funds");
        require(
            maxFunds > 0 && minFunds < maxFunds && minFunds != maxFunds,
            "Invalid max project funds"
        );
        require(whitelist[msg.sender], "Must be whitelisted");
        require(!blacklist[msg.sender], "Must not be blacklisted");
        uint256 fee = calculateProjectSubmissionFee();
        require(
            msg.value >= fee,
            "Fee for submitting an entry must be sufficient"
        );
        projectSubmissions[id] = Project(
            id,
            minFunds,
            maxFunds,
            msg.sender,
            projectSubmissionKeys.push(id),
            State.InProgress,
            true,
            true,
            true
        );
        emit ProjectSubmissionCreated(
            projectSubmissions[id].index,
            id,
            minFunds,
            maxFunds,
            projectSubmissions[id].owner,
            projectSubmissions[id].state
        );
    }

    function propose(
        bytes memory id,
        string memory reason,
        uint8 proposalType
    ) public daoActive memberOnly {
        require(submissionExists(id), "Submission not found");
        require(
            proposalType != 1 || proposalType != 2,
            "Invalid proposal type"
        );
        uint256 proposalId = proposals.length++;
        Proposal storage p = proposals[proposalId];
        p.description = reason;
        p.executed = false;
        p.creationDate = now;
        p.submitter = msg.sender;
        p.proposalType = proposalType;
        p.target = id;
        p.deadline = now + deadLineDays;//@dev all projects are given 7 days to reach their target
        proposals[proposalId] = p;
        emit ProposalAdded(proposalId, proposalType, id, reason, msg.sender);
        proposalCount = proposalId + 1;
    }

    function unlockMyTokens() external {
        require(!active, "Dao still active");
        require(token.getLockedAmount(msg.sender) > 0);
        token.decreaseLockedAmount(
            msg.sender,
            token.getLockedAmount(msg.sender)
        );
    }

    function executeProposal(uint256 _id) public daoActive {
        Proposal storage proposal = proposals[_id];
        require(
            now >= proposal.deadline && !proposal.executed,
            "proposal hasnt expired"
        );
        if (proposal.proposalType == 1 && proposal.currentResult > 0) {
            assert(deleteProjecSubmission(proposal.target));
        }
        if (proposal.proposalType == 2 && proposal.currentResult > 0) {
            updateProjectState(proposal.target, State.Rejected);
        }
        if (proposal.proposalType == 3 && proposal.currentResult > 0) {
            updateProjectState(proposal.target, State.InProgress);
        } else if (proposal.proposalType == 4 && proposal.currentResult > 0) {
            updateProjectState(proposal.target, State.AssesmentPhase);
        }
        uint256 len = proposal.votes.length;
        for (uint256 i = 0; i < len; i++) {
            token.decreaseLockedAmount(
                proposal.votes[i].voter,
                proposal.votes[i].power
            );
        }
        proposal.executed = true;
        emit ProposalExecuted(_id);
    }

    function vote(
        uint256 proposalId,
        bool vote_stance,
        string memory reason,
        uint256 votePower
    ) public daoActive tokenHolderOnly returns (uint256) {
        require(votePower > 0, "cant vote");
        require(
            uint256(votePower) <= token.balanceOf(msg.sender),
            "insufficient token balance"
        );
        Proposal storage p = proposals[proposalId];
        require(p.executed == false, "Proposal executed already.");
        require(p.deadline > now, "Proposal expired.");
        require(p.voters[msg.sender] == false, "User already voted.");
        uint256 voteid = p.votes.length++;
        Vote storage pvote = p.votes[voteid];
        pvote.inSupport = vote_stance;
        pvote.justification = reason;
        pvote.voter = msg.sender;
        pvote.power = votePower;
        p.voters[msg.sender] = true;
        p.currentResult = (vote_stance)
            ? p.currentResult.add(uint256(votePower))
            : p.currentResult.sub(uint256(votePower));
        token.increaseLockedAmount(daoOwner, votePower);
        emit Voted(msg.sender, vote_stance, votePower, reason);
        return p.currentResult;
    }

    function deleteProjecSubmission(bytes memory id)
        internal
        daoActive
        returns (bool)
    {
        require(submissionExists(id), "Submission not found");
        Project storage sub = projectSubmissions[id];

        sub.exists = false;
        deletions[projectSubmissions[id].owner] += 1;
        if (deletions[projectSubmissions[id].owner] >= 5) {
            blacklistAddress(projectSubmissions[id].owner);
        }

        emit ProjectSubmissionDeleted(
            sub.index,
            sub.id,
            projectSubmissions[id].owner,
            projectSubmissions[id].state
        );

        nonDeletedSubmissions -= 1;
        return true;
    }

    function calculateProjectSubmissionFee() internal view returns (uint256) {
        return submissionZeroFee.mul(nonDeletedSubmissions);
    }

    function blacklistAddress(address offender) internal daoActive {
        require(!blacklist[offender], "Already blacklisted");
        blacklist[offender] = true;
        token.increaseLockedAmount(
            offender,
            token.getUnlockedAmount(offender)
        );
        emit Blacklisted(offender, true);
    }

    function removeFromBlackListMsgSender() public payable {
        removeFromBlackList(msg.sender);
    }

    function removeFromBlackList(address offender) public payable daoActive {
        require(msg.value >= 0.05 ether, "Unblacklisting fee");
        require(blacklist[offender], "Address not blacklisted");
        require(
            notVoting(offender),
            "Offender must not be involved in a vote"
        );
        withdrawableByDaoOwner = withdrawableByDaoOwner.add(msg.value);
        blacklist[offender] = false;
        token.decreaseLockedAmount(offender, token.balanceOf(offender));
        emit Blacklisted(offender, false);
    }

    function whitelistAddress(address user) public payable daoActive {
        require(!whitelist[user], "not be whitelisted");
        require(!blacklist[user], "not be blacklisted");
        require(msg.value >= whitelistfee, "insufficient funds to whitelist");

        withdrawableByDaoOwner += msg.value;

        whitelist[user] = true;
        whitelistedNumber++;
        emit Whitelisted(user, true);

        if (msg.value > whitelistfee) {
            buyTokensInternal(user, msg.value.sub(whitelistfee));
        }
    }

    function updateTokenAddress(address tokenAddress) public daoActive onlyOwner {
        require(tokenAddress != address(0), "invalid address");
        token = RotectToken(tokenAddress);
        emit TokenAddressChange(tokenAddress);
    }

    function notVoting(address voter) internal view daoActive returns (bool) {
        for (uint256 i = 0; i < proposalCount; i++) {
            if (!proposals[i].executed && proposals[i].voters[voter]) {
                return false;
            }
        }
        return true;
    }

    function submissionExists(bytes memory id) public view returns (bool) {
        return projectSubmissions[id].exists;
    }

    function getProjectSubmission(bytes memory id)
        public
        view
        returns (
            address,
            State,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            projectSubmissions[id].owner,
            projectSubmissions[id].state,
            projectSubmissions[id].index,
            projectSubmissions[id].minimumFunds,
            projectSubmissions[id].maximumFunds,
            proposals[projectSubmissions[id].index].votes.length,
            proposals[projectSubmissions[id].index].currentResult
        );
    }

    function getAllProjectSubmissionKeys()
        public
        view
        returns (bytes[] memory)
    {
        return projectSubmissionKeys;
    }

    function updateMinimuProjectFunds(bytes memory id, uint256 minFunds)
        public
        payable
        daoActive
        memberOnly
        returns (bool)
    {
        require(msg.sender != address(0), "invalid address");
        require(projectSubmissions[id].exists, "project doesnt exist");
        require(
            projectSubmissions[id].state != State.Completed,
            "project already complted"
        );
        require(
            projectSubmissions[id].state != State.Rejected,
            "project already Rejected"
        );
        require(
            projectSubmissions[id].canUpdateFundsRequirement,
            "project funds cannot be altered"
        );
        require(
            projectSubmissions[id].minimumFunds != minFunds,
            "funds must not be the same"
        );
        require(msg.value == fundsUpdateFee, "insufficient funds");
        projectSubmissions[id].minimumFunds = projectSubmissions[id]
            .minimumFunds
            .add(minFunds);
        withdrawableByDaoOwner = withdrawableByDaoOwner.add(msg.value);
        emit UpdateProjectMinFunds(id, minFunds);
    }

    function updateMaxProjectFunds(bytes memory id, uint256 maxFunds)
        public
        payable
        daoActive
        memberOnly
        returns (bool)
    {
        require(msg.sender != address(0), "invalid address");
        require(projectSubmissions[id].exists, "project doesnt exist");
        require(
            projectSubmissions[id].state != State.Completed,
            "project already complted"
        );
        require(
            projectSubmissions[id].state != State.AssesmentPhase,
            "project in AssementPhase"
        );
        require(
            projectSubmissions[id].canUpdateFundsRequirement,
            "project funds cannot be altered"
        );
        require(
            projectSubmissions[id].maximumFunds != maxFunds,
            "funds must not be the same"
        );
        projectSubmissions[id].maximumFunds = projectSubmissions[id]
            .maximumFunds
            .add(maxFunds);
        withdrawableByDaoOwner = withdrawableByDaoOwner.add(msg.value);
        emit UpdateProjectMaxFunds(id, maxFunds);
    }

    function lowerSubmissionFee(uint256 fee) external onlyOwner daoActive {
        require(fee < submissionZeroFee, "fee must be lower");
        submissionZeroFee = fee;
        emit FeeChanged(fee);
    }

    function increaseSubmissionFee(uint256 fee) external onlyOwner daoActive {
        require(fee > submissionZeroFee, "fee must be greater");
        submissionZeroFee = fee;
        emit FeeChanged(fee);
    }

    function updateProjectState(bytes memory id, State state)
        public
        daoActive
        returns (bool)
    {
        require(msg.sender != address(0), "invalid address");
        require(
            state == State.Rejected ||
                state == State.InProgress ||
                state == State.AssesmentPhase ||
                state == State.Completed,
            "Invalid state"
        );
        require(projectSubmissions[id].exists, "project doesnt exist");
        require(
            projectSubmissions[id].state != State.Completed,
            "project already complted"
        );
        require(
            projectSubmissions[id].canChangeState,
            "state cannot be changed"
        );
        projectSubmissions[id].state = state;
        emit ProjectStateChanged(state);
    }

    function() external payable daoActive {
        if (!whitelist[msg.sender]) {
            whitelistAddress(msg.sender);
        } else {
            buyTokensInternal(msg.sender, msg.value);
        }
    }

    function daoTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function buyTokensInternal(address _buyer, uint256 _wei)
        internal
        daoActive
    {
        require(!blacklist[_buyer], "address blacklisted");
        uint256 tokens = _wei.mul(tokenToWeiRatio);
        if (daoTokenBalance() < tokens) {
            msg.sender.transfer(_wei);
        } else {
            token.transfer(_buyer, tokens);
        }
    }
function updateDeadLineDays(uint256 newDuration) public daoActive onlyOwner
}
