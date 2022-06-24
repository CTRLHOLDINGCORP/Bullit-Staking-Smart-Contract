// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ITNT721.sol";

interface ITNT721Metadata is ITNT721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}