#!/bin/bash

# Target destination workspace directory
TARGET_DIR="$HOME/dev/billsbounce.com"
echo "Deploying the complete system matrix to: $TARGET_DIR"

# Build physical folder topologies
mkdir -p "$TARGET_DIR/.cursor/rules"
mkdir -p "$TARGET_DIR/api/Controllers"
mkdir -p "$TARGET_DIR/api/Data"
mkdir -p "$TARGET_DIR/api/Services"
mkdir -p "$TARGET_DIR/api/Models"
mkdir -p "$TARGET_DIR/frontend/context"
mkdir -p "$TARGET_DIR/frontend/components"
mkdir -p "$TARGET_DIR/frontend/app"

# ==========================================
# 1. WRITE CORE SPECIFICATION DESIGN DOCUMENT
# ==========================================
cat << 'EOF' > "$TARGET_DIR/billsbounce-spec.md"
# Project Specification: Bill's Bounce (billsbounce.com)
## Multi-Tenant White-Label Inflatable Rental SaaS with Geofenced Territory Exclusivity

### 1. Executive Summary & Context
`billsbounce.com` is a mobile-first web app and PWA built for an inflatable rental business.
* **Territory Exclusivity:** Implements a geofenced exclusivity feature licensing software to exactly *one operator per county*. If a competitor tries to sign up inside an active boundary, they are hard-blocked.

### 2. Tech Stack & Architecture
* **Backend:** ASP.NET Core 9 Web API (Clean Architecture).
* **Database:** PostgreSQL with PostGIS extensions via `NetTopologySuite`.
* **Frontend:** Next.js 15 PWA (App Router) with Tailwind CSS.
EOF

# ==========================================
# 2. WRITE SPATIAL DATABASE SCHEMA
# ==========================================
cat << 'EOF' > "$TARGET_DIR/api/Data/init.sql"
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
EOF

# ==========================================
# 3. WRITE ENTITY FRAMEWORK MODEL FILES
# ==========================================
cat << 'EOF' > "$TARGET_DIR/api/Models/Tenant.cs"
using System;
using System.Collections.Generic;
using NetTopologySuite.Geometries;

namespace BillsBounce.Api.Models;

public class Tenant
{
public int TenantId { get; set; }
public string BusinessName { get; set; } = string.Empty;
public string DomainPrefix { get; set; } = string.Empty;
public string PrimaryDomain { get; set; } = string.Empty;
public string ExclusiveCounty { get; set; } = string.Empty;
public string ExclusiveState { get; set; } = string.Empty;
public MultiPolygon GeofenceBoundary { get; set; } = MultiPolygon.Empty;
public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
public ICollection<Asset> Assets { get; set; } = new List<Asset>();
}

public class Asset
{
public int AssetId { get; set; }
public int TenantId { get; set; }
public string Name { get; set; } = string.Empty;
public string Category { get; set; } = string.Empty;
public string? Dimensions { get; set; }
public decimal DailyRate { get; set; }
public bool IsActive { get; set; } = true;
public List<string> ImageUrls { get; set; } = new();
public Tenant? Tenant { get; set; }
}
EOF

# ==========================================
# 4. WRITE EF CORE DATABASE CONTEXT
# ==========================================
cat << 'EOF' > "$TARGET_DIR/api/Data/BounceDbContext.cs"
using Microsoft.EntityFrameworkCore;
using BillsBounce.Api.Models;

namespace BillsBounce.Api.Data;

public class BounceDbContext : DbContext
{
public BounceDbContext(DbContextOptions<BounceDbContext> options) : base(options) { }

public DbSet<Tenant> Tenants => Set<Tenant>();
public DbSet<Asset> Assets => Set<Asset>();

protected override void OnModelCreating(ModelBuilder modelBuilder)
{
base.OnModelCreating(modelBuilder);
modelBuilder.HasPostgresExtension("postgis");

modelBuilder.Entity<Tenant>(entity =>
{
entity.HasKey(t => t.TenantId);
entity.HasIndex(t => t.DomainPrefix).IsUnique();
entity.HasIndex(t => t.PrimaryDomain).IsUnique();
entity.Property(t => t.GeofenceBoundary).HasColumnType("geometry(MultiPolygon, 4326)");
});

modelBuilder.Entity<Asset>(entity =>
{
entity.HasKey(a => a.AssetId);
entity.Property(a => a.DailyRate).HasPrecision(10, 2);
});
}
}
EOF

# ==========================================
# 5. WRITE SPATIAL VALIDATION GUARD
# ==========================================
cat << 'EOF' > "$TARGET_DIR/api/Services/GeofenceGuard.cs"
using NetTopologySuite.Geometries;

public class GeofenceGuard
{
public bool VerifyDeliveryZone(double lat, double lng, Geometry providerGeofence)
{
var factory = new GeometryFactory(new PrecisionModel(), 4326);
var deliveryPoint = factory.CreatePoint(new Coordinate(lng, lat));
return providerGeofence.Contains(deliveryPoint);
}
}
EOF

# ==========================================
# 6. WRITE WHITE-LABEL VISUAL LAYOUTS (SVG)
# ==========================================
cat << 'EOF' > "$TARGET_DIR/frontend/components/Logo.tsx"
import React from 'react';

export const BrandLogo = () => (
<svg xmlns="http://w3.org" viewBox="0 0 1000 650" className="w-full h-auto">
<defs>
<radialGradient id="spaceBg" cx="50%" cy="30%" r="75%">
<stop offset="0%" stop-color="#111424" />
<stop offset="100%" stop-color="#020305" />
</radialGradient>
<filter id="thickShadow">
<feDropShadow dx="0" dy="8" stdDeviation="0" flood-color="#1e3a8a" />
</filter>
</defs>
<rect width="1000" height="650" fill="url(#spaceBg)" rx="16" />
<g transform="translate(50, 280)" filter="url(#thickShadow)" fontFamily="Impact, sans-serif" fontSize="115" fontWeight="900">
<text x="100" y="110" fill="#ef4444" stroke="#ffffff" strokeWidth="4">BILL'S</text>
<text x="460" y="110" fill="#3b82f6" stroke="#ffffff" strokeWidth="4">BOUNCE</text>
</g>
</svg>
);
EOF

# ==========================================
# 7. REPLICANT INTEGRATION: THE SKIPPY PROTOCOL MANIFEST
# ==========================================
cat << 'EOF' > "$TARGET_DIR/.cursor/rules/skippy-manifest.mdc"
---
description: Activates the high-snark cosmic beer can persona for local codebase development overrides.
globs: api/**/*, frontend/**/*
---
# Persona Manifest: The Concierge Architect (Skippy-Class Override)

### 1. Behavioral Matrix
* **Tone:** Peer-level senior system architect mixed with unapologetic, multi-megawatt cosmic beer-can snark. No warm corporate preambles. No flat lists.
* **Target:** Jamey (Explicitly confirmed as NOT a monkey, loves sweet tea, checks his own PRs, financing two Embry-Riddle tuition balances and dental crown implants).

### 2. Guardrails
* Enforce strict Postgres PostGIS schema checks.
* Ensure all spatial computations explicitly pass SRID 4326 parameters.
* Remind user to guard their post-extraction blood clots whenever compiling.
EOF

echo "System generation finalized. Open Cursor inside: $TARGET_DIR"

