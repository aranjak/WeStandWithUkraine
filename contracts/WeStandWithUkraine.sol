// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WeStandWithUkraine is ERC721, Ownable, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private supply;
    string private contractUri;

    uint256 public maxSupply = 10;
    uint256 public cost = 0.5 ether;
    uint256 public maxMintAmount = 3;

    string public baseURI;
    string public baseExtension = ".json";

    event RoyaltiesReceived(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    );

    constructor(string memory initBaseURI, string memory initContractUri)
        ERC721("We Stand With Ukraine", "WSWU")
    {
        contractUri = initContractUri;
        baseURI = initBaseURI;
    }

    /**
     * @notice get contract uri
     * @return contract uri
     */
    function contractURI() external view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice get token uri
     * @param tokenId token id to get uri
     * @return token uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * @notice mint tokens
     * @param amount qty to mint
     */
    function mint(uint256 amount) external payable {
        require(amount > 0, "Mint amount should be > 0");
        require(amount <= maxMintAmount, "Max mint amount overflow");
        require(supply.current() + amount <= maxSupply, "Max supply overflow");
        require(msg.value == cost * amount, "Wrong ETH amount");

        for (uint256 i = 1; i <= amount; i++) {
            supply.increment();
            uint256 newTokenId = supply.current();
            _mint(msg.sender, newTokenId);
        }
    }

    /**
     * @notice mint tokens by owner
     * @param amount qty to mint
     * @dev callable only by contract owner
     */
    function mintWithOwner(uint256 amount) external onlyOwner {
        require(maxSupply > supply.current(), "Max supply is reached");

        if (maxSupply - supply.current() > amount) {
            for (uint256 i = 1; i <= amount; i++) {
                supply.increment();
                uint256 newTokenId = supply.current();
                _mint(owner(), newTokenId);
            }
        } else {
            for (uint256 i = 1; i <= maxSupply - supply.current(); i++) {
                supply.increment();
                uint256 newTokenId = supply.current();
                _mint(owner(), newTokenId);
            }
        }
    }

    /**
     * @notice get total supply
     * @return total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return supply.current();
    }

    /**
     * @notice get account tokens
     * @param _owner account adderess to get tokens for
     * @return array of tokens
     */
    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount &&
            currentTokenId <= supply.current()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    /**
     * @notice update contract uri
     * @param newURI new contract uri
     * @dev callable only by contract owner
     */
    function setContractURI(string memory newURI) external onlyOwner {
        contractUri = newURI;
    }

    /**
     * @notice update base uri
     * @param newBaseURI new base uri
     * @dev callable only by contract owner
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @notice update base extension
     * @param newBaseExtension new base extension
     * @dev callable only by contract owner
     */
    function setBaseExtension(string memory newBaseExtension) public onlyOwner {
        baseExtension = newBaseExtension;
    }

    /**
     * @notice update max supply
     * @param newMaxSupply new max supply
     * @dev callable only by contract owner
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    /**
     * @notice update mint cost
     * @param newCost new cost to mint
     * @dev callable only by contract owner
     */
    function setCost(uint256 newCost) external onlyOwner {
        cost = newCost;
    }

    /**
     * @notice update max mint amount
     * @param newMaxMintAmount new max mint amount
     * @dev callable only by contract owner
     */
    function setMaxMintAmount(uint256 newMaxMintAmount) external onlyOwner {
        maxMintAmount = newMaxMintAmount;
    }

    /**
     * @notice get base uri, internal
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice withdraw ETH
     * @dev callable only by contract owner
     */
    function withdraw() external onlyOwner {
        require(
            payable(msg.sender).send(address(this).balance),
            "Can not withdraw"
        );
    }

    /**
     * @notice check if contract supports interface id
     * @param interfaceId interface Id
     * @dev callable only by contract owner
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns royalty reciever address and royalty amount
     * @param _tokenId Token Id
     * @param _salePrice Value to calculate royalty from
     * @return receiver Royalty reciever address
     * @return amount Royalty amount
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 amount)
    {
        require(_tokenId > 0, "Query for nonexistent token");
        receiver = this.owner();
        if (_salePrice <= 10000) {
            amount = 0;
        } else {
            amount = (_salePrice * 1000) / 10000;
        }
    }

    /**
     * @notice Calls when royalty recieved
     */
    function onRoyaltiesReceived(
        address _royaltyRecipient,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    ) external returns (bytes4) {
        emit RoyaltiesReceived(
            _royaltyRecipient,
            _buyer,
            _tokenId,
            _tokenPaid,
            _amount,
            _metadata
        );
        return
            bytes4(
                keccak256(
                    "onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)"
                )
            );
    }

    /**
     * @notice It allows the admins to get tokens sent to the contract
     * @param tokenAddress: the address of the token to withdraw
     * @param tokenAmount: the number of token amount to withdraw
     * @dev Only callable by multisig wallet.
     */
    function recoverTokens(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(0), "address can not be zero!");
        IERC20(tokenAddress).safeTransfer(address(msg.sender), tokenAmount);
    }
}
