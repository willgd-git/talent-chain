// src/utils/thirdweb.ts
import { createThirdwebClient } from "thirdweb";
import { inAppWallet, createWallet } from "thirdweb/wallets";

// Initialize the Thirdweb client with your Client ID
const client = createThirdwebClient({
  clientId: "bfeff02a87687435b308f5e65c5fbc1a", // Replace with your Thirdweb Client ID
});

// Define supported wallets: MetaMask and in-app wallets (Google, Twitter, Telegram)
const wallets = [
  inAppWallet({
    auth: {
      options: ["google", "x", "telegram"], // In-app wallet options
    },
  }),
  createWallet("io.metamask"), // MetaMask
];

export { client, wallets };
