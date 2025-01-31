// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./DAO.sol";

/**
 * @title DAOFactory
 * @dev Factory contract for creating new DAOs with standardized setup
 */
contract DAOFactory is Ownable, ReentrancyGuard, Pausable {
    // Track all created DAOs
    mapping(address => bool) public isDAO;
    address[] public allDAOs;
    
    // Default parameters
    uint256 public defaultQuorum;
    uint256 public defaultVotingDelay;
    
    event DAOCreated(
        address indexed daoAddress,
        string name,
        string membershipSymbol,
        address indexed owner
    );
    event DefaultParametersUpdated(
        uint256 quorum,
        uint256 votingDelay
    );
    
    error InvalidParameters();
    error DeploymentFailed();

    constructor(
        uint256 _defaultQuorum,
        uint256 _defaultVotingDelay
    ) Ownable(msg.sender) {
        require(_defaultQuorum > 0, "Invalid quorum");
        require(_defaultVotingDelay > 0, "Invalid voting delay");
        defaultQuorum = _defaultQuorum;
        defaultVotingDelay = _defaultVotingDelay;
    }

    /**
     * @dev Creates a new DAO with associated contracts
     * @param name DAO name
     * @param membershipName Membership NFT name
     * @param membershipSymbol Membership NFT symbol
     * @param initialRoyaltyBasisPoints Initial royalty in basis points (100 = 1%)
     * @return daoAddress The address of the newly created DAO
     */
    function createDAO(
        string memory name,
        string memory membershipName,
        string memory membershipSymbol,
        uint96 initialRoyaltyBasisPoints
    ) external nonReentrant whenNotPaused returns (address daoAddress) {
        // Input validation
        if (bytes(name).length == 0 ||
            bytes(membershipName).length == 0 ||
            bytes(membershipSymbol).length == 0 ||
            initialRoyaltyBasisPoints > 10000) {
            revert InvalidParameters();
        }

        // Deploy new DAO
        DAO dao = new DAO(
            name,
            msg.sender,
            membershipName,
            membershipSymbol,
            initialRoyaltyBasisPoints
        );
        
        daoAddress = address(dao);
        
        // Register DAO
        isDAO[daoAddress] = true;
        allDAOs.push(daoAddress);
        
        emit DAOCreated(
            daoAddress,
            name,
            membershipSymbol,
            msg.sender
        );
    }

    /**
     * @dev Updates default parameters for new DAOs
     * @param newQuorum New default quorum
     * @param newVotingDelay New default voting delay
     */
    function setDefaultParameters(
        uint256 newQuorum,
        uint256 newVotingDelay
    ) external onlyOwner {
        require(newQuorum > 0, "Invalid quorum");
        require(newVotingDelay > 0, "Invalid voting delay");
        
        defaultQuorum = newQuorum;
        defaultVotingDelay = newVotingDelay;
        
        emit DefaultParametersUpdated(newQuorum, newVotingDelay);
    }

    /**
     * @dev Returns the total number of DAOs created
     */
    function getDaoCount() external view returns (uint256) {
        return allDAOs.length;
    }

    /**
     * @dev Returns a page of DAO addresses
     * @param offset Starting index
     * @param limit Maximum number of addresses to return
     */
    function getDAOs(uint256 offset, uint256 limit) 
        external 
        view 
        returns (address[] memory daos) 
    {
        uint256 total = allDAOs.length;
        if (offset >= total) {
            return new address[](0);
        }
        
        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }
        
        daos = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            daos[i - offset] = allDAOs[i];
        }
    }

    /**
     * @dev Emergency pause/unpause functionality
     */
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}