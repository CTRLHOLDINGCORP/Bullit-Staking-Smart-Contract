// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ITNT721.sol";

interface ITNT721Enumerable is ITNT721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}