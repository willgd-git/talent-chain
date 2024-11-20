# Talent Chain
TalentChain is a decentralized skill exchange platform that enables users to trade skills and services directly through a secure, transparent, and decentralized system. By leveraging blockchain technology, TalentChain eliminates intermediaries, reduces costs, and empowers users with control over their data and transactions.

---

## **TalentChain End-to-End Flow**

---

### **1. User Registration and Profile Creation**

**User Actions:**

- **Connect Wallet:** A new user visits the TalentChain website and connects their cryptocurrency wallet (e.g., MetaMask) to the platform.
- **Profile Setup:** The user fills out their profile information, such as name, bio, skills, and uploads a profile picture or portfolio files.

**System Processes:**

- **Front-End Application:**

  - **Data Collection:** Collects the user's profile data and media files.
  - **IPFS Upload:** Uploads media files to IPFS (InterPlanetary File System) using an IPFS client library.
  - **Retrieve IPFS Hashes:** Obtains the IPFS content identifiers (CIDs), which are hashes representing the stored files.

- **Smart Contract Interaction:**

  - **UserRegistry Contract:** The front-end sends a transaction to the `UserRegistry.sol` contract's `registerUser` function.
  - **Transaction Details:** Includes the IPFS hash of the user's profile data.
  - **User Confirmation:** The user's wallet prompts them to confirm the transaction.

- **Blockchain:**

  - **Transaction Execution:** Once confirmed, the transaction is executed on the blockchain.
  - **Data Storage:** The `UserRegistry` contract stores the user's address and IPFS hash on-chain.
  - **Event Emission:** An event `UserRegistered` is emitted, containing the user's address and IPFS hash.

- **The Graph:**

  - **Event Indexing:** The subgraph indexes the `UserRegistered` event.
  - **Data Availability:** This allows efficient querying of user data via GraphQL.

**Data Flow Summary:**

- **On-Chain Data:** User's address and IPFS hash of profile data.
- **Off-Chain Data:** Actual profile data and media stored on IPFS.
- **Event Data:** Indexed by The Graph for retrieval.

### **2. Service Listing**

**User Actions:**

- **Create Service:** A registered user (service provider) wants to offer a service.
- **Input Details:** Fills out service details like title, description, price, and uploads any relevant media (e.g., work samples).

**System Processes:**

- **Front-End Application:**

  - **Data Collection:** Gathers service information and media files.
  - **IPFS Upload:** Uploads media files to IPFS and obtains their hashes.
  - **Prepare Transaction:** Compiles essential service data, including IPFS hashes.

- **Smart Contract Interaction:**

  - **ServiceListing Contract:** Sends a transaction to the `ServiceListing.sol` contract's `createService` function.
  - **Transaction Details:** Includes price and IPFS hash of the service details.
  - **User Confirmation:** Service provider confirms the transaction via their wallet.

- **Blockchain:**

  - **Data Storage:** The `ServiceListing` contract stores the service ID, provider's address, price, and IPFS hash.
  - **Event Emission:** An event `ServiceCreated` is emitted with service details.

- **The Graph:**

  - **Event Indexing:** The subgraph indexes the `ServiceCreated` event for efficient querying.

**Data Flow Summary:**

- **On-Chain Data:** Service ID, provider's address, price, IPFS hash.
- **Off-Chain Data:** Service descriptions and media on IPFS.
- **Event Data:** Indexed by The Graph.

### **3. Browsing and Selecting Services**

**User Actions:**

- **Browse Services:** A client explores available services on the platform.
- **View Details:** Checks service descriptions, provider profiles, and ratings.
- **Select Service:** Decides on a service to purchase.

**System Processes:**

- **Front-End Application:**

  - **Query Services:** Uses The Graph to fetch a list of services.
  - **Retrieve Data:** Fetches on-chain data and off-chain service details from IPFS.
  - **Display Services:** Shows services with all relevant information to the client.

**Data Flow Summary:**

- **Data Retrieval:** On-chain data via The Graph; off-chain data from IPFS.

### **4. Initiating a Service Agreement**

**User Actions:**

- **Request Service:** Client initiates a service agreement by specifying any additional requirements.
- **Agreement Details:** Confirms the price and terms.

**System Processes:**

- **Front-End Application:**

  - **Prepare Agreement:** Collects any additional agreement details.
  - **Initiate Transaction:** Sends a transaction to the `ServiceAgreement.sol` contract's `createAgreement` function.

- **Smart Contract Interaction:**

  - **Transaction Details:** Includes service ID, client address, and any specific terms.
  - **User Confirmation:** Client confirms the transaction via their wallet.

- **Blockchain:**

  - **Agreement Creation:** The `ServiceAgreement` contract creates a new agreement with a unique ID and status `Proposed`.
  - **Event Emission:** An event `AgreementCreated` is emitted.

- **The Graph:**

  - **Event Indexing:** The subgraph indexes the `AgreementCreated` event.

**Data Flow Summary:**

- **On-Chain Data:** Agreement ID, service ID, client and provider addresses, agreement status.
- **Event Data:** Indexed by The Graph.

### **5. Payment and Escrow**

**User Actions:**

- **Deposit Funds:** Client deposits the agreed-upon amount into the platform's escrow.

**System Processes:**

- **Front-End Application:**

  - **Initiate Payment:** Prepares the payment transaction to the `PaymentManager.sol` contract.
  - **Transaction Details:** Amount to be transferred and agreement ID.
  - **User Confirmation:** Client confirms the transaction.

- **Smart Contract Interaction:**

  - **Fund Management:** The `PaymentManager` contract receives the funds and associates them with the agreement ID.

- **Blockchain:**

  - **Escrow Update:** Funds are held securely in escrow.
  - **Agreement Status Update:** The agreement status is updated to `Funded`.
  - **Event Emission:** An event `FundsDeposited` is emitted.

- **The Graph:**

  - **Event Indexing:** Indexes the `FundsDeposited` event.

**Data Flow Summary:**

- **On-Chain Data:** Escrow balance, updated agreement status.
- **Event Data:** Indexed by The Graph.

### **6. Service Acceptance by Provider**

**User Actions:**

- **Accept Agreement:** Service provider reviews and accepts the service agreement.

**System Processes:**

- **Front-End Application:**

  - **Notification:** Provider is notified of the new agreement.
  - **Initiate Acceptance:** Provider sends a transaction to `ServiceAgreement.sol`'s `acceptAgreement` function.

- **Smart Contract Interaction:**

  - **Agreement Update:** The contract updates the agreement status to `Accepted`.

- **Blockchain:**

  - **Event Emission:** An event `AgreementAccepted` is emitted.

- **The Graph:**

  - **Event Indexing:** Indexes the `AgreementAccepted` event.

**Data Flow Summary:**

- **On-Chain Data:** Updated agreement status.
- **Event Data:** Indexed by The Graph.

### **7. Service Delivery**

**User Actions:**

- **Deliver Service:** Provider completes the service and uploads any deliverables to IPFS.
- **Submit Deliverables:** Provider sends deliverable details to the client.

**System Processes:**

- **Front-End Application:**

  - **IPFS Upload:** Provider uploads files to IPFS and obtains hashes.
  - **Notify Client:** Sends the IPFS hash to the client through the platform.

- **Smart Contract Interaction (Optional):**

  - **Record Delivery:** Provider may record the delivery on-chain by calling `submitDeliverables`, which logs an event with the IPFS hash.

- **Blockchain:**

  - **Event Emission:** If on-chain, an event `DeliverablesSubmitted` is emitted.

- **The Graph:**

  - **Event Indexing:** Indexes the `DeliverablesSubmitted` event.

**Data Flow Summary:**

- **Off-Chain Data:** Deliverables stored on IPFS.
- **Event Data:** Indexed by The Graph if recorded on-chain.

### **8. Completion and Fund Release**

**User Actions:**

- **Review Service:** Client reviews the deliverables.
- **Confirm Completion:** If satisfied, client confirms service completion.

**System Processes:**

- **Front-End Application:**

  - **Initiate Completion:** Client sends a transaction to `ServiceAgreement.sol`'s `completeAgreement` function.

- **Smart Contract Interaction:**

  - **Update Agreement:** Agreement status is updated to `Completed`.
  - **Fund Release:** `PaymentManager` releases the escrowed funds to the provider.

- **Blockchain:**

  - **Event Emission:** Events `AgreementCompleted` and `FundsReleased` are emitted.

- **The Graph:**

  - **Event Indexing:** Indexes the completion and fund release events.

**Data Flow Summary:**

- **On-Chain Data:** Updated agreement status, fund transfer.
- **Event Data:** Indexed by The Graph.

### **9. Submitting Feedback and Reputation Update**

**User Actions:**

- **Provide Feedback:** Both client and provider rate each other and optionally leave comments.

**System Processes:**

- **Front-End Application:**

  - **Collect Feedback:** Gathers ratings and comments.
  - **IPFS Upload (Comments):** If comments are provided, they are uploaded to IPFS.
  - **Submit Feedback:** Sends a transaction to `ReputationManager.sol`'s `submitFeedback` function with the rating and IPFS hash of comments.

- **Smart Contract Interaction:**

  - **Reputation Update:** The contract updates the user's aggregate reputation score.

- **Blockchain:**

  - **Event Emission:** An event `FeedbackSubmitted` is emitted.

- **The Graph:**

  - **Event Indexing:** Indexes the feedback events.

**Data Flow Summary:**

- **On-Chain Data:** Updated reputation scores.
- **Off-Chain Data:** Comments stored on IPFS.
- **Event Data:** Indexed by The Graph.

### **10. Dispute Resolution**

**User Actions:**

- **Initiate Dispute:** If the client or provider is dissatisfied, they can raise a dispute.

**System Processes:**

- **Front-End Application:**

  - **Collect Dispute Details:** Gathers reason and evidence.
  - **IPFS Upload:** Uploads evidence to IPFS.
  - **Submit Dispute:** Sends a transaction to `DisputeResolution.sol`'s `raiseDispute` function with the IPFS hash.

- **Smart Contract Interaction:**

  - **Dispute Creation:** The contract creates a dispute record and updates the agreement status to `Disputed`.
  - **Funds Frozen:** Escrowed funds remain locked until resolution.

- **Blockchain:**

  - **Event Emission:** An event `DisputeRaised` is emitted.

- **Dispute Resolution Process:**

  - **Manual Resolution (Initial Phase):** The team manually reviews the dispute and resolves it.
  - **Resolution Recording:** The outcome is recorded on-chain via a transaction to `resolveDispute`.

- **The Graph:**

  - **Event Indexing:** Indexes dispute-related events.

**Data Flow Summary:**

- **On-Chain Data:** Dispute status, agreement updates.
- **Off-Chain Data:** Evidence stored on IPFS.
- **Event Data:** Indexed by The Graph.

### **11. Data Retrieval and Display**

**Front-End Application:**

- **User Profiles:**

  - **Query The Graph:** Retrieves user addresses and IPFS hashes.
  - **Fetch from IPFS:** Downloads profile data and media files using IPFS hashes.

- **Service Listings:**

  - **Query The Graph:** Retrieves service IDs, provider addresses, prices, and IPFS hashes.
  - **Fetch from IPFS:** Downloads service descriptions and media.

- **Agreements and Transactions:**

  - **Real-Time Updates:** Listens to events via The Graph for changes in agreement statuses.

- **Reputation Scores:**

  - **On-Chain Data:** Fetches aggregate reputation scores.
  - **Off-Chain Data:** Retrieves detailed feedback from IPFS.

**Data Flow Summary:**

- **On-Chain Data:** Retrieved via The Graph.
- **Off-Chain Data:** Accessed through IPFS using hashes.

---

## **Tech Stack Overview**

---

### **1. Smart Contract Development**

- **Language and Framework:**
  - **Solidity:** Primary language for writing smart contracts.
  - **Foundry Framework:** Used for development, testing, and deployment of Solidity contracts.
    - **Benefits:** Fast compilation, robust testing suite, and advanced debugging tools.

- **Security Analysis:**
  - **Mythril:** A security analysis tool for detecting vulnerabilities in smart contracts.
  - **Slither:** A static analysis framework to identify potential security issues.

- **Libraries and Standards:**
  - **OpenZeppelin Contracts:** Utilized for standardized and secure implementations of ERC standards and other common smart contract patterns.

### **2. Front-End Development**

- **Framework:**
  - **React.js:** For building a responsive and interactive user interface.

- **UI Libraries:**
  - **Shadcn UI:** For pre-built UI components and styling solutions.

- **State Management:**
  - **Redux or Context API:** To manage application state effectively.

### **3. Smart Contract Integration and Wallet Management**

- **Thirdweb SDK:**
  - Simplifies interaction between the front-end and smart contracts.
  - Provides wallet connection capabilities and contract abstractions.
  - **Benefits:** Accelerates development by handling common blockchain interactions.

### **4. Backend and Data Indexing**

- **The Graph (Subgraph):**
  - For indexing blockchain data and listening to smart contract events.
  - Enables efficient querying of on-chain data using GraphQL.

- **Apollo Client:**
  - Used in the front-end to query data from the subgraph.

### **5. Development and Deployment Tools**

- **Version Control:**
  - **Git and GitHub:** For source code management and collaboration.

- **Hosting:**
  - **Frontend:**
    - **Vercel or Netlify:** For deploying the React application.
  - **Subgraph:**
    - **Hosted Service by The Graph:** For deploying the subgraph.

### **6. Testing and Quality Assurance**

- **Smart Contract Testing:**
  - **Forge (Foundry's testing framework):** For writing and running smart contract tests in Solidity.

