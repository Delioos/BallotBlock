# current development status
- [x] project dependency management 
- [ ] architecture design
- [ ] contracts development
- [ ] contracts testing
- [ ] contracts deployment
- [ ] backend(s) development
- [ ] frontend development
- [ ] dockerization
- [ ] CI/CD pipeline
- [ ] monitoring and observability
- [ ] documentation


# What is BallotBlock?
Ballot Block is a plateform intented to help DAO organize their activities.
This includes a bunch of differents actions:
- creating a DAO (using a number of token or a NFT)
- distributing DAO pass to members or let them mint it 
- let dao member propose a vote
- visualize ongoing polls
- visualize votes history

# Technology
Ballot Block is carefully crafted using the following stack:
- solidity with a bit of inline assembly for contracts (might use huff to optimize gas for some operations like mint)
- Golang for the backend (multiple micro services using restful architecture)
- next.js for the frontend 
- mongo db for some database work
- grafana and prometheus for app health managment
- a combiniation of precommits custom hooks and github actions, testify (for go), and foundry (for solidity) as a entreprise grade CI 
- Docker and Aws as a CD pipeline

# note 
One of the key feature I would like to implement is the possibility to vote offchain. 
For non critical polls, users could propose a vote and tick the "offchain" feature,
This would enable DAO participant to only sign with their wallet and not creating a real transaction, making "small" votes faster and costless for participant.
