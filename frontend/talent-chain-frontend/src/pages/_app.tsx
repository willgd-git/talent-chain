// src/pages/_app.tsx
import "../styles/globals.css";
import type { AppProps } from "next/app";
import { ThirdwebProvider } from "thirdweb/react";
import { client, wallets } from "../utils/thirdweb";

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ThirdwebProvider>
      <Component {...pageProps} />
    </ThirdwebProvider>
  );
}

export default MyApp;
