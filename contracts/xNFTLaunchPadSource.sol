// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IConnextHandler} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnextHandler.sol";
import {CallParams, XCallArgs} from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IxNFTLaunchPadDestination {
      function deploy(
        string memory name,
        string memory symbol,
        string memory tokenURI,
        uint price,
        address owner
    ) external ;
}

contract xNFTLaunchPadSource {
    // mapping to store chain id and corresponding address;
    struct connextContractDetails {
        //connext contract address
        address connextContractAddress;
        //domain
        uint32 domain;
        //deployer address
        address deployerAddress;
    }
    mapping(uint256 => connextContractDetails) public mapChainIdToContract;
    address public owner;
    IConnextHandler public connext;

    constructor(IConnextHandler _connext) {
        owner = msg.sender;
        connext = _connext;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addConextAddress(
        uint256 _chainId,
        address _contractAddress,
        uint32 _domain,
        address _deployerAddress
    ) external onlyOwner {
        connextContractDetails memory newEntry;
        newEntry.connextContractAddress = _contractAddress;
        newEntry.domain = _domain;
        newEntry.deployerAddress = _deployerAddress;
        mapChainIdToContract[_chainId] = newEntry;
    }

    // function _verifyChainIds(uint8[] memory _chainIds) internal returns (bool) {
    //     bool _isValid = true;
    //     for (uint256 i = 0; i < _chainIds.length(); i++) {
    //         if (mapChainIdToContract[_chainIds[i]] == 0) _isValid = false;
    //     }

    //     return _isValid;
    // }

    function launchNFT(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _salePrice,
        uint256[] memory _chainIds
    ) public {
        //TODO: Remove it after testing with one chainid
        // require(_verifyChainIds(_chainIds), "Invalid Chain Id");
        bytes4 selector = bytes4(
            keccak256("deploy(string,string,string,uint)")
        );
        bytes memory callData = abi.encodeWithSelector(
            selector,
            _name,
            _symbol,
            _tokenURI,
            _salePrice,
            msg.sender
        );

        for (uint8 i = 0; i < _chainIds.length; i++) {
            //get domain and deployer address
            connextContractDetails memory details = mapChainIdToContract[
                _chainIds[i]
            ];
            if (_chainIds[i] == 5) {
                IxNFTLaunchPadDestination(details.deployerAddress).deploy(
                    _name,
                    _symbol,
                    _tokenURI,
                    _salePrice,
                    msg.sender
                );
            } else {
                //define params as per connext
                CallParams memory callParams = CallParams({
                    to: details.deployerAddress,
                    callData: callData,
                    originDomain: 1735353714, //originDomain -> polygon Mumbai,
                    destinationDomain: details.domain, // gorlie
                    agent: msg.sender, // address allowed to execute transaction on destination side in addition to relayers
                    recovery: msg.sender, // fallback address to send funds to if execution fails on destination side
                    forceSlow: false, // option to force slow path instead of paying 0.05% fee on fast liquidity transfers
                    receiveLocal: false, // option to receive the local bridge-flavored asset instead of the adopted asset
                    callback: address(0), // zero address because we don't expect a callback
                    callbackFee: 0, // fee paid to relayers for the callback; no fees on testnet
                    relayerFee: 0, // fee paid to relayers for the forward call; no fees on testnet
                    destinationMinOut: 0 // not sending funds so minimum can be 0
                });
                // wrap it in xcall format
                XCallArgs memory xcallArgs = XCallArgs({
                    params: callParams,
                    transactingAsset: address(0), // 0 address is the native gas token
                    transactingAmount: 0, // not sending funds with this calldata-only xcall
                    originMinOut: 0 // not sending funds so minimum can be 0
                });
                // call the deployer contracts
                IConnextHandler(connext).xcall(xcallArgs);
            }
        }
    }
}
