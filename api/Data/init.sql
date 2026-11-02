CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE tenants (
tenant_id SERIAL PRIMARY KEY,
business_name VARCHAR(255) NOT NULL,
domain_prefix VARCHAR(100) UNIQUE NOT NULL,
primary_domain VARCHAR(255) UNIQUE NOT NULL,
exclusive_county VARCHAR(100) NOT NULL,
exclusive_state VARCHAR(2) NOT NULL,
geofence_boundary GEOMETRY(MultiPolygon, 4326) NOT NULL,
created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT unique_county_state UNIQUE (exclusive_county, exclusive_state)
);

CREATE TABLE assets (
asset_id SERIAL PRIMARY KEY,
tenant_id INT REFERENCES tenants(tenant_id) ON DELETE CASCADE,
name VARCHAR(255) NOT NULL,
category VARCHAR(100) NOT NULL,
dimensions VARCHAR(100),
daily_rate NUMERIC(10, 2) NOT NULL,
is_active BOOLEAN DEFAULT TRUE,
image_urls TEXT[],
created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
booking_id SERIAL PRIMARY KEY,
tenant_id INT REFERENCES tenants(tenant_id) ON DELETE CASCADE,
customer_name VARCHAR(255) NOT NULL,
customer_email VARCHAR(255) NOT NULL,
customer_phone VARCHAR(50) NOT NULL,
delivery_address TEXT NOT NULL,
delivery_location GEOMETRY(Point, 4326) NOT NULL,
start_time TIMESTAMP WITH TIME ZONE NOT NULL,
end_time TIMESTAMP WITH TIME ZONE NOT NULL,
total_price NUMERIC(10, 2) NOT NULL,
status VARCHAR(50) DEFAULT 'Pending',
created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE booking_items (
booking_id INT REFERENCES bookings(booking_id) ON DELETE CASCADE,
asset_id INT REFERENCES assets(asset_id) ON DELETE CASCADE,
PRIMARY KEY (booking_id, asset_id)
);

CREATE INDEX idx_tenants_geofence ON tenants USING GIST (geofence_boundary);
CREATE INDEX idx_bookings_location ON bookings USING GIST (delivery_location);
