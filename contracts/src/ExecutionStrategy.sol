// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ExecutionStrategy
 * @dev Abstract contract for implementing custom proposal execution strategies
 */
abstract contract ExecutionStrategy is ReentrancyGuard {
    address public immutable dao;
    
    event ProposalValidated(bytes32 indexed proposalHash, bool valid);
    event ProposalExecuted(bytes32 indexed proposalHash);
    event ProposalCanceled(bytes32 indexed proposalHash);
    
    error Unauthorized();
    error InvalidProposal();
    error ExecutionFailed();

    constructor(address _dao) {
        require(_dao != address(0), "Invalid DAO address");
        dao = _dao;
    }
    
    modifier onlyDAO() {
        if (msg.sender != dao) revert Unauthorized();
        _;
    }

    /**
     * @dev Validates if a proposal can be executed
     * @param targets Array of target addresses
     * @param values Array of ETH values
     * @param calldatas Array of calldata bytes
     * @return bool True if proposal is valid
     */
    function validateProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) external virtual returns (bool) {
        // Basic validation
        if (targets.length == 0) revert InvalidProposal();
        if (targets.length != values.length || targets.length != calldatas.length) revert InvalidProposal();

        bytes32 proposalHash = _hashProposal(targets, values, calldatas);
        
        // Validate each target and value
        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == address(0)) revert InvalidProposal();
            // Add any additional validation logic here
        }

        emit ProposalValidated(proposalHash, true);
        return true;
    }

    /**
     * @dev Executes a proposal
     * @param targets Array of target addresses
     * @param values Array of ETH values
     * @param calldatas Array of calldata bytes
     */
    function executeProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) external virtual onlyDAO nonReentrant {
        bytes32 proposalHash = _hashProposal(targets, values, calldatas);

        // Execute each call
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(calldatas[i]);
            if (!success) revert ExecutionFailed();
        }

        emit ProposalExecuted(proposalHash);
    }

    /**
     * @dev Cancels a proposal
     * @param targets Array of target addresses
     * @param values Array of ETH values
     * @param calldatas Array of calldata bytes
     */
    function cancelProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) external virtual onlyDAO {
        bytes32 proposalHash = _hashProposal(targets, values, calldatas);
        emit ProposalCanceled(proposalHash);
    }

    /**
     * @dev Internal helper to compute proposal hash
     */
    function _hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(targets, values, calldatas));
    }
}