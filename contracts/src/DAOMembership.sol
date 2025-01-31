// SPDX-License-Identifier: MIT
// @author: @deliossssss

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAOMembership is ERC721, ERC721Royalty {
    // DAO contract that owns this membership
    address public immutable dao;
    
    // Token ID counter
    uint256 private _nextTokenId;

    // Add collection-wide royalty tracking
    uint96 public currentRoyaltyBasisPoints;

    constructor(
        string memory name_,
        string memory symbol_,
        address daoAddress,
        uint96 initialRoyaltyBasisPoints
    ) ERC721(name_, symbol_) {
        dao = daoAddress;
        currentRoyaltyBasisPoints = initialRoyaltyBasisPoints;
        _setDefaultRoyalty(daoAddress, initialRoyaltyBasisPoints);
    }

    // Only DAO can mint new memberships
    function mint(address to) external returns (uint256) {
        require(msg.sender == dao, "Only DAO can mint");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    // Only DAO can set royalties
    function setRoyalty(uint96 royaltyBasisPoints) external {
        require(msg.sender == dao, "Only DAO can set royalty");
        currentRoyaltyBasisPoints = royaltyBasisPoints;
        _setDefaultRoyalty(dao, royaltyBasisPoints);
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
}