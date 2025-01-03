// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DailyNFTRewards is ERC721, Ownable {
    uint256 private _currentId;

    // Enum to represent NFT categories
    enum NFTCategory { Theta, Beta, Alpha, Sigma }

    // Mapping from token ID to NFT category
    mapping(uint256 => NFTCategory) private _tokenCategories;

    // Mapping from address to first claimed timestamp
    mapping(address => uint256) private _firstClaimedTime;

    // Mapping from address to last claimed timestamp
    mapping(address => uint256) private _lastClaimedTime;

    // Mapping from address to list of claimed token IDs
    mapping(address => uint256[]) private _claimHistory;

    // Mapping from address to list of burned token IDs
    mapping(address => uint256[]) private _burnHistory;
    
    // Mapping from NFT category to base URI
    mapping(NFTCategory => string) private _categoryBaseURIs;

    // Events for claim and burn
    event NFTClaimed(address indexed user, uint256 indexed tokenId, NFTCategory category, uint256 timestamp);
    event NFTBurned(address indexed user, uint256 indexed tokenId, uint256 timestamp);

    /**
     * @dev Constructor to initialize the ERC721 token with name and symbol.
     */
    constructor(
        string memory thetaBaseURI,
        string memory betaBaseURI,
        string memory alphaBaseURI,
        string memory sigmaBaseURI
    ) ERC721("DailyNFTRewards", "DNR") {

        _categoryBaseURIs[NFTCategory.Theta] = thetaBaseURI;
        _categoryBaseURIs[NFTCategory.Beta] = betaBaseURI;
        _categoryBaseURIs[NFTCategory.Alpha] = alphaBaseURI;
        _categoryBaseURIs[NFTCategory.Sigma] = sigmaBaseURI;
    }



    /**
     * @dev Internal function to determine the current NFT category based on the number 
     * of days since the user started claiming.
     * 
     * @param user The address of the user.
     * @return The current NFT category to be assigned.
     */
    function _getCurrentNFTCategory(address user) internal view returns (NFTCategory) {
        uint256 daysSinceStart = (block.timestamp - _firstClaimedTime[user]) / 1 days;
        
        if (daysSinceStart < 7) {
            return NFTCategory.Theta;
        } else if (daysSinceStart < 14) {
            return NFTCategory.Beta;
        } else if (daysSinceStart < 30) {
            return NFTCategory.Alpha;
        } else {
            return NFTCategory.Sigma;
        }
    }

    /**
     * @dev Function for users to claim an NFT daily.
     * Emits an {NFTClaimed} event.
     */
    function claimNFT() external {
        require(block.timestamp - _lastClaimedTime[msg.sender] >= 1 days, "Claim once every 24 hours.");

        _lastClaimedTime[msg.sender] = block.timestamp;

        if(_firstClaimedTime[msg.sender] == 0)
          _firstClaimedTime[msg.sender] = block.timestamp;
        
        NFTCategory category = _getCurrentNFTCategory(msg.sender);
        uint256 newItemId = _mintNFT(msg.sender, category);

        // Record claim in history
        _claimHistory[msg.sender].push(newItemId);
        emit NFTClaimed(msg.sender, newItemId, category, block.timestamp);
    }

    /**
     * @dev Internal function to mint a new NFT.
     * 
     * @param recipient The address that will receive the minted NFT.
     * @param category The category of the NFT to be minted.
     * @return The token ID of the minted NFT.
     */
    function _mintNFT(address recipient, NFTCategory category) internal returns (uint256) {
        uint256 newItemId = _currentId++;
        _mint(recipient, newItemId);
        _tokenCategories[newItemId] = category;
        return newItemId;
    }

    /**
     * @dev Function to burn an NFT owned by the caller to unlock the next daily reward.
     * Emits an {NFTBurned} event.
     * 
     * @param tokenId The token ID of the NFT to be burned.
     */
    function burnAndUnlock(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You do not own this token.");
        _burn(tokenId);

        // Record burn in history
        _burnHistory[msg.sender].push(tokenId);
        emit NFTBurned(msg.sender, tokenId, block.timestamp);

        // Unlock the daily reward logic here
    }

    /**
     * @dev Function to get the category of a specific NFT.
     * 
     * @param tokenId The token ID of the NFT.
     * @return The category of the NFT.
     */
    function getNFTCategory(uint256 tokenId) external view returns (NFTCategory) {
        // require(_exists(tokenId), "Token does not exist.");
        return _tokenCategories[tokenId];
    }

    /**
     * @dev Function to get the last claimed timestamp for a user.
     * 
     * @param user The address of the user.
     * @return The timestamp when the user last claimed an NFT.
     */
    function getLastClaimedTime(address user) external view returns (uint256) {
        return _lastClaimedTime[user];
    }

    /**
     * @dev Function to get the claim history of a user.
     * 
     * @param user The address of the user.
     * @return An array of token IDs that the user has claimed.
     */
    function getClaimHistory(address user) external view returns (uint256[] memory) {
        return _claimHistory[user];
    }

    /**
     * @dev Function to get the burn history of a user.
     * 
     * @param user The address of the user.
     * @return An array of token IDs that the user has burned.
     */
    function getBurnHistory(address user) external view returns (uint256[] memory) {
        return _burnHistory[user];
    }

    /**
     * @dev Function to set the base URI for an NFT category.
     *
     * @param category The category for which the base URI is set.
     * @param baseURI The new base URI to be set.
     */
    function setCategoryBaseURI(NFTCategory category, string memory baseURI) external onlyOwner {
        _categoryBaseURIs[category] = baseURI;
    }

    /**
     * @dev Internal function to return the base URI for a token ID.
     *
     * @param tokenId The token ID to retrieve the base URI for.
     * @return The base URI string.
     */
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        NFTCategory category = _tokenCategories[tokenId];
        return _categoryBaseURIs[category];
    }

    /**
     * @dev Function to return the token URI for a given token ID.
     *
     * @param tokenId The token ID to retrieve the URI for.
     * @return The token URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI(tokenId);
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId))) : "";
    }
}