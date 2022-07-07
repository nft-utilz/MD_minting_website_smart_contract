// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
  @title minting website NFT contract opensource
  @author web3.0 stevejobs
  @dev ERC721A contract for minting NFT tokens
*/
contract NftContract is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public maxMintAmountPerTx;
    uint256 public maxSupply = 100;

    string public baseURI;
    string public notRevealedUri =
        "ipfs://QmcXG9QgbBocXuXHA3HukSDGF9aAEi88niNMspwvqRmaNp.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public publicM = false;

    uint256 _price = 10**16; // 0.01 ETH

    constructor()
        ERC721A("name BoredApe Yacht Club", "symbol BAYC")
        ReentrancyGuard()
    {
        maxSupply = 5000;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount, uint256 cost) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPublicSalePrice(uint256 _cost) public onlyOwner {
        _price = _cost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function airdrop(uint256 _mintAmount, address _to) public onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "airdrop amount exceeds max supply"
        );
        _safeMint(_to, _mintAmount);
    }

    function publicSaleMint(uint256 _amount)
        external
        payable
        mintCompliance(_amount)
        mintPriceCompliance(_amount, _price)
        onlyAccounts
    {
        require(publicM, "CryptoPunks: PublicSale is OFF");
        require(!paused, "CryptoPunks: Contract is paused");
        _safeMint(msg.sender, _amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function withdraw() public onlyOwner nonReentrant {
        // This will pay nft-utilz 5% of the initial sale.
        // You can remove this if you want, or keep it in to support nft-utilz open source.
        // =============================================================================
        (bool nu, ) = payable(0x45E3Ca56946e0ee4bf36e893CC4fbb96A1523212).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(nu, " nft-utilz 5% of the initial sale");
        // =============================================================================

        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }
}
