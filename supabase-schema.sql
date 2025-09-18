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

-- Processing Queue table for managing AI generation tasks
CREATE TABLE IF NOT EXISTS processing_queue (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    queue_position INTEGER NOT NULL,
    status TEXT DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'cancelled')),
    priority INTEGER DEFAULT 0, -- Higher numbers = higher priority
    generation_type TEXT NOT NULL CHECK (generation_type IN ('ultrasound', 'separate', 'together')),
    generation_params JSONB NOT NULL, -- Input parameters for AI generation
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    estimated_completion_time TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    result_data JSONB, -- Generated image URLs and metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Processing Steps table for detailed progress tracking
CREATE TABLE IF NOT EXISTS processing_steps (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    queue_id UUID REFERENCES processing_queue(id) ON DELETE CASCADE,
    step_name TEXT NOT NULL, -- e.g., 'preparing', 'analyzing', 'generating', 'enhancing', 'finalizing'
    step_order INTEGER NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'skipped')),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    step_data JSONB DEFAULT '{}', -- Step-specific data
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_generated_images_user_id ON generated_images(user_id);
CREATE INDEX IF NOT EXISTS idx_generated_images_created_at ON generated_images(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_processing_queue_user_id ON processing_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_processing_queue_status ON processing_queue(status);
CREATE INDEX IF NOT EXISTS idx_processing_queue_position ON processing_queue(queue_position);
CREATE INDEX IF NOT EXISTS idx_processing_steps_queue_id ON processing_steps(queue_id);
CREATE INDEX IF NOT EXISTS idx_processing_steps_order ON processing_steps(step_order);

-- Row Level Security Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE download_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE processing_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE processing_steps ENABLE ROW LEVEL SECURITY;

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

-- Processing Queue policies
CREATE POLICY "Users can view their own queue items" ON processing_queue
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own queue items" ON processing_queue
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own queue items" ON processing_queue
    FOR UPDATE USING (auth.uid() = user_id);

-- Processing Steps policies
CREATE POLICY "Users can view their processing steps" ON processing_steps
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM processing_queue
            WHERE processing_queue.id = processing_steps.queue_id
            AND processing_queue.user_id = auth.uid()
        )
    );

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

CREATE TRIGGER update_processing_queue_updated_at BEFORE UPDATE ON processing_queue
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

-- Function to add item to processing queue
CREATE OR REPLACE FUNCTION add_to_processing_queue(
    user_uuid UUID,
    order_uuid UUID,
    gen_type TEXT,
    gen_params JSONB,
    priority_level INTEGER DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
    new_queue_id UUID;
    next_position INTEGER;
BEGIN
    -- Get next queue position
    SELECT COALESCE(MAX(queue_position), 0) + 1
    INTO next_position
    FROM processing_queue
    WHERE status IN ('queued', 'processing');

    -- Insert into processing queue
    INSERT INTO processing_queue (
        user_id, order_id, queue_position, generation_type,
        generation_params, priority, estimated_completion_time
    )
    VALUES (
        user_uuid, order_uuid, next_position, gen_type,
        gen_params, priority_level, NOW() + INTERVAL '5 minutes'
    )
    RETURNING id INTO new_queue_id;

    -- Create default processing steps
    INSERT INTO processing_steps (queue_id, step_name, step_order) VALUES
        (new_queue_id, '이미지 분석 중', 1),
        (new_queue_id, 'AI 모델 준비', 2),
        (new_queue_id, '아기 얼굴 생성', 3),
        (new_queue_id, '이미지 품질 향상', 4),
        (new_queue_id, '최종 처리', 5);

    RETURN new_queue_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update processing progress
CREATE OR REPLACE FUNCTION update_processing_progress(
    queue_uuid UUID,
    new_status TEXT,
    progress_pct INTEGER DEFAULT NULL,
    current_step INTEGER DEFAULT NULL,
    error_msg TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Update main queue item
    UPDATE processing_queue
    SET
        status = new_status,
        progress_percentage = COALESCE(progress_pct, progress_percentage),
        started_at = CASE WHEN new_status = 'processing' AND started_at IS NULL THEN NOW() ELSE started_at END,
        completed_at = CASE WHEN new_status IN ('completed', 'failed', 'cancelled') THEN NOW() ELSE completed_at END,
        error_message = error_msg
    WHERE id = queue_uuid;

    -- Update current step if specified
    IF current_step IS NOT NULL THEN
        UPDATE processing_steps
        SET
            status = CASE
                WHEN new_status = 'failed' THEN 'failed'
                WHEN step_order < current_step THEN 'completed'
                WHEN step_order = current_step THEN 'in_progress'
                ELSE 'pending'
            END,
            progress_percentage = CASE
                WHEN step_order < current_step THEN 100
                WHEN step_order = current_step THEN COALESCE(progress_pct, 0)
                ELSE 0
            END,
            started_at = CASE
                WHEN step_order = current_step AND status = 'pending' THEN NOW()
                ELSE started_at
            END,
            completed_at = CASE
                WHEN step_order < current_step THEN NOW()
                ELSE completed_at
            END
        WHERE queue_id = queue_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's queue status
CREATE OR REPLACE FUNCTION get_user_queue_status(user_uuid UUID)
RETURNS TABLE (
    queue_id UUID,
    status TEXT,
    generation_type TEXT,
    progress_percentage INTEGER,
    queue_position INTEGER,
    estimated_completion TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pq.id,
        pq.status,
        pq.generation_type,
        pq.progress_percentage,
        pq.queue_position,
        pq.estimated_completion_time,
        pq.created_at
    FROM processing_queue pq
    WHERE pq.user_id = user_uuid
    AND pq.status IN ('queued', 'processing', 'completed')
    ORDER BY pq.created_at DESC;
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