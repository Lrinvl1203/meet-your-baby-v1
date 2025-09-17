-- MeetYourBaby Database Schema for Supabase
-- Created for user authentication, image management, cart, and orders

-- Enable Row Level Security and necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'pro')),
    credits_remaining INTEGER DEFAULT 3, -- Free tier gets 3 credits
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Generated Images table
CREATE TABLE IF NOT EXISTS generated_images (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    image_type TEXT NOT NULL CHECK (image_type IN ('ultrasound', 'separate', 'together')),
    generation_settings JSONB NOT NULL, -- Stores all generation parameters
    metadata JSONB DEFAULT '{}', -- Additional metadata
    file_size_bytes BIGINT,
    image_format TEXT DEFAULT 'png',
    is_purchased BOOLEAN DEFAULT FALSE,
    price_cents INTEGER NOT NULL DEFAULT 299, -- $2.99 default
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cart Items table
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_id UUID REFERENCES generated_images(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
    price_cents INTEGER NOT NULL,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, image_id) -- Prevent duplicate items
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    order_number TEXT UNIQUE NOT NULL,
    total_amount_cents INTEGER NOT NULL,
    currency TEXT DEFAULT 'USD',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    payment_provider TEXT DEFAULT 'polar',
    payment_id TEXT, -- Polar payment/checkout ID
    payment_url TEXT, -- Polar checkout URL
    payment_completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order Items table
CREATE TABLE IF NOT EXISTS order_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    image_id UUID REFERENCES generated_images(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL,
    total_price_cents INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Sessions/Activity tracking (optional)
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Download History (for purchased images)
CREATE TABLE IF NOT EXISTS download_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_id UUID REFERENCES generated_images(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    download_count INTEGER DEFAULT 1,
    downloaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_generated_images_user_id ON generated_images(user_id);
CREATE INDEX IF NOT EXISTS idx_generated_images_created_at ON generated_images(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);

-- Row Level Security Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE download_history ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Generated Images policies
CREATE POLICY "Users can view their own images" ON generated_images
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own images" ON generated_images
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own images" ON generated_images
    FOR UPDATE USING (auth.uid() = user_id);

-- Cart Items policies
CREATE POLICY "Users can manage their own cart" ON cart_items
    FOR ALL USING (auth.uid() = user_id);

-- Orders policies
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id);

-- Order Items policies
CREATE POLICY "Users can view their order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
            AND orders.user_id = auth.uid()
        )
    );

-- Download History policies
CREATE POLICY "Users can view their download history" ON download_history
    FOR ALL USING (auth.uid() = user_id);

-- Functions for common operations
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
BEGIN
    RETURN 'MYB-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTRING(uuid_generate_v4()::text, 1, 8));
END;
$$ LANGUAGE plpgsql;

-- Function to calculate cart total
CREATE OR REPLACE FUNCTION get_cart_total(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    total INTEGER := 0;
BEGIN
    SELECT COALESCE(SUM(price_cents * quantity), 0)
    INTO total
    FROM cart_items
    WHERE user_id = user_uuid;

    RETURN total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to move cart items to order
CREATE OR REPLACE FUNCTION create_order_from_cart(user_uuid UUID)
RETURNS UUID AS $$
DECLARE
    new_order_id UUID;
    cart_total INTEGER;
    order_num TEXT;
BEGIN
    -- Calculate total
    SELECT get_cart_total(user_uuid) INTO cart_total;

    IF cart_total = 0 THEN
        RAISE EXCEPTION 'Cart is empty';
    END IF;

    -- Generate order number
    SELECT generate_order_number() INTO order_num;

    -- Create order
    INSERT INTO orders (user_id, order_number, total_amount_cents)
    VALUES (user_uuid, order_num, cart_total)
    RETURNING id INTO new_order_id;

    -- Move cart items to order items
    INSERT INTO order_items (order_id, image_id, quantity, unit_price_cents, total_price_cents)
    SELECT
        new_order_id,
        image_id,
        quantity,
        price_cents,
        price_cents * quantity
    FROM cart_items
    WHERE user_id = user_uuid;

    -- Clear cart
    DELETE FROM cart_items WHERE user_id = user_uuid;

    RETURN new_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample pricing tiers (can be customized)
INSERT INTO generated_images (id, user_id, image_url, image_type, generation_settings, price_cents) VALUES
    (uuid_generate_v4(), null, 'sample', 'ultrasound', '{}', 399), -- $3.99 for ultrasound
    (uuid_generate_v4(), null, 'sample', 'separate', '{}', 299),   -- $2.99 for parents separately
    (uuid_generate_v4(), null, 'sample', 'together', '{}', 349)    -- $3.49 for parents together
ON CONFLICT DO NOTHING;

-- Delete sample data
DELETE FROM generated_images WHERE user_id IS NULL;