# Deployment Guide - Fitness SaaS

## 🚀 Deploy to Vercel

### 1. Prerequisites
- Vercel CLI installed: `npm install -g vercel`
- Flutter SDK installed
- Node.js and npm installed

### 2. Environment Setup
1. Copy `.env.production` to `.env.local` in Vercel dashboard
2. Update `JWT_SECRET` with a secure random string
3. Configure optional services (email, payments)

### 3. Deploy Steps

#### Option A: Using Vercel CLI
```bash
# Login to Vercel
vercel login

# Deploy
vercel --prod
```

#### Option B: Using Git Integration
1. Push code to GitHub/GitLab
2. Connect repository in Vercel dashboard
3. Set build command: `npm run vercel-build`
4. Set output directory: `deploy/web`

### 4. Database Migration
The SQLite database will be automatically created on first run. For production, consider upgrading to PostgreSQL:

```bash
# Add PostgreSQL support
npm install pg

# Update config/database.js to use PostgreSQL in production
```

### 5. Custom Domain
1. Go to Vercel project settings
2. Add your custom domain
3. Update DNS records as instructed

### 6. Monitoring
- API Health Check: `https://yourapp.vercel.app/health`
- API Documentation: `https://yourapp.vercel.app/api/docs`

## 📱 Mobile App Deployment

### Android
```bash
cd fitness_app
flutter build apk --release
```

### iOS (macOS required)
```bash
cd fitness_app
flutter build ios --release
```

## 🔧 Environment Variables

Required:
- `NODE_ENV=production`
- `JWT_SECRET=your-secret-key`

Optional:
- `SMTP_*` for email features
- `STRIPE_*` for payments

## 📊 Pricing Model
- **R$49,90/mês** per trainer (up to 10 athletes)
- Automatic subscription management via Stripe
- Free trial: 14 days

## 🎯 Next Steps
1. Set up payment gateway (Stripe)
2. Configure email service (SendGrid/Gmail)
3. Add analytics (Google Analytics)
4. Set up monitoring (Sentry)
5. Configure CDN for better performance