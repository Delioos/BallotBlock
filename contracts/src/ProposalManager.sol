// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ExecutionStrategy.sol";

/**
 * @title ProposalManager
 * @dev Manages proposal creation, voting, and execution for the DAO
 */
contract ProposalManager is ReentrancyGuard, Pausable {
    enum ProposalState { 
        Pending,    // Just created
        Active,     // In voting period
        Canceled,   // Canceled by DAO
        Defeated,   // Failed to reach quorum or majority
        Succeeded,  // Passed but not executed
        Executed    // Passed and executed
    }
    
    struct Proposal {
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
    }

    address public immutable dao;
    ExecutionStrategy public executionStrategy;
    
    // Governance parameters
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public quorumRequired;
    uint256 public votingDelay;
    
    // Proposals storage
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        address proposer,
        uint256 startTime,
        uint256 endTime
    );
    event ProposalQueued(
        bytes32 indexed proposalHash,
        address target,
        uint256 value,
        uint256 timestamp
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        bool support,
        uint256 weight
    );
    
    error Unauthorized();
    error InvalidProposal();
    error AlreadyVoted();
    error VotingClosed();
    error QuorumNotReached();
    error ExecutionFailed();
    error InvalidParameters();
    error ValueTooHigh();

    uint256 public constant MAX_TRANSACTION_VALUE = 1000 ether;
    uint256 public constant TIMELOCK_DURATION = 2 days;
    uint256 public constant MAX_TARGETS = 10;
    mapping(bytes32 => uint256) public pendingProposals;

    constructor(
        address _dao,
        uint256 _quorumRequired,
        uint256 _votingDelay
    ) {
        require(_dao != address(0), "Invalid DAO address");
        dao = _dao;
        quorumRequired = _quorumRequired;
        votingDelay = _votingDelay;
    }

    modifier onlyDAO() {
        if (msg.sender != dao) revert Unauthorized();
        _;
    }

    /**
     * @dev Creates a new proposal
     * @param title Proposal title
     * @param description Proposal description
     * @param targets Target addresses for execution
     * @param values ETH values for execution
     * @param calldatas Calldata for execution
     */
    function createProposal(
        string memory title,
        string memory description,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) external onlyDAO nonReentrant whenNotPaused returns (uint256) {
        if (bytes(title).length == 0) revert InvalidParameters();
        if (bytes(description).length == 0) revert InvalidParameters();
        if (targets.length == 0) revert InvalidParameters();
        if (targets.length > MAX_TARGETS) revert InvalidParameters();
        require(targets.length == values.length && 
            targets.length == calldatas.length,
            "Invalid proposal length"
        );

        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals[proposalId];
        
        newProposal.title = title;
        newProposal.description = description;
        newProposal.startTime = block.timestamp + votingDelay;
        newProposal.endTime = newProposal.startTime + VOTING_PERIOD;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.calldatas = calldatas;

        emit ProposalCreated(
            proposalId,
            title,
            msg.sender,
            newProposal.startTime,
            newProposal.endTime
        );

        return proposalId;
    }

    /**
     * @dev Casts a vote on a proposal
     * @param proposalId The proposal ID
     * @param support True for yes, false for no
     */
    function vote(
        uint256 proposalId,
        bool support
    ) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (block.timestamp <= proposal.startTime) revert VotingClosed();
        if (block.timestamp > proposal.endTime) revert VotingClosed();

        proposal.hasVoted[msg.sender] = true;

        // TODO: Get voting weight from membership NFT
        uint256 weight = 1;

        if (support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }

        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    /**
     * @dev Executes a successful proposal
     * @param proposalId The proposal ID
     */
    function execute(uint256 proposalId) external onlyDAO nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.executed) revert InvalidProposal();
        if (block.timestamp <= proposal.endTime) revert VotingClosed();
        if (proposal.forVotes + proposal.againstVotes < quorumRequired) revert QuorumNotReached();
        if (proposal.forVotes <= proposal.againstVotes) revert InvalidProposal();

        proposal.executed = true;

        if (address(executionStrategy) != address(0)) {
            executionStrategy.executeProposal(
                proposal.targets,
                proposal.values,
                proposal.calldatas
            );
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Returns the current state of a proposal
     * @param proposalId The proposal ID
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        
        if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        }
        
        if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        }
        
        if (proposal.forVotes + proposal.againstVotes < quorumRequired) {
            return ProposalState.Defeated;
        }
        
        if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        }
        
        return ProposalState.Succeeded;
    }

    /**
     * @dev Sets the execution strategy
     * @param _executionStrategy New execution strategy address
     */
    function setExecutionStrategy(address _executionStrategy) external onlyDAO {
        executionStrategy = ExecutionStrategy(_executionStrategy);
    }

    /**
     * @dev Updates the quorum requirement
     * @param _quorumRequired New quorum requirement
     */
    function setQuorumRequired(uint256 _quorumRequired) external onlyDAO {
        quorumRequired = _quorumRequired;
    }

    /**
     * @dev Updates the voting delay
     * @param _votingDelay New voting delay
     */
    function setVotingDelay(uint256 _votingDelay) external onlyDAO {
        votingDelay = _votingDelay;
    }

    /**
     * @dev Emergency pause/unpause functionality
     */
    function togglePause() external onlyDAO {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function queueProposal(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyDAO returns (bytes32) {
        if (value > MAX_TRANSACTION_VALUE) revert ValueTooHigh();
        
        bytes32 proposalHash = keccak256(abi.encode(target, value, data));
        pendingProposals[proposalHash] = block.timestamp + TIMELOCK_DURATION;
        
        emit ProposalQueued(proposalHash, target, value, block.timestamp);
        return proposalHash;
    }
}