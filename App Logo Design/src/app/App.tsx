import { Logo } from '@/app/components/Logo';
import { Download, Smartphone, Globe, Tablet } from 'lucide-react';
import { useState } from 'react';

export default function App() {
  const [darkMode, setDarkMode] = useState(false);

  return (
    <div className={darkMode ? 'dark' : ''}>
      <div className="min-h-screen bg-background text-foreground">
        {/* Header */}
        <header className="border-b border-border bg-card">
          <div className="container mx-auto px-6 py-4 flex items-center justify-between">
            <Logo variant="full" size="md" />
            <button
              onClick={() => setDarkMode(!darkMode)}
              className="px-4 py-2 rounded-lg bg-secondary text-secondary-foreground hover:bg-secondary/80 transition-colors"
            >
              {darkMode ? '☀️ Light' : '🌙 Dark'}
            </button>
          </div>
        </header>

        {/* Main Content */}
        <main className="container mx-auto px-6 py-12">
          {/* Hero Section */}
          <div className="text-center mb-16">
            <h1 className="mb-4">Divvy - Share Tasks, Share Life</h1>
            <p className="text-muted-foreground max-w-2xl mx-auto">
              Logo design system for the household task-sharing app.
              Optimized for webapp, iOS, and Android with teal/copper (light mode) and rose/teal (dark mode) themes.
            </p>
          </div>

          {/* Logo Variations Grid */}
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 mb-16">
            {/* Full Logo */}
            <div className="bg-card border border-border rounded-xl p-8">
              <div className="flex items-center justify-center h-32 mb-6 bg-muted rounded-lg">
                <Logo variant="full" size="lg" />
              </div>
              <h3 className="mb-2">Full Logo</h3>
              <p className="text-muted-foreground text-sm">
                Primary logo with rounded square "d" icon and "ivvy" wordmark in DM Sans. Best for headers and navigation.
              </p>
            </div>

            {/* Icon Only */}
            <div className="bg-card border border-border rounded-xl p-8">
              <div className="flex items-center justify-center h-32 mb-6 bg-muted rounded-lg">
                <Logo variant="icon" size="lg" />
              </div>
              <h3 className="mb-2">Icon Only</h3>
              <p className="text-muted-foreground text-sm">
                Rounded square with lowercase "d" in DM Sans Bold. Perfect app icon for iOS and Android.
              </p>
            </div>

            {/* Text Only */}
            <div className="bg-card border border-border rounded-xl p-8">
              <div className="flex items-center justify-center h-32 mb-6 bg-muted rounded-lg">
                <Logo variant="text" size="lg" />
              </div>
              <h3 className="mb-2">Text Only</h3>
              <p className="text-muted-foreground text-sm">
                "ivvy" wordmark in DM Sans SemiBold. Pairs with icon variant for flexible layouts.
              </p>
            </div>
          </div>

          {/* Size Variations */}
          <div className="bg-card border border-border rounded-xl p-8 mb-16">
            <h2 className="mb-6">Size Variations</h2>
            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8">
              <div className="flex flex-col items-center gap-4">
                <div className="flex items-center justify-center h-32 w-full bg-muted rounded-lg">
                  <Logo variant="full" size="sm" />
                </div>
                <span className="text-sm text-muted-foreground">Small (32px)</span>
              </div>
              <div className="flex flex-col items-center gap-4">
                <div className="flex items-center justify-center h-32 w-full bg-muted rounded-lg">
                  <Logo variant="full" size="md" />
                </div>
                <span className="text-sm text-muted-foreground">Medium (48px)</span>
              </div>
              <div className="flex flex-col items-center gap-4">
                <div className="flex items-center justify-center h-32 w-full bg-muted rounded-lg">
                  <Logo variant="full" size="lg" />
                </div>
                <span className="text-sm text-muted-foreground">Large (64px)</span>
              </div>
              <div className="flex flex-col items-center gap-4">
                <div className="flex items-center justify-center h-32 w-full bg-muted rounded-lg">
                  <Logo variant="full" size="xl" />
                </div>
                <span className="text-sm text-muted-foreground">X-Large (96px)</span>
              </div>
            </div>
          </div>

          {/* Platform Specific Previews */}
          <div className="mb-16">
            <h2 className="mb-6">Platform Previews</h2>
            <div className="grid md:grid-cols-3 gap-8">
              {/* Web App */}
              <div className="bg-card border border-border rounded-xl p-6">
                <div className="flex items-center gap-2 mb-4 text-primary">
                  <Globe className="w-5 h-5" />
                  <h3>Web Application</h3>
                </div>
                <div className="bg-muted rounded-lg p-4 space-y-4">
                  <div className="bg-background border border-border rounded-lg p-3 flex items-center justify-between">
                    <Logo variant="full" size="sm" />
                    <div className="flex gap-2">
                      <div className="w-8 h-8 bg-muted-foreground/20 rounded"></div>
                      <div className="w-8 h-8 bg-muted-foreground/20 rounded"></div>
                    </div>
                  </div>
                  <div className="h-24 bg-background/50 rounded-lg flex items-center justify-center">
                    <Logo variant="icon" size="lg" />
                  </div>
                </div>
              </div>

              {/* iOS App */}
              <div className="bg-card border border-border rounded-xl p-6">
                <div className="flex items-center gap-2 mb-4 text-primary">
                  <Smartphone className="w-5 h-5" />
                  <h3>iOS Application</h3>
                </div>
                <div className="bg-gradient-to-b from-gray-800 to-gray-900 rounded-2xl p-4 space-y-4">
                  <div className="flex flex-col items-center gap-3">
                    <div className="w-20 h-20 rounded-2xl overflow-hidden bg-white flex items-center justify-center shadow-lg">
                      <Logo variant="icon" size="lg" />
                    </div>
                    <span className="text-white text-sm">Divvy</span>
                  </div>
                </div>
              </div>

              {/* Android App */}
              <div className="bg-card border border-border rounded-xl p-6">
                <div className="flex items-center gap-2 mb-4 text-primary">
                  <Tablet className="w-5 h-5" />
                  <h3>Android Application</h3>
                </div>
                <div className="bg-gradient-to-b from-gray-100 to-gray-200 rounded-2xl p-4 space-y-4">
                  <div className="flex flex-col items-center gap-3">
                    <div className="w-20 h-20 rounded-2xl overflow-hidden bg-white flex items-center justify-center shadow-md">
                      <Logo variant="icon" size="lg" />
                    </div>
                    <span className="text-gray-800 text-sm">Divvy</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Download Guidelines */}
          <div className="bg-card border-2 border-primary/20 rounded-xl p-8">
            <div className="flex items-center gap-3 mb-6">
              <Download className="w-6 h-6 text-primary" />
              <h2>Design Specifications</h2>
            </div>
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <h4 className="mb-3">Logo Details</h4>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li>• Font: DM Sans (Google Fonts)</li>
                  <li>• Icon "d": Weight 700 (Bold)</li>
                  <li>• Text "ivvy": Weight 600 (SemiBold)</li>
                  <li>• Shape: Rounded square, 28% radius</li>
                </ul>
              </div>
              <div>
                <h4 className="mb-3">Color Scheme</h4>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li>• Light: Teal (#009688) & Copper (#E07A5F)</li>
                  <li>• Dark: Rose (#F67280) & Teal (#4DB6AC)</li>
                  <li>• Icon uses primary color background</li>
                  <li>• White text on all icon backgrounds</li>
                </ul>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}