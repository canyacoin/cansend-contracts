pragma solidity ^0.4.19;

import "./ERC20.sol";


contract CanSend {

    address public owner;
    address public feeTokenAddress;
    uint256 public MAX_RECIPIENTS = 255;
    uint256 public feeTokensToCollect = 0;
    uint256 public totalFeesCollected = 0;
    uint256 public feeTokenDecimals = 0;
    uint256 public wholeTokensPerTenRecipients = 1;
    ERC20 public feeToken;

    event TokensSent (address indexed _token, uint256 _total, uint256 _feesToCollect);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /// @dev Changes the owner of the contract
    /// @param _newOwner Address of the new owner
    function transferOwnerShip(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    /// @dev Constructor, sets the owner and the address of the feeToken
    /// @param _feeTokenAddress Address of the fee token
    /// @param _feeTokenDecimals Number of decimal places in the feeToken
    function CanSend(address _feeTokenAddress, uint256 _feeTokenDecimals) public {
        owner = msg.sender;
        feeTokenAddress = _feeTokenAddress;
        feeToken = ERC20(_feeTokenAddress);
        feeTokenDecimals = _feeTokenDecimals;
    }

    /// @dev Sends varying amounts of a specific token to multiple addresses
    /// @param _token Address of the token to send
    /// @param _recipients Array of recipient addresses
    /// @param _amounts Array of the amounts that recipients should receive
    function multiSend (address _token, address[] _recipients, uint256[] _amounts) public {
        require(_token != address(0));
        require(_recipients.length != 0);
        require(_recipients.length <= MAX_RECIPIENTS);
        require(_recipients.length == _amounts.length);
        ERC20 tokenToSend = ERC20(_token);
        
        uint256 totalAirDropped = 0;
        uint256 feeTokensRequired = (
            (_recipients.length / 10) *
            (wholeTokensPerTenRecipients * (10 ** feeTokenDecimals))
        );
        
        // Collect 1 token per 10 recipients
        require(feeToken.transferFrom(msg.sender, address(this), feeTokensRequired));
        feeTokensToCollect += feeTokensRequired;
        totalFeesCollected += feeTokensRequired;

        // Air drop tokens to multiple addresses
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(tokenToSend.transferFrom(msg.sender, _recipients[i], _amounts[i])); 
            totalAirDropped += _amounts[i];
        }
        
        TokensSent(_token, totalAirDropped, feeTokensToCollect);
    }

    /// @dev Allows the owner to claim the fees collected by the contract
    /// @param _destination The address to which the fees should be transferred
    function claimTokens(address _destination) public onlyOwner {
        uint256 totalTokensToTransfer = feeToken.balanceOf(address(this));
        require(feeToken.transfer(_destination, totalTokensToTransfer));
        feeTokensToCollect = 0;
    }

    /// @dev Changes the maximum number of recipients for the multisender, useful
    /// in the future if the gas limit is changed
    /// @param _newMaxRecipients New number of maximum recipients
    function changeRecipientsNo(uint256 _newMaxRecipients) public onlyOwner {
        MAX_RECIPIENTS = _newMaxRecipients; 
    }

    /// @dev Changes the fee amount per ten recipients in whole tokens
    /// @param _newWholeTokensPerTenRecipients Number of whole tokens to charge per ten recipients
    function changeFeeAmount(uint256 _newWholeTokensPerTenRecipients) public onlyOwner {
        wholeTokensPerTenRecipients = _newWholeTokensPerTenRecipients;
    }

}