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
