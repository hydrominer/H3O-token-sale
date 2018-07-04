pragma solidity 0.4.24;

import "./usingOraclize.sol";


/**
 * Contract which exposes `ethInCents` which is the Ether price in USD cents.
 * E.g. if 1 Ether is sold at 840.32 USD on the markets, the `ethInCents` will
 * be `84032`.
 *
 * This price is supplied by Oraclize callback, which sets the value. Currently
 * there is no proof provided for the callback, other then the value and the
 * corresponding ID which was generated when this contract called Oraclize.
 *
 * If this contract runs out of Ether, the callback cycle will interrupt until
 * the `update` function is called with a transaction which also replenishes the
 * balance of the contract.
 */
contract ETHUSD is usingOraclize {

   /** ######################################################################
    *
    *  S T O R A G E
    *
    * ######################################################################
    */

    uint256 public ethInCents;
    
    uint256 public lastOraclizeCallback;

    // Calls to oraclize generate a unique ID and the subsequent callback uses
    // that ID. We allow callbacks only if they have a valid ID.
    mapping(bytes32 => bool) private validIds;

    // Allow only single auto update cycle, to prevent DOS attack.
    bytes32 private autoUpdateId;

    /** ######################################################################
     *
     *  E V E N T S
     *
     * ######################################################################
     */

    event LogOraclizeQuery(string description);
    event LogPriceUpdated(string price);


    /** ######################################################################
     *
     *  F U N C T I O N S
     *
     * ######################################################################
     */

    // NB: ethInCents is not initialised until the first Oraclize callback comes
    // in.
    constructor() public {
        lastOraclizeCallback = 0;

        // For local Ethereum network, we need to supply our own OAR contract
        // address.
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);

        update();
    }

    function update() public payable {
        require(hasEnoughFunds());
        require(autoUpdateId == bytes32(0));

        emit LogOraclizeQuery("Requesting Oraclize to submit latest ETHUSD price");

        bytes32 qId = oraclize_query(60, "URL", "json(https://api.infura.io/v1/ticker/ethusd).ask");
        validIds[qId] = true;
        autoUpdateId = qId;
    }

    function instantUpdate() public payable {
        require(hasEnoughFundsInThisCall());

        emit LogOraclizeQuery("Requesting Oraclize to submit latest ETHUSD price instantly");

        bytes32 qId = oraclize_query("URL", "json(https://api.infura.io/v1/ticker/ethusd).ask");
        validIds[qId] = true;
    }

    function __callback(bytes32 cbId, string result) public {
        require(msg.sender == oraclize_cbAddress());
        require(validIds[cbId]);

        ethInCents = parseInt(result, 2);
        delete validIds[cbId];

        lastOraclizeCallback = block.number;

        emit LogPriceUpdated(result);

        if (cbId == autoUpdateId) {
            autoUpdateId = bytes32(0);
        } else {
            // Don't auto update if it was instant update.
            return;
        }
        if (!hasEnoughFunds()) {
            // Exit to not revert received price.
            return;
        }
        update();
    }

    function hasEnoughFunds() internal returns (bool) {
        return oraclize_getPrice("URL") <= address(this).balance;
    }

    function hasEnoughFundsInThisCall() internal returns (bool) {
        return oraclize_getPrice("URL") <= msg.value;
    }
}