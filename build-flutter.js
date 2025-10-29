import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

console.log('🚀 Building Flutter web app for production...');

try {
  // Change to Flutter app directory
  process.chdir('fitness_app');
  
  // Build Flutter web app
  console.log('📦 Building Flutter web...');
  execSync('flutter build web --release', { stdio: 'inherit' });
  
  // Create deploy directory
  const deployDir = path.join('..', 'deploy', 'web');
  if (!fs.existsSync(deployDir)) {
    fs.mkdirSync(deployDir, { recursive: true });
  }
  
  // Copy build files
  console.log('📁 Copying build files...');
  const buildDir = path.join('build', 'web');
  
  if (fs.existsSync(buildDir)) {
    // Copy all files from build/web to deploy/web
    const copyRecursive = (src, dest) => {
      const stats = fs.statSync(src);
      if (stats.isDirectory()) {
        if (!fs.existsSync(dest)) {
          fs.mkdirSync(dest);
        }
        fs.readdirSync(src).forEach(file => {
          copyRecursive(path.join(src, file), path.join(dest, file));
        });
      } else {
        fs.copyFileSync(src, dest);
      }
    };
    
    copyRecursive(buildDir, deployDir);
    console.log('✅ Build completed successfully!');
  } else {
    throw new Error('Build directory not found');
  }
} catch (error) {
  console.error('❌ Build failed:', error.message);
  process.exit(1);
}