/**
 * Generate PWA icons from SVG
 * Run with: node scripts/generate-icons.js
 *
 * Prerequisites: npm install sharp
 */

const fs = require('fs');
const path = require('path');

// Check if sharp is available
let sharp;
try {
  sharp = require('sharp');
} catch (e) {
  console.log('Installing sharp package...');
  require('child_process').execSync('npm install sharp', { stdio: 'inherit' });
  sharp = require('sharp');
}

const svgPath = path.join(__dirname, '../web/icons/icon.svg');
const iconsDir = path.join(__dirname, '../web/icons');
const faviconPath = path.join(__dirname, '../web/favicon.png');

// Read the SVG file
const svgContent = fs.readFileSync(svgPath, 'utf8');

// Icon sizes to generate
const sizes = [
  { name: 'Icon-192.png', size: 192 },
  { name: 'Icon-512.png', size: 512 },
  { name: 'Icon-maskable-192.png', size: 192 },
  { name: 'Icon-maskable-512.png', size: 512 },
];

async function generateIcons() {
  console.log('Generating PWA icons from SVG...\n');

  // Generate each icon size
  for (const { name, size } of sizes) {
    const outputPath = path.join(iconsDir, name);

    await sharp(Buffer.from(svgContent))
      .resize(size, size)
      .png()
      .toFile(outputPath);

    console.log(`✓ Generated ${name} (${size}x${size})`);
  }

  // Generate favicon (32x32)
  await sharp(Buffer.from(svgContent))
    .resize(32, 32)
    .png()
    .toFile(faviconPath);

  console.log(`✓ Generated favicon.png (32x32)`);

  console.log('\n✅ All icons generated successfully!');
  console.log('\nNote: Clear your browser cache and re-add to home screen to see the new icons.');
}

generateIcons().catch(err => {
  console.error('Error generating icons:', err);
  process.exit(1);
});
