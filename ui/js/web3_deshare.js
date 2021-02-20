//initialize web3 and connect metamask
var web3, account, fundPlatform, newFund, USDT; 
$('#loader').hide();

window.addEventListener('load', function() {
  if (typeof window.ethereum !== 'undefined') {
    window.web3 = new Web3(window.ethereum);
    window.ethereum.request({ method: 'eth_requestAccounts' });
	getSelectedAccount();
	
    fundPlatform = new web3.eth.Contract(fundPlatformABI, fundPlatformAddr);
    populateFundDetails(fundPlatform);
  }
  else {
    console.log('Error: web3 provider not found. Make sure Metamask or the wallet is configured properly. Otherwise, download and install Metamask: https://metamask.io/');
    $('#result').html('<div class="alert alert-danger alert-dismissible fade show" role="alert"><p>Error: Make sure your Metamask configured correctly. You may download and install Metamask here: <a href="https://metamask.io/">https://metamask.io/</a></p></div>');
  }
});

async function getSelectedAccount(){
	// "currently selected" address is the first item in the array returned by eth_accounts
    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
	account = accounts[0];
    console.log("connected with: "+account);
}

//write to BSC and do something with event
function preApproveTransfer(){
  var _assetBaseCurrency = getCurrencyAddress($('#baseCurrencyInput').val(), true);
  var _seedFunding = web3.utils.toWei($('#investmentInput').val(), "ether"); // Normalize for 18 decimal places
  
  // Obtain approval for fund platform to transfer USDT
  USDT = new web3.eth.Contract(wrappedUsdtABI, getCurrencyAddress("USDT"));
  
  USDT.methods.approve(fundPlatformAddr, _seedFunding)
  .send({ from: account })
  .on('transactionHash', function (txHash) {
    console.log("Approval sent. Please check the amount and confirm the pre-approval.");
    $('#preApproveBtn').hide();
    $('#loader').show();
	$('#result').html('<div class="alert alert-primary alert-dismissible fade show" role="alert"><p>Pre-approval txn sent and pending confirmation. Check your transaction status <a href="'+bscScanURL+'/tx/'+txHash+'">here</a></p></div>');
    console.log(txHash);
  })
  .once('confirmation', function(confNumber, receipt){ 
    console.log(receipt.status);
    if(receipt.status == true){
	  $('#loader').hide();
      $('#preApproveBtn').show();
      $('#result').html('<div class="alert alert-success alert-dismissible fade show" role="alert"><p>Pre-approval to platform smart contract successfully granted. Check your transaction status <a href="'+bscScanURL+'/tx/'+receipt.status+'">here</a></p></div>');
	  console.log("Pre-approval successful: "+receipt.status);
    }
    else{
      console.log("there was an error");
    } 
  }).once('error', function(error){console.log(error);});
}

function createFund(){
  //validate form before submission of contract
  var form = $('#launchFundForm')[0];
  
  if (form.checkValidity()) {
    form.classList.add('was-validated');
  }
  
  var _initialAmountInput = web3.utils.toWei($('#initialAmountInput').val(), "ether"); // Normalize for 18 decimal places
  var _fundNameInput = $('#fundNameInput').val();
  var _fundSymbolInput = "A" + $('#fundSymbolInput').val();
  var _fundTypeInput = $('#fundTypeInput').val();
  var _assetBaseCurrency = getCurrencyAddress($('#baseCurrencyInput').val(), true);
  var _seedFunding = web3.utils.toWei($('#investmentInput').val(), "ether"); // Normalize for 18 decimal places
  
  // Assumes pre-approval for fund platform to transfer USDT granted; otherwise will fail
  // Proceed to create the fund and transfers th USDT to the fund
  fundPlatform.methods.createFund(_initialAmountInput, _fundNameInput, _fundSymbolInput, _fundTypeInput, _assetBaseCurrency, _seedFunding, fundMgr)
  .send({ from: account, gas: 3000000, gasPrice: 20*1000000000 , to: fundPlatformAddr, value: 1*100000000000000000})

  .on('transactionHash', function (txHash) {
    console.log("Txn sent. Please wait for confirmation.");
    $('#createFundBtn').hide();
    $('#loader').show();
	$('#result').html('<div class="alert alert-primary alert-dismissible fade show" role="alert"><p>Txn sent and pending confirmation. Check your transaction status <a href="'+bscScanURL+'/tx/'+txHash+'">here</a></p></div>');
    console.log(txHash);
  })
  .once('confirmation', function(confNumber, receipt){ 
    console.log(receipt.status);
    if(receipt.status == true){

      $('#loader').hide();
      $('#createFundBtn').show();
      $('#result').html('<div class="alert alert-success alert-dismissible fade show" role="alert"><p>Mutual fund successfully created. Check your transaction status <a href="'+bscScanURL+'/tx/'+receipt.status+'">here</a></p></div>');
	  populateFundDetails(receipt.status);
	  console.log("Txn successful: "+receipt.status);
    }
    else{
      console.log("there was an error");
    } 
  }).once('error', function(error){console.log(error);});
}

//read
function populateFundDetails(_fundPlatform){
  _fundPlatform.methods.getAllFunds()
  .call({from: account},
    async function(error, result) {
      if (!error){
        console.log(result);
		
		for(let i = 0; i < result.length; i++){
			var _fund = new web3.eth.Contract(fundABI, result[i]);
  
			$("#fundListing").append("<tr id='"+result[i]+"'><th scope='row' class='className'></th><td class='classSymbol'></td><td class='classPortfolioSize'></td><td class='classTotalSupply'></td><td class='classFundType'></td><td><a href='https://testnet.bscscan.com/address/"+result[i]+"'>Details</a></td></tr>");
			  
			populateFundName(_fund, result[i]);
			populateFundSymbol(_fund, result[i]);
			populatePortfolioSize(_fund, result[i])
			populateFundTotalSupply(_fund, result[i]);
			populateFundType(_fund, result[i]);
		}
      }
      else
      console.error(error);
    }
  );
}

function populateFundName(_fund, _contractAddress){
  _fund.methods.name()
  .call({from: account},
    async function(error, result) {
      if (!error){
        //console.log(result);
		$("#" + _contractAddress).children(".className").html(result);
      }
      else
      console.error(error);
    }
  );
}

function populateFundSymbol(_fund, _contractAddress){
  _fund.methods.symbol()
  .call({from: account},
    async function(error, result) {
      if (!error){
        //console.log(result);
		$("#" + _contractAddress).children(".classSymbol").html(result);
      }
      else
      console.error(error);
    }
  );
}

function populatePortfolioSize(_fund, _contractAddress){
  _fund.methods.getPortfolioSize()
  .call({from: account},
    async function(error, result) {
      if (!error){
        //console.log(result);
        $("#" + _contractAddress).children(".classPortfolioSize").html(web3.utils.fromWei(result, "ether") + " USDT");
      }
      else
      console.error(error);
    }
  );
}

function populateFundType(_fund, _contractAddress){
  _fund.methods.getFundType()
  .call({from: account},
    async function(error, result) {
      if (!error){
        //console.log(result);
        $("#" + _contractAddress).children(".classFundType").html(result);
      }
      else
      console.error(error);
    }
  );
}

function populateFundTotalSupply(_fund, _contractAddress){
  _fund.methods.totalSupply()
  .call({from: account},
    async function(error, result) {
      if (!error){
        //console.log(result);
        $("#" + _contractAddress).children(".classTotalSupply").html(web3.utils.fromWei(result, "ether"));
      }
      else
      console.error(error);
    }
  );
}

// Helper function
function getCurrencyAddress(_currencyString){
	switch (_currencyString) {
	  case 'USDT':
		return wrappedUSDT;
	  case 'BUSD':
		return wrappedBUSD;
	  default:
		return "0";
	}
}