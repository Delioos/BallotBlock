// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title DAOMembership
 * @dev ERC721 token representing DAO membership with voting power and royalties
 */
contract DAOMembership is ERC721, ERC721Royalty, Pausable, ReentrancyGuard {
    // DAO contract that owns this membership
    address public immutable dao;
    
    // Token ID counter
    uint256 private _nextTokenId;

    // Collection-wide royalty tracking
    uint96 public currentRoyaltyBasisPoints;

    // Voting power per token
    mapping(uint256 => uint256) public votingPower;
    
    // Default voting power for new tokens
    uint256 public defaultVotingPower = 1;

    event MembershipMinted(address indexed to, uint256 indexed tokenId);
    event MembershipBurned(uint256 indexed tokenId);
    event VotingPowerUpdated(uint256 indexed tokenId, uint256 newVotingPower);
    event DefaultVotingPowerUpdated(uint256 newDefaultVotingPower);
    event RoyaltyUpdated(uint96 newRoyaltyBasisPoints);
    event PauseStateChanged(bool newPausedState);
    
    error Unauthorized();
    error InvalidTokenId();
    error InvalidParameters();

    constructor(
        string memory name_,
        string memory symbol_,
        address daoAddress,
        uint96 initialRoyaltyBasisPoints
    ) ERC721(name_, symbol_) {
        require(daoAddress != address(0), "Invalid DAO address");
        require(initialRoyaltyBasisPoints <= 10000, "Invalid royalty basis points");
        
        dao = daoAddress;
        currentRoyaltyBasisPoints = initialRoyaltyBasisPoints;
        _setDefaultRoyalty(daoAddress, initialRoyaltyBasisPoints);
    }

    modifier onlyDAO() {
        if (msg.sender != dao) revert Unauthorized();
        _;
    }

    /**
     * @dev Mints a new membership token
     * @param to Address to mint the token to
     * @return tokenId The ID of the minted token
     */
    function mint(address to) 
        external 
        onlyDAO 
        nonReentrant 
        whenNotPaused 
        returns (uint256) 
    {
        require(to != address(0), "Invalid recipient");
        
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        
        // Set default voting power for new token
        votingPower[tokenId] = defaultVotingPower;
        
        emit MembershipMinted(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Burns a membership token
     * @param tokenId ID of token to burn
     */
    function burn(uint256 tokenId) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to burn");
        
        _burn(tokenId);
        delete votingPower[tokenId];
        
        emit MembershipBurned(tokenId);
    }

    /**
     * @dev Updates royalty for the entire collection
     * @param royaltyBasisPoints New royalty in basis points (100 = 1%)
     */
    function setRoyalty(uint96 royaltyBasisPoints) 
        external 
        onlyDAO 
        whenNotPaused 
    {
        if (royaltyBasisPoints > 10000) revert InvalidParameters();
        
        currentRoyaltyBasisPoints = royaltyBasisPoints;
        _setDefaultRoyalty(dao, royaltyBasisPoints);
        
        emit RoyaltyUpdated(royaltyBasisPoints);
    }

    /**
     * @dev Updates voting power for a specific token
     * @param tokenId Token ID to update
     * @param newVotingPower New voting power value
     */
    function setVotingPower(uint256 tokenId, uint256 newVotingPower) 
        external 
        onlyDAO 
        whenNotPaused 
    {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (newVotingPower == 0) revert InvalidParameters();
        if (newVotingPower > type(uint96).max) revert InvalidParameters();
        
        votingPower[tokenId] = newVotingPower;
        emit VotingPowerUpdated(tokenId, newVotingPower);
    }

    /**
     * @dev Updates default voting power for new tokens
     * @param newDefaultVotingPower New default voting power value
     */
    function setDefaultVotingPower(uint256 newDefaultVotingPower) 
        external 
        onlyDAO 
        whenNotPaused 
    {
        defaultVotingPower = newDefaultVotingPower;
        emit DefaultVotingPowerUpdated(newDefaultVotingPower);
    }

    /**
     * @dev Gets the current voting power of a token
     * @param tokenId Token ID to query
     * @return Current voting power
     */
    function getVotingPower(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return votingPower[tokenId];
    }

    /**
     * @dev Emergency pause/unpause functionality
     */
    function togglePause() external onlyDAO {
        bool newPausedState = !paused();
        if (newPausedState) {
            _pause();
        } else {
            _unpause();
        }
        emit PauseStateChanged(newPausedState);
    }

    // Required overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _burn(uint256 tokenId) 
        internal 
        override(ERC721, ERC721Royalty) 
    {
        super._burn(tokenId);
    }
}