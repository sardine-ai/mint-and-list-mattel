import FungibleToken from "FungibleToken"
import NonFungibleToken from "NonFungibleToken"
import ExampleNFT from "ExampleNFT"
import FlowToken from "FlowToken"
import MetadataViews from "MetadataViews"
import NFTStorefrontV2 from "NFTStorefrontV2"

transaction {
  let minter: &ExampleNFT.NFTMinter
  let recipientCollectionRef: &{NonFungibleToken.Receiver}
  let tokenReceiver: Capability<&{FungibleToken.Receiver}>
  let storefront: auth(NFTStorefrontV2.CreateListing) &NFTStorefrontV2.Storefront
  var saleCuts: [NFTStorefrontV2.SaleCut]
  var marketplacesCapability: [Capability<&{FungibleToken.Receiver}>]

  prepare(acct: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, Storage) &Account) {
    if acct.storage.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) == nil {

        // Create a new empty .Storefront
        let storefront <- NFTStorefrontV2.createStorefront()
        
        // save it to the account
        acct.storage.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)

        // create a public capability for the .Storefront & publish
        let storefrontPublicCap = acct.capabilities.storage.issue<&{NFTStorefrontV2.StorefrontPublic}>(
                NFTStorefrontV2.StorefrontStoragePath
            )
        acct.capabilities.publish(storefrontPublicCap, at: NFTStorefrontV2.StorefrontPublicPath)
    }

    self.saleCuts = []
    self.marketplacesCapability = []
    let marketplacesAddress: [Address] = []

    let collectionData = ExampleNFT.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?
      ?? panic("ViewResolver does not resolve NFTCollectionData view")

    self.minter = acct.storage.borrow<&ExampleNFT.NFTMinter>(from: ExampleNFT.MinterStoragePath)
      ?? panic("Account does not store an object at the specified path")
    
    self.recipientCollectionRef = acct.capabilities.borrow<&{NonFungibleToken.Receiver}>(
      collectionData.publicPath
    ) ?? panic("Could not get receiver reference to the NFT Collection")

    self.storefront = acct.storage.borrow<auth(NFTStorefrontV2.CreateListing) &NFTStorefrontV2.Storefront>(
      from: NFTStorefrontV2.StorefrontStoragePath
    ) ?? panic("Missing or mis-typed NFTStorefront Storefront")

    self.tokenReceiver = acct.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    assert(self.tokenReceiver.borrow() != nil, message: "Missing or mis-typed ExampleToken receiver")

    var index = 0
    var listingResourceIds: [UInt64] = []

    while index < 10 {
      let royalties: [MetadataViews.Royalty] = []
      let nft <- self.minter.mintNFT(
        name: "testing",
        description: "testing",
        thumbnail: "thumbnail",
        royalties: royalties
      )
      let nftId = nft.id
      var totalRoyaltyCut = 0.0
      let effectiveSaleItemPrice = UFix64(0.00001)
      if nft.getViews().contains(Type<MetadataViews.Royalties>()) {
        let royaltiesRef = nft.resolveView(Type<MetadataViews.Royalties>())?? panic("Unable to retrieve the royalties")
        let royalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
        for royalty in royalties {
          // TODO - Verify the type of the vault and it should exists
          self.saleCuts.append(
            NFTStorefrontV2.SaleCut(
              receiver: royalty.receiver,
              amount: royalty.cut * effectiveSaleItemPrice
            )
          )
          totalRoyaltyCut = totalRoyaltyCut + (royalty.cut * effectiveSaleItemPrice)
        }
      }
      self.recipientCollectionRef.deposit(token: <-nft)

      let exampleNFTProvider = acct.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
        collectionData.storagePath
      )
      assert(exampleNFTProvider.check(), message: "Missing or mis-typed ExampleNFT provider")

      let collection = acct.capabilities.borrow<&{NonFungibleToken.Collection}>(
        collectionData.publicPath
      ) ?? panic("Could not borrow a reference to the signer's collection")

      let collectionRef = exampleNFTProvider.borrow()
        ?? panic("Could not borrow reference to collection")
      let nftRef = collectionRef.borrowNFT(nftId)
        ?? panic("Could not borrow a reference to the desired NFT ID from tx")

      // Append the cut for the seller.
      self.saleCuts.append(
        NFTStorefrontV2.SaleCut(
          receiver: self.tokenReceiver,
          amount: effectiveSaleItemPrice - totalRoyaltyCut
        )
      )

      for marketplace in marketplacesAddress {
        // Here we are making a fair assumption that all given addresses would have
        // the capability to receive the `ExampleToken`
        self.marketplacesCapability.append(
            getAccount(marketplace).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        )
      }

      log(nftId)

      listingResourceIds.append(self.storefront.createListing(
        nftProviderCapability: exampleNFTProvider,
        nftType: Type<@ExampleNFT.NFT>(),
        nftID: nftId,
        salePaymentVaultType: Type<@FlowToken.Vault>(),
        saleCuts: self.saleCuts,
        marketplacesCapability: nil,
        customID: nil,
        commissionAmount: UFix64(0),
        expiry: UInt64(1920175511)
      ))
      index = index + 1
    }

    log(listingResourceIds)
  }
}