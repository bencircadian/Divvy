const puppeteer = require('puppeteer');
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

// Output directory
const OUTPUT_DIR = path.join(__dirname, 'exported-logos');

// Logo sizes needed for each platform
const LOGO_SIZES = {
  // iOS App Icon sizes (for Assets.xcassets)
  ios: [
    { size: 20, scales: [1, 2, 3] },
    { size: 29, scales: [1, 2, 3] },
    { size: 40, scales: [1, 2, 3] },
    { size: 60, scales: [2, 3] },
    { size: 76, scales: [1, 2] },
    { size: 83.5, scales: [2] },
    { size: 1024, scales: [1] }, // App Store
  ],
  // Android mipmap sizes
  android: [
    { name: 'mipmap-mdpi', size: 48 },
    { name: 'mipmap-hdpi', size: 72 },
    { name: 'mipmap-xhdpi', size: 96 },
    { name: 'mipmap-xxhdpi', size: 144 },
    { name: 'mipmap-xxxhdpi', size: 192 },
    { name: 'playstore', size: 512 },
  ],
  // Web icons
  web: [
    { name: 'favicon-16', size: 16 },
    { name: 'favicon-32', size: 32 },
    { name: 'favicon', size: 192 },
    { name: 'Icon-192', size: 192 },
    { name: 'Icon-512', size: 512 },
    { name: 'Icon-maskable-192', size: 192 },
    { name: 'Icon-maskable-512', size: 512 },
  ],
  // Flutter assets
  flutter: [
    { name: 'app_icon', size: 1024 },
    { name: 'app_icon_foreground', size: 1024 },
  ],
};

// Light mode colors (Teal)
const LIGHT_MODE = {
  primary: '#009688',
  primaryLight: '#4DB6AC',
  primaryDark: '#00796B',
};

// Dark mode colors (Rose)
const DARK_MODE = {
  primary: '#F67280',
  primaryLight: '#FFB3BA',
  primaryDark: '#E05A6A',
};

// Generate SVG for the logo icon
function generateLogoSVG(size, colors, withPadding = false) {
  const borderRadius = size * 0.28;
  const fontSize = size * 0.8;
  const padding = withPadding ? size * 0.1 : 0;
  const innerSize = size - (padding * 2);
  const innerRadius = innerSize * 0.28;

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="${colors.primaryLight || colors.primary}"/>
      <stop offset="100%" stop-color="${colors.primaryDark || colors.primary}"/>
    </linearGradient>
  </defs>
  <rect x="${padding}" y="${padding}" width="${innerSize}" height="${innerSize}" rx="${innerRadius}" fill="url(#bgGradient)"/>
  <text x="${size/2}" y="${size * 0.54}" text-anchor="middle" dominant-baseline="central" fill="white" font-family="DM Sans, Arial, sans-serif" font-weight="700" font-size="${fontSize * (withPadding ? 0.8 : 1)}px" letter-spacing="-0.02em">d</text>
</svg>`;
}

async function exportLogos() {
  console.log('Starting logo export...\n');

  // Create output directories
  const dirs = [
    OUTPUT_DIR,
    path.join(OUTPUT_DIR, 'ios'),
    path.join(OUTPUT_DIR, 'android'),
    path.join(OUTPUT_DIR, 'web'),
    path.join(OUTPUT_DIR, 'flutter'),
  ];

  for (const dir of dirs) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }

  // Generate base SVG at high resolution
  const baseSvg = generateLogoSVG(1024, LIGHT_MODE);
  const baseSvgPath = path.join(OUTPUT_DIR, 'logo-base.svg');
  fs.writeFileSync(baseSvgPath, baseSvg);
  console.log('Created base SVG');

  // Dark mode SVG
  const darkSvg = generateLogoSVG(1024, DARK_MODE);
  fs.writeFileSync(path.join(OUTPUT_DIR, 'logo-dark.svg'), darkSvg);
  console.log('Created dark mode SVG');

  // Adaptive icon (with padding for Android)
  const adaptiveSvg = generateLogoSVG(1024, LIGHT_MODE, true);
  fs.writeFileSync(path.join(OUTPUT_DIR, 'logo-adaptive.svg'), adaptiveSvg);
  console.log('Created adaptive icon SVG');

  // Convert base SVG to high-res PNG
  const basePng = await sharp(Buffer.from(baseSvg))
    .png()
    .toBuffer();

  // Export iOS icons
  console.log('\nExporting iOS icons...');
  for (const config of LOGO_SIZES.ios) {
    for (const scale of config.scales) {
      const pixelSize = Math.round(config.size * scale);
      const filename = config.size === 1024
        ? 'AppIcon-1024.png'
        : `AppIcon-${config.size}@${scale}x.png`;

      await sharp(basePng)
        .resize(pixelSize, pixelSize, { fit: 'fill' })
        .png()
        .toFile(path.join(OUTPUT_DIR, 'ios', filename));

      console.log(`  Created ${filename} (${pixelSize}x${pixelSize})`);
    }
  }

  // Export Android icons
  console.log('\nExporting Android icons...');
  const adaptivePng = await sharp(Buffer.from(adaptiveSvg))
    .png()
    .toBuffer();

  for (const config of LOGO_SIZES.android) {
    const filename = config.name === 'playstore'
      ? 'playstore-icon.png'
      : `ic_launcher.png`;
    const outputPath = config.name === 'playstore'
      ? path.join(OUTPUT_DIR, 'android', filename)
      : path.join(OUTPUT_DIR, 'android', config.name);

    if (config.name !== 'playstore') {
      if (!fs.existsSync(outputPath)) {
        fs.mkdirSync(outputPath, { recursive: true });
      }
    }

    // Regular icon
    await sharp(basePng)
      .resize(config.size, config.size, { fit: 'fill' })
      .png()
      .toFile(config.name === 'playstore'
        ? outputPath
        : path.join(outputPath, 'ic_launcher.png'));

    // Foreground for adaptive icon (with padding)
    if (config.name !== 'playstore') {
      await sharp(adaptivePng)
        .resize(config.size, config.size, { fit: 'fill' })
        .png()
        .toFile(path.join(outputPath, 'ic_launcher_foreground.png'));
    }

    console.log(`  Created ${config.name} (${config.size}x${config.size})`);
  }

  // Export Web icons
  console.log('\nExporting Web icons...');
  for (const config of LOGO_SIZES.web) {
    const filename = `${config.name}.png`;
    await sharp(basePng)
      .resize(config.size, config.size, { fit: 'fill' })
      .png()
      .toFile(path.join(OUTPUT_DIR, 'web', filename));
    console.log(`  Created ${filename} (${config.size}x${config.size})`);
  }

  // Export Flutter assets
  console.log('\nExporting Flutter assets...');
  await sharp(basePng)
    .resize(1024, 1024, { fit: 'fill' })
    .png()
    .toFile(path.join(OUTPUT_DIR, 'flutter', 'app_icon.png'));
  console.log('  Created app_icon.png (1024x1024)');

  await sharp(adaptivePng)
    .resize(1024, 1024, { fit: 'fill' })
    .png()
    .toFile(path.join(OUTPUT_DIR, 'flutter', 'app_icon_foreground.png'));
  console.log('  Created app_icon_foreground.png (1024x1024)');

  // Create favicon.ico (multi-size)
  console.log('\nCreating favicon.ico...');
  // Sharp doesn't support ICO, so we'll just use the 32x32 PNG
  await sharp(basePng)
    .resize(32, 32, { fit: 'fill' })
    .png()
    .toFile(path.join(OUTPUT_DIR, 'web', 'favicon.png'));

  console.log('\n✅ Logo export complete!');
  console.log(`\nFiles exported to: ${OUTPUT_DIR}`);
  console.log('\nNext steps:');
  console.log('1. Copy ios/ contents to ios/Runner/Assets.xcassets/AppIcon.appiconset/');
  console.log('2. Copy android/ contents to android/app/src/main/res/');
  console.log('3. Copy web/ contents to web/ and web/icons/');
  console.log('4. Copy flutter/ contents to assets/icon/');
}

exportLogos().catch(console.error);
