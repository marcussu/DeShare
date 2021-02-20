// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import * as bridgeUSDT from "./IBEP40.sol";
import "./BEP20.sol";

/**
 * @title BEP20Mintable
 * @dev Implementation of the BEP20Mintable. Extension of {BEP20} that adds a minting behaviour.
 */
abstract contract BEP20Mintable is BEP20 {

    // indicates if minting is finished
    bool private _mintingFinished = false;

    /**
     * @dev Emitted during finish minting
     */
    event MintFinished();

    /**
     * @dev Tokens can be minted only before minting finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "BEP20Mintable: minting is finished");
        _;
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev Function to mint tokens.
     *
     * WARNING: it allows everyone to mint new tokens. Access controls MUST be defined in derived contracts.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) public canMint {
        _mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * WARNING: it allows everyone to finish minting. Access controls MUST be defined in derived contracts.
     */
    function finishMinting() public canMint {
        _finishMinting();
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function _finishMinting() internal virtual {
        _mintingFinished = true;

        emit MintFinished();
    }
}

/**
 * @dev Extension of {BEP20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract BEP20Burnable is Context, BEP20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {BEP20-_burn} and {BEP20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "BEP20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

/**
 * @title FundManager
 * @dev Implementation of the FundManager
 */
contract FundManager is Ownable {

    mapping (bytes32 => uint256) private _prices;

    event Created(string serviceName, address indexed serviceAddress);

    function pay(string memory serviceName) public payable {
        require(msg.value == _prices[_toBytes32(serviceName)], "FundManager: incorrect price");

        emit Created(serviceName, _msgSender());
    }

    function getPrice(string memory serviceName) public view returns (uint256) {
        return _prices[_toBytes32(serviceName)];
    }

    function setPrice(string memory serviceName, uint256 amount) public onlyOwner {
        _prices[_toBytes32(serviceName)] = amount;
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }

    function _toBytes32(string memory serviceName) private pure returns (bytes32) {
        return keccak256(abi.encode(serviceName));
    }
}

/**
 * @title ServicePayer
 * @dev Implementation of the ServicePayer
 */
abstract contract ServicePayer {

    constructor (address payable receiver, string memory serviceName) payable {
        require(receiver != address(0), "Fee receiver cannot be zero address.");
        
        FundManager(receiver).pay{value: msg.value}(serviceName);
    }
}

/**
 * @title Fund
 * @dev Implementation of a decentralized mutual fund
 */
contract Fund is BEP20Mintable, BEP20Burnable, ServicePayer {

    using SafeMath for uint256;

    address private fund_initiator;
    enum FundType { NEW_FUND, MONEY_MARKET_FUND, FIXED_INCOME_FUND, EQUITY_FUND, BALANCED_FUND, INDEX_FUND, SPECIALTY_FUND, FUND_OF_FUNDS }
    FundType private fund_type;
    enum FundStatus { INACTIVE, EXPRESS_INTEREST, ACTIVE }
    FundStatus private fund_status;
    address private asset_base_currency;
    bool public can_invest = true;
    address payable public fee_receiver;
    address payable public fund_manager;
    
    // events for EVM logging
    event InitiatorSet(address indexed oldInitiator, address indexed newInitiator);
    event FundTypeSet(FundType indexed oldFundType, FundType indexed newFundType);
    
    // modifier to check if caller is initiator
    modifier onlyFundMgrOrOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to BNB balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(_msgSender() == fund_manager || _msgSender() == owner(), "Caller is not fund manager or owner.");
        _;
    }
    
    /**
     * @dev Create a decentralized mutual fund
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        FundType _fundType,
        address _assetBaseCurrency,
        address payable _feeReceiver,
        address payable _fundManager,
        address _fundInitiator
    )
        BEP20(_tokenName, _tokenSymbol)
        ServicePayer(_feeReceiver, "CREATE_FUND")
        payable 
    { 
        require(_fundType >= FundType.MONEY_MARKET_FUND && fund_type <= FundType.FUND_OF_FUNDS, "Fund type defined is not supported.");
        
        //_setupDecimals(_decimals);                            // Amount of decimals for display purposes; Set to the default 18 for all A-Share funds
        
        asset_base_currency = _assetBaseCurrency;                       // Can only be set once during fund setup; Immutable
        fund_status = FundStatus.ACTIVE;
        
        fund_initiator = _fundInitiator; // Track the initiator of the fund
        emit InitiatorSet(address(0), fund_initiator);
        
        fund_type = _fundType;
        emit FundTypeSet(FundType.NEW_FUND, fund_type);
        
        fee_receiver = _feeReceiver;
        fund_manager = _fundManager;
    }
    
    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {BEP20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override onlyOwner {
        super._mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {BEP20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }

    /**
     * @dev See {BEP20-_beforeTokenTransfer}. See {BEP20Capped-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        
        if (from == address(0)) { // When minting tokens
          require(can_invest, "Issue of new shares has been restricted by the fund initiator / owner.");
        }
    }
    
    /**
     * @dev Return initiator address 
     * @return address of initiator
     */
    function getFundInitiator() external view returns (address) {
        return fund_initiator;
    }
    
    /**
     * @dev Return fund type
     * @return the fund type
     */
    function getFundType() external view returns (FundType) {
        return fund_type;
    }
    
    /**
     * @dev Return fund status
     * @return the fund status
     */
    function getFundStatus() external view returns (FundStatus) {
        return fund_status;
    }
    
    /**
     * @dev Return fund's asset base currency
     * @return the fund's asset base currency
     */
    function getBaseCurrency() external view returns (address) {
        return asset_base_currency;
    }
    
    /**
     * @dev Return fund's total asset (portfolio size)
     * @return the fund's total asset (portfolio size)
     */
    function getPortfolioSize() external view returns (uint256) {
        uint256 _totalAssetValue = bridgeUSDT.IBEP40(asset_base_currency).balanceOf(address(this));
        
        return _totalAssetValue;
    }
    
    /**
     * @dev Function to issue shares once funding is received.
     *
     * NOTE: Restricting function to owner only.
     *
     * @param _sharesReceiver The address of the new fund manager
     */
    function issueShares(address _sharesReceiver, uint256 _amount) public onlyOwner {
        _mint(_sharesReceiver, _amount); // Mint the new tokens and issue to shares receiver; No normalization done to _amount, frontend to handle
    }
    
    /**
    * @dev Stop new investments
    *
    * Requirements
    *
    * - `msg.sender` must be the fund manager or owner
    */
    function stopNewInvestments() public onlyFundMgrOrOwner returns (bool) {
        can_invest = false;
        return true;
    }
    
    /**
    * @dev Resume new investments
    *
    * Requirements
    *
    * - `msg.sender` must be the fund manager or owner
    */
    function resumeNewInvestments() public onlyFundMgrOrOwner returns (bool) {
        can_invest = true;
        return true;
    }
    
    /**
     * @dev Function to change fund manager.
     *
     * NOTE: Restricting function to owner only.
     *
     * @param _newFundMgr The address of the new fund manager
     */
    function changeFundManager(address payable _newFundMgr) public onlyOwner {
        fund_manager = _newFundMgr;
    }
    
    /**
     * @dev Function for fund manager to use the fund assets
     *
     * NOTE: Restricting function to fund manager and owner only.
     *
     * @param _assetReceiver The receiver of the asset.
     * @param _assetCurrency The currency of the asset to use.
     * @param _assetCurrency The amount to be sent to receiver.
     */
    function useAsset(address payable _assetReceiver, address _assetCurrency, uint256 _amount) public onlyFundMgrOrOwner returns (bool) {
        if(_assetCurrency == asset_base_currency){
            bridgeUSDT.IBEP40(asset_base_currency).transfer(_assetReceiver, _amount);
            
            return true;
        }
        
        return false;
    }
}