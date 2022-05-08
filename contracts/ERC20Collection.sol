// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./BaseERC721.sol";
import "./PriceConverter.sol";

contract ERC20Collection is BaseERC721, ReentrancyGuard {
  IERC20 internal token;
  AggregatorV3Interface internal priceFeed;
  PriceConverter internal priceConverter;
  /**
  * @notice contract can receive Ether.
  */
  receive() external payable {}

  event Fund(address from, uint256 amount, uint256 tokenId);
  event Defund(address to, uint256 amount, uint256 tokenId);
  event OnMarket(uint256 tokenId, uint256 price);
  event OffMarket(uint256 tokenId);
  event Purchase(address seller, address buyer, uint256 tokenId, uint256 amount);
  event Melt(address owner, uint256 tokenId);

  uint256 public _faceValue;

  string constant TOKEN_MUST_BE_FUNDED = "Token must be funded";
  string constant TOKEN_ID_DOES_NOT_EXIST = "Token id does not exist";
  string constant SENDER_MUST_BE_TOKEN_OWNER = "Sender must be token owner";
  string constant PRICE_MUST_BE_AT_LEAST_FACE_VALUE = "Price must be >= face value";
  string constant TOKEN_MUST_NOT_BE_FOR_SALE = "Token must not be for sale";
  string constant TOKEN_MUST_BE_FOR_SALE = "Token must be for sale";
  string constant BUYER_CANNOT_BE_OWNER = "Buyer cannot be owner";
  string constant VALUE_MUST_EQUAL_PRICE = "Value must equal price";

  mapping(uint256 => uint256) private _listPrices;
  mapping(uint256 => uint256) private _fundedValues;

  /**
  * @dev Initializes the contract with a mint limit
  * @param mintLimit the maximum tokens a given address may own at a given time
  */
  constructor(
    uint256 mintLimit,
    uint256 __faceValue,
    string memory name,
    string memory symbol,
    string memory baseURI,
    string memory contractURI,

    string storage basePriceFeedContractAddress,
    string storage quotePriceFeedContractAddress,
    string memory erc20TokenContractAddress
  ) BaseERC721(
    name,
    symbol,
    mintLimit,
    baseURI,
    contractURI
  ) {
    _faceValue = __faceValue;
    token = IERC20(erc20TokenContractAddress);
    priceConverter = new PriceConverter();
  }


  /**
   * Returns the latest price
   */
  function getLatestPrice() public view returns (uint256) {
    (
    /*uint80 roundID*/,
    int price,
    /*uint startedAt*/,
    /*uint timeStamp*/,
    /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();
    return uint256(price);
  }

  function faceValue() public view returns (uint256) {
    return _faceValue;
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   * - the caller must have the `MINTER_ROLE`.
   * - the total supply must be less than the collection mint limit
   */
  function mint() onlyMinter public returns (uint256) {
    uint256 tokenId = BaseERC721._mint();
    return tokenId;
  }

  function getBalance() public view returns (uint) {
    return token.balanceOf(address(this));
  }

  function fund(uint256 tokenId) nonReentrant onlyMinter whenNotPaused external {
    require(_exists(tokenId), TOKEN_ID_DOES_NOT_EXIST);
    // Ensure the coin is unfunded
    require(_fundedValues[tokenId] == uint256(0));

    _fundedValues[tokenId] = _faceValue;

    // Emit a Fund event
    emit Fund(msg.sender, _faceValue, tokenId);
  }

  function defund(uint256 tokenId) nonReentrant onlyMinter whenNotPaused external {
    // Confirm token exists
    require(_exists(tokenId), TOKEN_ID_DOES_NOT_EXIST);
    // confirm the token is fully funded
    require(_fundedValues[tokenId] == _faceValue, TOKEN_MUST_BE_FUNDED);
    // Minter may defund only when the coin owner
    require(msg.sender == ownerOf(tokenId), SENDER_MUST_BE_TOKEN_OWNER);

    //    token.transfer(msg.sender, _faceValue);
    //    token.transferFrom(address(this), msg.sender, _faceValue);

    // withdraw funds to minter
    _withdrawFunds(tokenId);
  }

  function burn(uint256 tokenId) nonReentrant whenNotPaused external {
    // Ensure the coin exists
    require(_exists(tokenId), TOKEN_ID_DOES_NOT_EXIST);
    // Only the token owner may burn
    require(_isOwner(tokenId), SENDER_MUST_BE_TOKEN_OWNER);
    // Token must be funded
    require(_fundedValues[tokenId] == _faceValue, TOKEN_MUST_BE_FUNDED);
    // Token may not be for sale
    require(_listPrices[tokenId] == uint256(0), TOKEN_MUST_NOT_BE_FOR_SALE);
    // withdraw funds to owner
    _withdrawFunds(tokenId);
    ERC721._burn(tokenId);
    // emits Transfer event
    emit Melt(msg.sender, tokenId);
  }

  // callable by owner only, after specified time
  function _withdrawFunds(uint256 tokenId) private {
    // transfer the balance to the caller
    //    token.transfer(address(uint160(msg.sender)), _fundedValues[tokenId]);
    token.transferFrom(address(this), msg.sender, _faceValue);
    // Emit a Withdraw event
    emit Defund(msg.sender, _fundedValues[tokenId], tokenId);
    // Set the coin's funded value to nil
    _fundedValues[tokenId] = uint256(0);
  }

  function allowBuy(uint256 tokenId, uint256 price) external {
    // Make sure the coin exists
    require(_exists(tokenId), TOKEN_ID_DOES_NOT_EXIST);
    // Only the token owner may invoke
    require(_isOwner(tokenId), SENDER_MUST_BE_TOKEN_OWNER);
    // Listing price must be at least as much as the face value
    require(price >= _faceValue, PRICE_MUST_BE_AT_LEAST_FACE_VALUE);
    // Token must be funded
    require(_fundedValues[tokenId] == _faceValue, TOKEN_MUST_BE_FUNDED);
    _listPrices[tokenId] = price;

    emit OnMarket(tokenId, price);
  }

  function disallowBuy(uint256 tokenId) external {
    // Ensure the coin exists
    require(_exists(tokenId), TOKEN_ID_DOES_NOT_EXIST);
    // Only the token owner may invoke
    require(_isOwner(tokenId), SENDER_MUST_BE_TOKEN_OWNER);
    // Token must be funded
    require(_fundedValues[tokenId] == _faceValue, TOKEN_MUST_BE_FUNDED);
    // Delist the coin if listed
    _disallowBuy(tokenId);
  }

  function _disallowBuy(uint256 tokenId) internal {
    if (_listPrices[tokenId] != uint256(0)) {
      _listPrices[tokenId] = uint256(0);

      emit OffMarket(tokenId);
    }
  }

  // Returns the price of the eNFT in the chain's native currency
  function getNativePrice(uint256 tokenId) public view returns (uint256) {
    // Ensure the coin exists
    require(_exists(tokenId), TOKEN_ID_DOES_NOT_EXIST);
    // Fetch the price denominated in the ERC20 token
    uint256 price = _listPrices[tokenId];

    int256 conversionFactor = priceConverter.getDerivedPrice(
      basePriceFeedContractAddress,
      quotePriceFeedContractAddress,
      8
    );

    // Return the price in the native coin
    return uint256(conversionFactor) * price;
  }

  // Buy the coin in the chain's native currency
  function buy(uint256 tokenId) nonReentrant external payable {
    // Ensure the coin exists
    require(_exists(tokenId), TOKEN_ID_DOES_NOT_EXIST);
    // Capture the seller
    address seller = ownerOf(tokenId);
    // Require that the buyer is not the seller
    require(seller != msg.sender, BUYER_CANNOT_BE_OWNER);
    // Require that the coins is on sale
    // Fetch the price in the chain's native coin
    uint256 nativePrice = _listPrices[tokenId] * getLatestPrice();
    // expressed at 8dp
    require(msg.value >= nativePrice, VALUE_MUST_EQUAL_PRICE);

    BaseERC721._buy(tokenId);

    // Transfer the payment to the seller
    safeTransferFrom(seller, msg.sender, tokenId);
    // Transfer the payment to the seller
    payable(seller).transfer(msg.value);

    emit Purchase(seller, msg.sender, tokenId, _listPrices[tokenId]);
    // Reset the price to zero (not for sale)
    _listPrices[tokenId] = uint256(0);
  }

  // If the coin is listed for sale (has a price)
  // Delist it (reset the price to zero) prior to transfer
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(BaseERC721) {
    if (_exists(tokenId)) {
      _disallowBuy(tokenId);
    }

    super._beforeTokenTransfer(from, to, tokenId);
  }

  /// @notice Returns all the relevant information about a specific coin.
  function getCoin(uint256 tokenId) external view
  returns (
    bool forSale,
    uint256 price,
    uint256 fundedValue,
    string memory uri,
    address owner
  ) {
    price = _listPrices[tokenId];
    forSale = price != uint256(0);
    fundedValue = _fundedValues[tokenId];

    if (_exists(tokenId)) {
      owner = ownerOf(tokenId);
      uri = tokenURI(tokenId);
    }
    else {
      owner = address(0);
      uri = '';
    }
  }
}
