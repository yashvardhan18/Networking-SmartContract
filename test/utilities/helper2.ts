/* eslint-disable node/no-unsupported-features/es-syntax */
/* eslint-disable prettier/prettier */

const SIGNING_DOMAIN_NAME = "Secondary" 
const SIGNING_DOMAIN_VERSION = "2"

class OrderHash{
  public contract : any; 
  public signer : any; 
  public _domain : any;
  public hashcount :number=0;

  constructor(data:any) { 
    const {_contract, _signer} =data; 
    this.contract = _contract 
    this.signer = _signer
  }

  async createSecVoucher(nftAddress: any, owner: any, tokenId: any, unitPrice: any, nftBatchAmount: any, counterValue: any, tokenURI: any, listed: any, isEth: any){
    const voucher = {tokenId, unitPrice, nftBatchAmount, counterValue,nftAddress,owner, tokenURI, listed, isEth}
    const domain = await this._signingDomain()
    const types = {
      marketItem: [
        {name: "tokenId", type: "uint256"},
        {name: "unitPrice", type: "uint256"},
        {name: "nftBatchAmount", type: "uint256"},
        {name: "counterValue", type: "uint256"},
        {name: "nftAddress", type: "address"},
        {name: "owner", type: "address"},
        {name: "tokenURI", type: "string"},
        {name: "listed", type: "bool"},
        {name: "isEth", type: "bool"},
      ]
    }
    const signature = await this.signer._signTypedData(domain, types, voucher)
    return {
      ...voucher,
      signature,
    }
}

  async createVoucherAucSeller(royaltyFees: any, tokenId: any, nftBatchAmount: any, minimumBid: any, nftAddress: any, owner: any, royaltyKeeper: any, tokenURI: any, isEth: any) {
    const voucher = {royaltyFees, tokenId, nftBatchAmount, minimumBid, nftAddress, owner, royaltyKeeper, tokenURI, isEth}
    const domain = await this._signingDomain()
    const types = {
      auctionItemSeller:[
        {name: "royaltyFees", type: "uint96"},
        {name: "tokenId", type: "uint256"},
        {name: "nftBatchAmount", type: "uint256"},
        {name: "minimumBid", type: "uint256"},
        {name: "nftAddress", type: "address"},
        {name: "owner", type: "address"},
        {name: "royaltyKeeper", type: "address"},
        {name: "tokenURI", type: "string"},
        {name: "isEth", type: "bool"},
      ]
    }



    const signature = await this.signer._signTypedData(domain, types, voucher)
    // console.log(domain);
    return {
      ...voucher,
      signature,
    }
  }

    async createSecVoucherAucSeller(nftAddress: any, owner: any,tokenId: any, nftBatchAmount: any, tokenURI: any, minimumBid: any, isEth: any) {
      const voucher = { tokenId, nftBatchAmount,minimumBid, nftAddress,owner,tokenURI,isEth}
    const domain = await this._signingDomain()
    const types = {
      auctionItemSeller:[
        
        {name: "tokenId", type: "uint256"},
        {name: "nftBatchAmount", type: "uint256"},
        {name: "minimumBid", type: "uint256"},
        {name: "nftAddress", type: "address"},
        {name: "owner", type: "address"},
        {name: "tokenURI", type: "string"},
        {name: "isEth", type: "bool"},
      ]
    }

      const signature = await this.signer._signTypedData(domain, types, voucher)
      return {
        ...voucher,
        signature,
      }
    }

  
  async createVoucherAucBuyer(nftAddress: any, buyer: any, tokenId: any, nftBatchAmount: any, tokenURI: any, pricePaid: any){
    const voucher = {tokenId, nftBatchAmount,pricePaid,nftAddress,buyer, tokenURI}
    const domain = await this._signingDomain()
    const types = {
      auctionItemBuyer: [
        {name: "tokenId", type: "uint256"},
        {name: "nftBatchAmount", type: "uint256"},
        {name: "pricePaid", type: "uint256"},
        {name: "nftAddress", type: "address"},
        {name: "buyer", type: "address"},
        {name: "tokenURI", type: "string"},
      ]
    }
      const signature = await this.signer._signTypedData(domain, types, voucher);
      return {
        ...voucher,
        signature,
      }
  }

  async _signingDomain() {
    if (this._domain != null) {
      return this._domain
    }
    const chainId = await this.contract.getChainID()
    this._domain  = {
      name: SIGNING_DOMAIN_NAME,
      version: SIGNING_DOMAIN_VERSION,
      verifyingContract: this.contract.address,
      chainId,
    }
    return this._domain
  }

  async secAuctionItemSeller(
    nftAddress: any,
    owner: any,
    tokenId: any,
    nftBatchAmount: any,
    tokenURI: any,
    minimumBid: any,
    isEth: any,
  ) {
    const voucher = {minimumBid,tokenId,nftBatchAmount,nftAddress,owner,tokenURI,isEth};

   /** struct secAuctionItemSeller {
      uint256 minimumBid;
        uint256 tokenId;
        uint256 nftBatchAmount;
        address nftAddress; 
        address owner;
        string tokenURI;
        bool isEth;
        
  }
  */

    const domain = await this._signingDomain()
    const types = {
      secAuctionItemSeller: [
        {name: "minimumBid", type: "uint256"},
        {name: "tokenId", type: "uint256"},
        {name: "nftBatchAmount", type: "uint256"},
        {name: "nftAddress", type: "address"},
        {name: "owner", type: "address"},
        {name: "tokenURI", type: "string"},
        {name: "isEth", type: "bool"},
      ],
    }

    const signature = await this.signer._signTypedData(domain, types, voucher);
    return {
      ...voucher,
      signature,
    }
  }
}

export default OrderHash;