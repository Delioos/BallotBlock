// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

import "./DAOMembership.sol";
import "./ProposalManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Treasury.sol";

contract DAO is Ownable {
    string public name;
    DAOMembership public membership;
    ProposalManager public proposalManager;
    Treasury public treasury;
    
    event ProposalCreated(uint256 indexed proposalId, string title);
    event MembershipMinted(address indexed to, uint256 indexed tokenId);

    // membership tracking
    mapping(uint256 => address) public membershipOwners;
    uint256 public totalMemberships;

    constructor(
        string memory _name,
        address _owner,
        string memory membershipName,
        string memory membershipSymbol,
        uint96 initialRoyaltyBasisPoints
    ) Ownable(_owner) {
        name = _name;
        
        // Deploy membership NFT contract
        membership = new DAOMembership(
            membershipName,
            membershipSymbol,
            address(this),
            initialRoyaltyBasisPoints
        );
        
        // Deploy proposal manager
        proposalManager = new ProposalManager(address(this));
        
        // Deploy treasury
        treasury = new Treasury(address(this));
    }

    function createProposal(
        string calldata title,
        string calldata description
    ) external onlyOwner returns (uint256) {
        uint256 proposalId = proposalManager.createProposal(title, description);
        emit ProposalCreated(proposalId, title);
        return proposalId;
    }

    function mintMembership(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = membership.mint(to);
        membershipOwners[tokenId] = to;
        totalMemberships++;
        emit MembershipMinted(to, tokenId);
        return tokenId;
    }

    function setMembershipRoyalty(uint96 royaltyBasisPoints) external onlyOwner {
        membership.setRoyalty(royaltyBasisPoints);
    }

    function executeProposal(uint256 proposalId) external onlyOwner {
        proposalManager.execute(proposalId);
    }

    function withdrawFunds(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        treasury.withdraw(token, amount, to);
    }
}
