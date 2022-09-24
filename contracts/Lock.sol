// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// import {CallParams, XCallArgs} from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";
contract xNFTLaunchPadDestination {
    struct NFTDetails {
        string name;
        string symbol;
        string tokenURI;
        uint256 price;
    }

    uint256 public index;

    mapping(uint256 => NFTDetails) public nftMapping;

    function deploy(
        string memory name,
        string memory symbol,
        string memory tokenURI,
        uint256 price
    ) external {
        NFTDetails memory newEntry;
        newEntry.name = name;
        newEntry.symbol = symbol;
        newEntry.tokenURI = tokenURI;
        newEntry.price = price;

        nftMapping[++index] = newEntry;
    }
}
