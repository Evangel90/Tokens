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
    uint public id;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// @notice Standard Base64 Encoding Logic
    /// @dev Implementation of the Base64 encoding algorithm from scratch
    function encode(bytes memory data) public pure returns (string memory) {
        if (data.length == 0) return "";
        
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 encodedLength = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLength);

        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 input = uint256(uint8(data[i])) << 16;
            if (i + 1 < data.length) input |= uint256(uint8(data[i + 1])) << 8;
            if (i + 2 < data.length) input |= uint256(uint8(data[i + 2]));

            result[(i / 3) * 4] = bytes(table)[(input >> 18) & 0x3F];
            result[(i / 3) * 4 + 1] = bytes(table)[(input >> 12) & 0x3F];
            result[(i / 3) * 4 + 2] = (i + 1 < data.length) ? bytes(table)[(input >> 6) & 0x3F] : bytes1("=");
            result[(i / 3) * 4 + 3] = (i + 2 < data.length) ? bytes(table)[input & 0x3F] : bytes1("=");
        }
        return string(result);
    }

    /// @notice Generates the SVG image string
    function buildImage(uint256 tokenId) public pure returns (string memory) {
        // A simple SVG: A square with the Token ID text
        return string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='300' height='300'>",
            "<rect width='100%' height='100%' fill='#2c3e50'/>",
            "<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' fill='white' font-size='40'>NFT #",
            uint2str(tokenId),
            "</text></svg>"
        ));
    }

    // Helper: Convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function mint(address _to) public  {
        id += 1;
        require(_to != address(0), "Invalid recipient");
        require(tokenOwners[id] == address(0), "Token already exists");

        tokenOwners[id] = _to;
        balances[_to] += 1;
        tokenURIs[id] = tokenURI(id);

        emit Transfer(address(0), _to, id);
    }

    /// @notice The ERC-721 tokenURI function
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId > 0, "Invalid token ID");
        require(tokenOwners[tokenId] != address(0), "Token does not exist");

        string memory imageSvg = buildImage(tokenId);
        
        // Encode image to base64
        string memory imageBase64 = encode(bytes(imageSvg));
        
        // Construct JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name": "On-Chain Token #', uint2str(tokenId), 
            '", "description": "Truly on-chain SVG", "image": "data:image/svg+xml;base64,', 
            imageBase64, '"}'
        ));

        // Return Data URI
        return string(abi.encodePacked("data:application/json;base64,", encode(bytes(json))));
    }

    // function tokenURI(uint256 _tokenId) public view returns (string memory){
    //     require(_tokenId > 0, "Invalid token ID");
    //     require(tokenOwners[_tokenId] != address(0), "Token does not exist");
    //     return tokenURIs[_tokenId];
    // }

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
