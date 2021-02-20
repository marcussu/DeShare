// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./Fund.sol";

contract FundPlatform is BEP20Mintable, BEP20Burnable {
    using SafeMath for uint256;
    
    mapping(bytes32 => Fund) funds; // Tracks all the funds created on the platform; Maps fund symbol to Fund instance
    mapping(address => FundManager) fundMgrs; // Tracks all the fund managers of each fund; Maps Fund contract address to FundManager instance
    address[] private fundListing;
    address payable platformFeeReceiver;
    address public asset_base_currency;
    
    /**
     * @dev Setup the mutual fund platform
     */
    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _assetBaseCurrency,
        address payable _feeReceiver
    )
        BEP20(_tokenName, _tokenSymbol)
        payable 
    { 
        //_setupDecimals(_decimals);                            // Amount of decimals for display purposes; Set to the default 18
        
        _mint(_msgSender(), _initialAmount);                    // Mint the new platform tokens and issue to platform contract deployer; No normalization done
        
        asset_base_currency = _assetBaseCurrency;                       // Can only be set once during setup; Immutable
        platformFeeReceiver = _feeReceiver;                             // Can only be set once during setup; Immutable
    }
    
    /**
     * @dev Initiate the creation of a decentralized mutual fund and track the fund listings
     */
    function createFund(
        uint256 _initialAmount, 
        string memory _tokenName, 
        string memory _tokenSymbol, 
        Fund.FundType _fundType, 
        address _assetBaseCurrency, 
        uint256 _seedFunding, 
        address payable _fundManager
    ) public payable returns (Fund) {
        require(funds[_toBytes32(_tokenSymbol)] == Fund(0), "Fund symbol is in use, kindly use a unique fund symbol."); // Check if the fund symbol is already in use
        require(_initialAmount > 0, "Initial number of share supply cannot be zero.");
        
        // Caller of this function is likely the fund initiator; This fund platform contract will be the "owner" of the fund contract
        Fund _fundInstance = new Fund{value: msg.value}(_tokenName, _tokenSymbol, _fundType, _assetBaseCurrency, platformFeeReceiver, _fundManager, _msgSender());
        
        address payable _fundAddress = payable(address(_fundInstance));
        
        fundListing.push(_fundAddress);
       
        bridgeUSDT.IBEP40(_assetBaseCurrency).transferFrom(_msgSender(), _fundAddress, _seedFunding);
        
        _fundInstance.issueShares(_msgSender(), _initialAmount);
        
        funds[_toBytes32(_tokenSymbol)] = _fundInstance; // Use helper function to convert the string to bytes32 mapping key
        fundMgrs[_fundAddress] = FundManager(_fundManager); // Explicitly type convert the _fundManager address into FundManager instance
        
        return _fundInstance;
    }
    
    /**
     * @dev Retrieve a single fund using its symbol
     */
    function getAllFunds() public view returns (address[] memory) {
        return fundListing;
    }
    
    /**
     * @dev Retrieve a single fund using its symbol
     */
    function getFund(string memory _fundSymbol) public view returns (address payable) {
        return payable(address(funds[_toBytes32(_fundSymbol)]));
    }
    
    /**
     * @dev Helper function to convert string to bytes32
     */
    function _toBytes32(string memory _origString) private pure returns (bytes32) {
        return keccak256(abi.encode(_origString));
    }
    
    /**
     * @dev Enable platform fee withdrawals
     */
    function withdraw(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }
    
    /**
     * @dev Invest in a fund using its symbol
     */
    function investFund(string memory _fundSymbol, address _assetCurrency, uint256 _investAmount) public payable returns (bool) {
        require(_assetCurrency == 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd || _assetCurrency == 0x55d398326f99059fF775485246999027B3197955, "Currency is not set as Binance wrapped USDT.");
        
        address payable _investingFund = getFund(_fundSymbol);
        
        require(_investingFund != address(0), "Investing fund cannot be zero address.");
        
        bridgeUSDT.IBEP40(_assetCurrency).transferFrom(_msgSender(), _investingFund, _investAmount);
        
        Fund _investingFundInstance = Fund(_investingFund);
        require(_investAmount.mul( _investingFundInstance.totalSupply() ) >= _investingFundInstance.getPortfolioSize(), "Invest amount is lower than NAV.");
        
        Fund(_investingFund).issueShares(_msgSender(), _investAmount.mul( _investingFundInstance.totalSupply() ).div( _investingFundInstance.getPortfolioSize() ));
        
        return true;
    }
    
    /**
     * @dev Function to change fund manager.
     *
     * NOTE: Restricting function to owner only.
     *
     * @param _newFundMgr The address of the new fund manager
     */
    function changeFundManager(string memory _fundSymbol, address payable _newFundMgr) public onlyOwner {
        funds[_toBytes32(_fundSymbol)].changeFundManager(_newFundMgr);
    }
    
    /**
     * @dev Function to transfer a mutual fund ownership. May be used for platform upgrade/migration
     *
     * NOTE: Restricting function to platform owner only.
     *
     * @param _newFundOwner The address of the new fund owner
     */
    function transferMutualFund(string memory _fundSymbol, address _newFundOwner) public onlyOwner {
        funds[_toBytes32(_fundSymbol)].transferOwnership(_newFundOwner);
    }
    
    /**
     * @dev Function to import a mutual fund. May be used for platform upgrade/migration
     *
     * NOTE: Restricting function to platform owner only.
     *
     * @param _importedFundAddr The address of the imported mutual fund
     */
    function importMutualFund(address payable _importedFundAddr) public onlyOwner {
        Fund _importedFund = Fund(_importedFundAddr);
        
        require(_importedFund.getOwner() == address(this), "Ownership of fund needs to be transferred here before import.");
        require(funds[_toBytes32(_importedFund.symbol())] == Fund(0), "Fund symbol is in use, kindly use a unique fund symbol."); // Check if the fund symbol is already in use
        
        funds[_toBytes32(_importedFund.symbol())] = _importedFund;
        
        fundListing.push(_importedFundAddr);
        
        fundMgrs[_importedFundAddr] = FundManager(_importedFund.fund_manager());
    }
}