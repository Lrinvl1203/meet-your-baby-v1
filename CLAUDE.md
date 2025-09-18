# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

**AI Baby Face Prediction Application** - Complete web application with Supabase authentication, Polar payment integration, and processing queue system. Currently in beta stage with multi-layer security implementation.

## ⚠️ SECURITY ALERT (2025-09-18)

**CRITICAL**: API key security incident occurred. See `SECURITY.md` for full details.

**Current Status**:
- ✅ Temporary security fix implemented
- ⚠️ New API key generation required
- 📋 Multi-tier API key loading system active

**Before making changes**: Review `SECURITY.md` for current security requirements.

## Architecture

**Single-page web application** with the following components:

### Core Technologies
- **Frontend**: Vanilla JavaScript (ES6+), HTML5, CSS3
- **Authentication**: Supabase (email/password + Google OAuth)
- **Database**: Supabase PostgreSQL with Row Level Security
- **Payments**: Polar Payment integration
- **AI**: Google Gemini API for baby face prediction
- **Storage**: Supabase Storage for image management

### Key Features
- Multi-mode photo upload (ultrasound, parents separately, parents together)
- Real-time authentication state management
- Shopping cart and checkout system
- Processing queue with progress tracking
- Order history and download management
- Mobile-responsive design

## Development Commands

**Local Development**:
```bash
# Start development server
npx http-server -p 8000 -c-1

# Access application
http://127.0.0.1:8000
```

**Database Management**:
- Execute `supabase-schema.sql` in Supabase dashboard for initial setup
- Review RLS policies before production deployment

## Getting Started

Since this is a greenfield project, consider establishing:

1. **Project Type**: Determine if this will be a static site, React/Vue/Angular app, or other framework
2. **Package Manager**: Set up package.json with appropriate dependencies
3. **Build System**: Configure bundling and development tools
4. **Project Structure**: Establish directory organization for components, assets, styles, etc.

## Notes

- The project directory name suggests Korean language support may be needed
- Consider internationalization (i18n) requirements early in development
- The "MeetYourBaby" theme suggests this may be a pregnancy/parenting-related application