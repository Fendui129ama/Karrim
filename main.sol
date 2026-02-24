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
