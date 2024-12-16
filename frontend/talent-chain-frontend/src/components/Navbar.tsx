// src/components/Navbar.tsx
import { ConnectButton } from "thirdweb/react";
import { client, wallets } from "../utils/thirdweb";

const Navbar: React.FC = () => {
  return (
    <nav className="bg-gray-800 p-4 flex justify-between items-center">
      <div className="text-white font-bold text-2xl">Talent Chain</div>
      <ConnectButton
        client={client}
        wallets={wallets}
        connectButton={{ label: "Sign In" }}
        connectModal={{
          size: "compact",
          title: "Sign In",
          showThirdwebBranding: false,
        }}
      />
    </nav>
  );
};

export default Navbar;
