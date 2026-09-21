import geohash from "ngeohash";
import { getRedis } from "../config/redis.js";
import { AppError } from "../utils/api-error.js";

export async function getNearbyTemples(lat: number, lng: number, radiusKm: number) {
  // Precision 5 provides a bounding box of roughly 2.4km x 2.4km.
  // This means anyone within that box will get the same cached results, drastically saving API hits.
  const hash = geohash.encode(lat, lng, 5);
  const cacheKey = `temples:nearby:${hash}`;
  
  const redis = await getRedis();
  
  if (redis) {
    const cached = await redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }
  }

  const apiKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!apiKey) {
    // Graceful fallback for local development if the key isn't provided
    console.warn("GOOGLE_PLACES_API_KEY is missing. Returning empty array.");
    return [];
  }

  const radiusMeters = radiusKm * 1000;
  
  // Google Places API Nearby Search
  const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radiusMeters}&type=hindu_temple&key=${apiKey}`;

  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Google Places API error: ${response.statusText}`);
    }

    const data = await response.json();
    
    // We only care about specific fields for the app to reduce payload size
    const results = (data.results || []).map((place: any) => ({
      placeId: place.place_id,
      name: place.name,
      location: {
        lat: place.geometry?.location?.lat,
        lng: place.geometry?.location?.lng,
      },
      vicinity: place.vicinity,
      rating: place.rating,
      userRatingsTotal: place.user_ratings_total,
      icon: place.icon,
    }));

    if (redis) {
      // Cache for 24 hours (86400 seconds)
      await redis.setex(cacheKey, 86400, JSON.stringify(results));
    }

    return results;
  } catch (error) {
    console.error("Error fetching nearby temples:", error);
    throw new AppError(500, "INTERNAL_ERROR", "Failed to fetch nearby temples");
  }
}
