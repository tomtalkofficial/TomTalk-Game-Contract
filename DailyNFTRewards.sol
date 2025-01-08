// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";


contract DailyNFTRewards is ERC721 {

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256 private _currentId;

    // Enum to represent NFT categories
    enum NFTCategory { Theta, Beta, Alpha, Sigma }

    // Mapping from token ID to NFT category
    mapping(uint256 => NFTCategory) public tokenCategories;

    // Mapping from address to first claimed timestamp
    mapping(address => uint256) public firstClaimedTime;

    // Mapping from address to last claimed timestamp
    mapping(address => uint256) public lastClaimedTime;

    // // Mapping from address to list of claimed token IDs
    // mapping(address => uint256[]) public claimHistory;

    // // Mapping from address to list of burned token IDs
    // mapping(address => uint256[]) public burnHistory;
    
    // Mapping from NFT category to base URI
    mapping(NFTCategory => string) public categoryBaseURIs;

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

        categoryBaseURIs[NFTCategory.Theta] = thetaBaseURI;
        categoryBaseURIs[NFTCategory.Beta] = betaBaseURI;
        categoryBaseURIs[NFTCategory.Alpha] = alphaBaseURI;
        categoryBaseURIs[NFTCategory.Sigma] = sigmaBaseURI;

    }

    /**
     * @dev Internal function to determine the current NFT category based on the number 
     * of days since the user started claiming.
     * 
     * @param user The address of the user.
     * @return The current NFT category to be assigned.
     */
    function _getCurrentNFTCategory(address user) internal view returns (NFTCategory) {
        uint256 daysSinceStart = (block.timestamp - firstClaimedTime[user]) / 1 days;
        
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
        require(block.timestamp - lastClaimedTime[msg.sender] >= 1 days, "Claim once every 24 hours.");

        lastClaimedTime[msg.sender] = block.timestamp;

        if(firstClaimedTime[msg.sender] == 0)
          firstClaimedTime[msg.sender] = block.timestamp;
        
        NFTCategory category = _getCurrentNFTCategory(msg.sender);
        uint256 newItemId = _mintNFT(msg.sender, category);

        // Record claim in history
        // claimHistory[msg.sender].push(newItemId);
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
        tokenCategories[newItemId] = category;
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
        // burnHistory[msg.sender].push(tokenId);
        emit NFTBurned(msg.sender, tokenId, block.timestamp);

        // Unlock the daily reward logic here
    }

    /**
     * @dev Internal function to return the base URI for a token ID.
     *
     * @param tokenId The token ID to retrieve the base URI for.
     * @return The base URI string.
     */
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        NFTCategory category = tokenCategories[tokenId];
        return categoryBaseURIs[category];
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