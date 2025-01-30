// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

contract ProposalManager {
    // Proposal states
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }
    
    struct Proposal {
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        uint256 forVotes;
        uint256 againstVotes;
        // Efficient vote tracking
        mapping(address => bool) hasVoted;
    }

    // DAO that owns this proposal manager
    address public immutable dao;
    
    // Proposals storage
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Voting period in seconds
    uint256 public constant VOTING_PERIOD = 7 days;

    constructor(address _dao) {
        dao = _dao;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO can call");
        _;
    }

    function createProposal(
        string calldata title,
        string calldata description
    ) external onlyDAO returns (uint256) {
        uint256 proposalId = proposalCount++;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.title = title;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + VOTING_PERIOD;
        
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (support) {
            proposal.forVotes += 1;
        } else {
            proposal.againstVotes += 1;
        }
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        
        if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        }
        
        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }
}