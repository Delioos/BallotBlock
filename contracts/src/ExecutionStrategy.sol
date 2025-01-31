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
    ) external virtual returns (bool);

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
    ) external virtual onlyDAO nonReentrant;

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
    ) external virtual onlyDAO;

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