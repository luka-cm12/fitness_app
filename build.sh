# Build script for Vercel deployment
echo "Building Flutter web app..."
cd fitness_app
flutter build web --release --web-renderer html

echo "Moving build files to deployment location..."
mkdir -p ../deploy/web
cp -r build/web/* ../deploy/web/

echo "Build complete!"