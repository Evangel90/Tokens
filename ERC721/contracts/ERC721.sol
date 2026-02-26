// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @dev Interface for the NFT receiver to prevent locked tokens
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract ERC721 {
    mapping (address => uint256) private balances;
    mapping (uint256 => address) private tokenOwners;
    mapping (uint256 => address) private approvedAddress;
    mapping (address => mapping(address => bool)) private approvedForAll;
    mapping (uint256 => string) private tokenURIs;

    string public name;
    string public symbol;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0), "Invalid owner");
        return balances[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view returns (address){
        require(_tokenId > 0, "Invalid token ID");
        return tokenOwners[_tokenId];
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(tokenOwners[_tokenId] == _from, "Not the owner");
        require(tokenOwners[_tokenId] != _to, "Invalid recipient");
        require(_tokenId > 0 && _tokenId <= balances[_from], "Invalid token ID");
        require(_to != address(0), "Invalid recipient");

        delete approvedAddress[_tokenId];

        balances[_from] -= 1;
        tokenOwners[_tokenId] = _to;
        balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool){
        if(to.code.length > 0){
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
        return true;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable{
        _transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, data), "onERC721Received failed");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        _transferFrom(_from, _to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
        require(tokenOwners[_tokenId] == msg.sender, "Not the owner");
        _transferFrom(_from, _to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external payable{
        require(tokenOwners[_tokenId] == msg.sender, "Not the owner");
        approvedAddress[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        approvedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

  
    function getApproved(uint256 _tokenId) external view returns (address){
        require(_tokenId > 0, "Invalid token ID");
        return approvedAddress[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return approvedForAll[_owner][_operator];
    }  
}
