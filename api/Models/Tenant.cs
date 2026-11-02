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
