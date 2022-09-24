// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import {LibCrossDomainProperty} from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibCrossDomainProperty.sol";
import {IConnextHandler} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnextHandler.sol";
// import {CallParams, XCallArgs} from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";
contract xNFTLaunchPadDestination {
  struct NFTDetails {
    string name;
    string symbol;
    string tokenURI;
    uint price;
  }
  // Variables to store data of authorized call
  address public originContract; // the address of the source contract
  uint32 public originDomain; // the origin Domain ID
  address public executor; // the address of the Connext Executor contract
  address public connextAddress;

  uint public index;

  constructor(address _originContract, uint32 _originDomain, address _connext) {
    originContract = _originContract;
    originDomain = _originDomain;
    connextAddress = _connext;
    executor = address(IConnextHandler(connextAddress).executor());
  }

    // A modifier for authenticated functions.
  // Note: This is an important security consideration. If the target function
  //       is authenticated, it must check that the originating call is from
  //       the correct domain and contract. Also, the msg.sender must be the 
  //       Connext Executor address.
  modifier onlySource() {
    require(
      LibCrossDomainProperty.originSender(msg.data) == originContract &&
        LibCrossDomainProperty.origin(msg.data) == originDomain &&
        msg.sender == address(executor),
      "Expected origin contract on origin domain called by Executor"
    );
    _;
  }

  mapping (uint => NFTDetails) public  nftMapping;
  function deploy(string memory name, string memory symbol, string memory tokenURI, uint price) external onlySource {
    NFTDetails memory newEntry ;
    newEntry.name = name;
    newEntry.symbol = symbol;
    newEntry.tokenURI = tokenURI;
    newEntry.price = price;

    nftMapping[++index] = newEntry;

  }
}