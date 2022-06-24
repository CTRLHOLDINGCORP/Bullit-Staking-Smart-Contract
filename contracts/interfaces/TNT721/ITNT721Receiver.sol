// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ITNT721.sol";

interface ITNT721Receiver {
    function onTNT721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}