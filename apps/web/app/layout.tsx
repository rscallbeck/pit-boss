import type { Metadata } from 'next';
import './globals.css';
import { Header } from '@aegis/shared-config';
import { Web3ProviderWrapper, ClientOnly, } from '@aegis/shared-config';

export const metadata: Metadata = {
  title: 'Aegis | Provably Fair',
  description: 'Next-gen decentralized gaming.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-slate-950 text-white antialiased">
        <ClientOnly>
          <Web3ProviderWrapper>
            {/* Main wrapper with global styling */}
            <div className="min-h-screen flex flex-col relative overflow-hidden">
              {/* Global Background Glow */}
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-200 h-200  bg-emerald-500/10 blur-[120px] rounded-full pointer-events-none" />
                <Header />
              {/* Added pb-28 for mobile to prevent content from hiding behind the bottom bar! */}
              <main className="flex-1 flex flex-col z-10 relative pb-25 md:pb-0">
                {children}
              </main>  
            </div>
          </Web3ProviderWrapper>
        </ClientOnly>
      </body>
    </html>
  );
}
