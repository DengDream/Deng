pragma solidity ^0.4.23;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import './strings.sol';
import './Console.sol';
import {IterableMapping} from './iterable_mapping.sol';

contract StarNotary is ERC721,Console {
  using strings for *;
  using IterableMapping for IterableMapping.itmap;
  IterableMapping.itmap public starsForSale;

  function addStarForSale(uint _key, uint _value) public {
    starsForSale.insert(_key,_value);
  }

  function getPriceByStarTokenID(uint _tokenId) public returns(uint){
    return starsForSale.getValueByKey(_tokenId);
  }

  struct Star {
    string name;
    string ra;
    string dec;
    string mag;
    // StarCoordinators coordinator;
    string starStory;
  }

  struct StarCoordinators{
    string ra;
    string dec;
    string mag;
  }

  mapping(uint256 => Star) public tokenIdToStarInfo;
  /* mapping(uint256 => uint256) public starsForSale; */
  //a map to store coordinates info to keep uniqless ,concact

  //using bytes32 to store uniqinfo generate "0.32.155+121.874+245.978" like key
  mapping(bytes32 => uint256) public coordinatorToTokenId;

  //for test
  mapping(address => bytes32) public addressToCodBytes32;

  //nonce
  mapping (address => uint) public nonces;

   modifier onlyMetaTx() {
        require(msg.sender == address(this));
        _;
    }

function createStarMeta(string _name, string _ra, string _dec,string _mag,string _starstory,uint256 _tokenId, address _owner) onlyMetaTx public {
         //web3.js not support return a struct inside a struct to test
    require(
      !checkIfStarExist(_ra,_dec,_mag),
      "Star already Exist!"
    );

    string memory coordinateCombine = _ra.toSlice().concat(_dec.toSlice()).toSlice().concat(_mag.toSlice());
    bytes32  bytesCoordinateCombine = stringToBytes32(coordinateCombine);

    coordinatorToTokenId[bytesCoordinateCombine] = _tokenId;
    Star memory newStar = Star(_name,_ra,_dec,_mag,_starstory);
    tokenIdToStarInfo[_tokenId] = newStar;
    addressToCodBytes32[_owner] = bytesCoordinateCombine;
    _mint(_owner, _tokenId);
}

  function createStar(string _name, string _ra, string _dec,string _mag,string _starstory,uint256 _tokenId) public {
    createStarMeta(_name,_ra,_dec,_mag,_starstory,_tokenId,msg.sender);
  }

  function execute(
        uint8 _v, bytes32 _r, bytes32 _s,
        address _from, address _to,
        uint _value, bytes _data,
        address _rewardType, uint _rewardAmount) public {

        bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _value, _data,
            _rewardType, _rewardAmount, nonces[_from]++));

        require(ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s) == _from);

        // Below is not used. Love should be free!
        // ---------------------------------------
        // if(_rewardAmount > 0) {
        //     if(_rewardType == address(0)){
        //         //pay fee with ether
        //         require(msg.sender.call.value(_rewardAmount)());
        //     } else {
        //         //pay fee with tokens
        //         require((ERC20(_rewardType)).transfer(msg.sender, _rewardAmount));
        //     }
        // }

        require(_to.call.value(_value)(_data));
}

  function checkIfStarExist(string _ra,string _dec,string _mag) view returns (bool){
     //concate star coordinator to a string
    string  memory coordinatorCombine = _ra.toSlice().concat(_dec.toSlice()).toSlice().concat(_mag.toSlice());
    bytes32 bytesCoordnatorCombin = stringToBytes32(coordinatorCombine);

    if(coordinatorToTokenId[bytesCoordnatorCombin] == 0){
      return false;
     }else{
      return true;
     }
  }

  function stringToBytes32(string source) internal returns (bytes32 result){
    assembly{
       result :=mload(add(source,32))
    }
    
  }

  function putStarUpForSale(uint256 _tokenId, uint256 _price) public {
    require(this.ownerOf(_tokenId) == msg.sender);

    /* starsForSale[_tokenId] = _price; */
    addStarForSale(_tokenId,_price);

  }

//   function checkStarUniqlessByCoordinator()

  function buyStar(uint256 _tokenId) public payable {
    require(getPriceByStarTokenID(_tokenId) > 0);

    uint256 starCost = getPriceByStarTokenID(_tokenId);
    address starOwner = this.ownerOf(_tokenId);
    require(msg.value >= starCost);

    _removeTokenFrom(starOwner, _tokenId);
    _addTokenTo(msg.sender, _tokenId);

    starOwner.transfer(starCost);

    if(msg.value > starCost) {
      msg.sender.transfer(msg.value - starCost);
      }
  }

  function mint(address to,uint256 tokenId) internal{
    _mint(to,tokenId);
  }

  function _approve(address to, uint256 tokenId) public{
    approve(to,tokenId);
  }

  function _safeTransferFrom(address from,address to,uint256 tokenId) public{
    safeTransferFrom(from,to,tokenId);
  }

  function _setApprovalForAll(address to, bool approved) public {
    setApprovalForAll(to,approved);
  }

  function _getApproved(uint256 tokenId) public view returns (address) {
    return getApproved(tokenId);
  }

  function _isApprovedForAll(
    address owner,
    address operator
  ) public view returns(bool){
      isApprovedForAll(owner,operator);
  }

  function _ownerOf(uint256 tokenId) public view returns (address) {
    return ownerOf(tokenId);
  }

// convert uint star token to string for showing the forsale stars.
  function uint2str(uint i) internal pure returns (string){
    if (i == 0) return "0";
    uint j = i;
    uint length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0){
        bstr[k--] = byte(48 + i % 10);
        i /= 10;
    }
    return string(bstr);
}

  function starsForSale() public returns (string) {
    string memory result = "";
     for(uint i = IterableMapping.iterate_start(starsForSale); IterableMapping.iterate_valid(starsForSale, i); i = IterableMapping.iterate_next(starsForSale, i)){
         (uint key, uint value) = IterableMapping.iterate_get(starsForSale, i);
         string memory starTokenId = uint2str(key);
         result = result.toSlice().concat(starTokenId.toSlice()).toSlice().concat('_'.toSlice());
     }
     return result;
  }

  function _starsForSale(uint _tokenId)  view returns (uint){
    return starsForSale.getValueByKey(_tokenId);
  }

  function _tokenIdToStarInfo(uint _tokenId) view returns (string,string,string,string,string){
    Star memory star = tokenIdToStarInfo[_tokenId];
    return (star.name,star.starStory,star.ra,star.dec,star.mag);
  }
}
