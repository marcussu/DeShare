# DeShare
DeShare: Decentralized Mutual Fund Platform

Platform based on Binance Smart Chain to enable decentralized mutual funds to be launched that are more transparent and cost-effective than traditional mutual funds. The platform will also form a "family of mutual funds" to enable participants more flexibility to switch between funds.

Official site - https://fund.type.sg
Demo videos - https://www.youtube.com/playlist?list=PLm6WgPLnPE1jAS2BczC9n8dCXN7z0R9A3
DeShare platform smart contract address - https://testnet.bscscan.com/address/0xa70218f213ccde531b114f079554d181f18e7722

## Advantages of Mutual Funds
* Allows diversification of portfolio.
* Provides liquidity and ease of access.
* Leverages on economies of scale with minimal investment requirements.
* Delegates portfolio management.
* Variety of offerings catering to different needs.

## Limitations of Traditional Mutual Funds
* High fees, commissions, and other expenses. Often, there is also a lack of transparency in the breakdown of the fund expenses.
* Lack of transparency in holdings.
* Difficulty in comparing funds.
* Large cash presence in portfolios (cash drag) to maintain capacity to accommodate withdrawals.
* Other limitations such as over-complicated investment / portfolio strategy, dilution, etc.

## Objectives of DeShare
* Fast and cost-effective launch of decentralized mutual funds.
* More transparent fee structure, investment strategy (all transactions visible on Binance Smart Chain), and investment holdings.
* New opportunities through integration with other DeFi projects / developments.

## Phase 1 Support

### Mutual Fund Types
DeShare has structured the fund types into 7 common types of mutual funds so as to cater to the fund participants' different risk appetites and investment strategy preferences.

Fund Type | Traditional Mutual Fund
--------- | -----------------------
**Money Market Fund** | These funds invest in short-term fixed income securities such as government bonds, treasury bills, bankers’ acceptances, commercial paper and certificates of deposit. They are generally a safer investment, but with a lower potential return then other types of mutual funds.
**Fixed Income Fund** | These funds buy investments that pay a fixed rate of return like government bonds, investment-grade corporate bonds and high-yield corporate bonds. They aim to have money coming into the fund on a regular basis, mostly through interest that the fund earns. High-yield corporate bond funds are generally riskier than funds that hold government and investment-grade bonds.
**Equity Fund** | These funds invest in stocks. These funds aim to grow faster than money market or fixed income funds, so there is usually a higher risk that you could lose money. You can choose from different types of equity funds including those that specialize in growth stocks (which don’t usually pay dividends), income funds (which hold stocks that pay large dividends), value stocks, large-cap stocks, mid-cap stocks, small-cap stocks, or combinations of these.
**Balanced Fund** | These funds invest in a mix of equities and fixed income securities. They try to balance the aim of achieving higher returns against the risk of losing money. Most of these funds follow a formula to split money among the different types of investments. They tend to have more risk than fixed income funds, but less risk than pure equity funds. Aggressive funds hold more equities and fewer bonds, while conservative funds hold fewer equities relative to bonds.
**Index Fund** | These funds aim to track the performance of a specific index such as the S&P/TSX Composite Index. The value of the mutual fund will go up or down as the index goes up or down.
**Specialty Fund** | These funds focus on specialized mandates such as real estate, commodities or socially responsible investing.
**Fund-of-Funds** | These funds invest in other funds. Similar to balanced funds, they try to make asset allocation and diversification easier for the investor. The MER for fund-of-funds tend to be higher than stand-alone mutual funds.

### Mutual Fund Base Currency
DeShare decided to adopt Binance wrapped USDT as the initial supported base currency and aims to support other stablecoins in future phases.

# Development Documentation
## Environment Setup
* Programming languages: Solidity (v0.7.4), Javascript, HTML/CSS
* Remix IDE - https://remix.ethereum.org/#optimize=true&runs=200&evmVersion=null&version=soljson-v0.7.4+commit.3f05b770.js&appVersion=0.8.0
* MetaMask - https://metamask.io/
* Frontend - Bootstrap v5.0.0

## Design Considerations
* Current version of DeShare platform is deployed on Binance Smart Chain (BSC) testnet due to rising BNB costs in mainnet.
* DeShare platform live on BSC testnet is a working smart contract that can create a mutual fund as BEP20 tokens directly from web form (no coding required by fund initiator).
* Smart contract is structured as a main DeShare platform (deployed as BEP20 Token for future use cases), which tracks and owns the created mutual funds' smart contract.
* Each mutual fund will also have its own FundManager smart contract / address that can execute commands on the fund (e.g. invest the fund assets).
* A fixed fee of 0.1 BNB is charged for starting a mutual fund, but this value is managed by a separate platform fee receiver smart contract and value is configurable without having to redeploy the platform.

## To Do
* Smart contract for the mutual fund has interface for additional investments, but user interface is currently not handled in the front-end portal.
