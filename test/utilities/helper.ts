/* eslint-disable lines-between-class-members */
/* eslint-disable node/no-unsupported-features/es-syntax */
/* eslint-disable prettier/prettier */

const SIGNING_DOMAIN_NAME = "Fanverse"
const SIGNING_DOMAIN_VERSION = "1"  

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

  /**struct priListing{
    uint256 tokenId;
    uint256 unitprice;
    uint256 countervalue;
    uint256 amount;
    address nftOwner;
    bool listed;
    bool isEth;
    bytes signature;
    */
  async createPrimaryVoucher(nftOwner: any, tokenId: any, unitprice: any, countervalue: any, amount: any, listed: any, isEth: any){
      const voucher = {tokenId, unitprice, countervalue, amount, nftOwner, listed, isEth}
      const domain = await this._signingDomain()
      const types = {
        priListing: [
          {name: "tokenId", type: "uint256"},
          {name: "unitprice", type: "uint256"},
          {name: "countervalue", type: "uint256"},
          {name: "amount", type: "uint256"},
          {name: "nftOwner", type: "address"},
          {name: "listed", type: "bool"},
          {name: "isEth", type: "bool"}
        ]
      }
      const signature = await this.signer._signTypedData(domain, types, voucher)
      return {
        ...voucher,
        signature,
      }
  }
  /**struct marketItem {
    uint256 tokenId;
    uint256 unitPrice;
    uint256 nftBatchAmount;
    uint256 counterValue;
    address nftAddress;
    address owner;
    string tokenURI;
    bool listed;
    bool isEth;
    bytes signature;
*/
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

/**struct mintVoucher{
  uint256 tokenId;
  uint256 amount;
  uint96 royaltyFees;
  address royaltyKeeper;
  address nftAddress;
  address nftOwner;
  string tokenUri;
  bytes signature;
}
*/
  
  async createMintVoucher(nftAddress: any, nftOwner: any, tokenId: any, amount: any, tokenUri: any, royaltyKeeper: any, royaltyFees: any ){
    const voucher = {tokenId, amount, royaltyFees, royaltyKeeper, nftAddress, nftOwner, tokenUri}
    const domain = await this._signingDomain()
    const types = {
      mintVoucher: [
        {name: "tokenId", type: "uint256"},
        {name: "amount", type: "uint256"},
        {name: "royaltyFees", type: "uint96"},
        {name: "royaltyKeeper", type: "address"},
        {name: "nftAddress", type: "address"},
        {name: "nftOwner", type: "address"},
        {name: "tokenUri", type: "string"},
      ]
    }
    const signature = await this.signer._signTypedData(domain, types, voucher)
    return {
      ...voucher,
      signature,
    }
  }

  /**struct auctionItemSeller {
    uint256 royaltyFees;
    uint256 tokenId;
    uint256 nftBatchAmount;
    uint256 minimumBid;
    
    address nftAddress;
    address owner;
    address royaltyKeeper;
    string tokenURI;
    
    bool isEth;
    bytes signature;
    
}
*/
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

  /**struct auctionItemBuyer {
    uint256 tokenId;
    uint256 nftBatchAmount;
    uint256 pricePaid;
    address nftAddress;
    address buyer;
    string tokenURI;
    bytes signature;
}
*/async createVoucherAucBuyer(tokenId: any,nftBatchAmount: any,pricePaid: any,nftAddress: any,buyer: any,tokenURI: any){
    const voucher = {tokenId, nftBatchAmount, pricePaid, nftAddress, buyer, tokenURI}
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
    const signature = await this.signer._signTypedData(domain, types, voucher)
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
}

export default OrderHash;