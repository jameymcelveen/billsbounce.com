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
