// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Karrim 9000
 * @notice Fixed-cap NFT collection: 9000 tokens, sequential mint. Beneficiary receives sale proceeds; base URI set by owner. Suited for limited digital collectibles on EVM.
 * @dev Beneficiary and max supply are immutable. ReentrancyGuard and Ownable for mainnet safety.
 */

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/token/ERC721/ERC721.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/security/ReentrancyGuard.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.6/contracts/access/Ownable.sol";

contract Karrim9000 is ERC721, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard, Ownable {

    event TokenMinted(uint256 indexed tokenId, address indexed to, uint256 paidWei, uint256 atBlock);
    event BaseURISet(string previousURI, string newURI, uint256 atBlock);
    event MintPriceUpdated(uint256 previousWei, uint256 newWei, uint256 atBlock);
    event ProceedsWithdrawn(address indexed to, uint256 amountWei, uint256 atBlock);
    event CollectionPauseToggled(bool paused);

    error K9K_ZeroAddress();
    error K9K_ZeroAmount();
    error K9K_MaxSupplyReached();
    error K9K_InsufficientPayment();
    error K9K_CollectionPaused();
    error K9K_TransferFailed();
    error K9K_InvalidTokenId();
    error K9K_NotBeneficiary();

    uint256 public constant K9K_MAX_SUPPLY = 9000;
    uint256 public constant K9K_COLLECTION_SALT = 0x4F8b2E6a0D3c7F1A9e5B8d2C6f0A4e8B1d5F9c3;

    address public immutable beneficiary;
    uint256 public immutable deployedBlock;
    bytes32 public immutable collectionDomain;

    uint256 public mintPriceWei;
    uint256 public nextTokenId;
    string private _baseTokenURI;
    bool public collectionPaused;

    constructor() ERC721("Karrim 9000", "K9K") {
        beneficiary = address(0xF4b7E2a9D1c6E0f3A8b5D2e9C1f7A4b0E6d3C9);
        deployedBlock = block.number;
        collectionDomain = keccak256(abi.encodePacked("Karrim9000_", block.chainid, block.prevrandao, K9K_COLLECTION_SALT));
        mintPriceWei = 0.01 ether;
        nextTokenId = 1;
    }

    function setCollectionPaused(bool paused) external onlyOwner {
        collectionPaused = paused;
        emit CollectionPauseToggled(paused);
    }

    function setMintPriceWei(uint256 newPriceWei) external onlyOwner {
        uint256 prev = mintPriceWei;
        mintPriceWei = newPriceWei;
        emit MintPriceUpdated(prev, newPriceWei, block.number);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        string memory prev = _baseTokenURI;
        _baseTokenURI = baseURI_;
        emit BaseURISet(prev, baseURI_, block.number);
    }

    function mint(address to) external payable nonReentrant returns (uint256 tokenId) {
        if (collectionPaused) revert K9K_CollectionPaused();
        if (to == address(0)) revert K9K_ZeroAddress();
        if (nextTokenId > K9K_MAX_SUPPLY) revert K9K_MaxSupplyReached();
        if (msg.value < mintPriceWei) revert K9K_InsufficientPayment();

        tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        if (mintPriceWei > 0) {
            (bool sent,) = beneficiary.call{value: mintPriceWei}("");
            if (!sent) revert K9K_TransferFailed();
        }
        if (msg.value > mintPriceWei) {
            (bool refund,) = msg.sender.call{value: msg.value - mintPriceWei}("");
            if (!refund) revert K9K_TransferFailed();
        }
        emit TokenMinted(tokenId, to, mintPriceWei, block.number);
        return tokenId;
    }

    function mintWithURI(address to, string calldata tokenURI_) external payable nonReentrant returns (uint256 tokenId) {
        if (collectionPaused) revert K9K_CollectionPaused();
        if (to == address(0)) revert K9K_ZeroAddress();
        if (nextTokenId > K9K_MAX_SUPPLY) revert K9K_MaxSupplyReached();
        if (msg.value < mintPriceWei) revert K9K_InsufficientPayment();

        tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        if (mintPriceWei > 0) {
            (bool sent,) = beneficiary.call{value: mintPriceWei}("");
            if (!sent) revert K9K_TransferFailed();
        }
        if (msg.value > mintPriceWei) {
            (bool refund,) = msg.sender.call{value: msg.value - mintPriceWei}("");
            if (!refund) revert K9K_TransferFailed();
        }
        emit TokenMinted(tokenId, to, mintPriceWei, block.number);
        return tokenId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function totalMinted() external view returns (uint256) {
        return nextTokenId - 1;
    }

    function maxSupply() external pure returns (uint256) {
        return K9K_MAX_SUPPLY;
    }

    function remainingSupply() external view returns (uint256) {
        return nextTokenId > K9K_MAX_SUPPLY ? 0 : K9K_MAX_SUPPLY - nextTokenId + 1;
    }

    function getBeneficiary() external view returns (address) {
        return beneficiary;
    }

    function getCollectionDomain() external view returns (bytes32) {
        return collectionDomain;
    }

    function getDeployedBlock() external view returns (uint256) {
        return deployedBlock;
    }

    function getMintPriceWei() external view returns (uint256) {
        return mintPriceWei;
    }

    function getBaseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    function isPaused() external view returns (bool) {
        return collectionPaused;
    }
}

