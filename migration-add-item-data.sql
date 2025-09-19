-- Migration: Add item_data column to cart_items table
-- Run this in Supabase SQL Editor to fix the cart functionality

-- Add the missing item_data column to cart_items table
ALTER TABLE cart_items
ADD COLUMN IF NOT EXISTS item_data JSONB NOT NULL DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN cart_items.item_data IS 'Stores generation settings and metadata for cart items';

-- Create index for better performance on JSONB queries
CREATE INDEX IF NOT EXISTS idx_cart_items_item_data ON cart_items USING GIN (item_data);

-- Verify the change
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'cart_items'
AND table_schema = 'public'
ORDER BY ordinal_position;