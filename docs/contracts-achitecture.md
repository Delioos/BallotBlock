classDiagram
    class DAOFactory {
        +createDAO()
        +listDAOs()
    }
    
    class DAO {
        +createProposal()
        +vote()
        +distributeTokens()
        +mintNFT()
    }
    
    class Proposal {
        +onChainVoting: bool
        +startVote()
        +endVote()
        +collectSignatures()
    }
    
    class Membership {
        +NFT
        +Token
    }
    
    DAOFactory --> DAO
    DAO --> Proposal
    DAO --> Membership
