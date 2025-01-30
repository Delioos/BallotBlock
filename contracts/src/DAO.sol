// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DAO {
    string public name;
    address public owner;
    Proposal[] public proposals;
    Membership public membershipType;

    constructor(string memory _name, address _owner, Membership _membershipType) {
        name = _name;
        owner = _owner;
        membershipType = _membershipType;
    }

    function createProposal(string memory _title, string memory _description, bool _onChainVoting) public returns (uint256) {
    }

    function vote(uint256 proposalId, bool support) public {
    }


    function distributeTokens(address[] memory recipients, uint256[] memory amounts) public {   
    }

    function mintNFT(address recipient) public {
    }
}
