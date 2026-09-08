import AsyncStorage from '@react-native-asyncstorage/asyncstorage';
import { HouseRecord } from '../types';

const GOOGLE_GEOCODING_API_KEY = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
const GEOCODE_CACHE_PREFIX = '@geocode_cache_';

export async function geocodeAddress(address: string): Promise<{ lat: number; lng: number } | null> {
  const cacheKey = `${GEOCODE_CACHE_PREFIX}${address.toLowerCase().trim()}`;
  
  try {
    // 1. Check local cache first
    const cached = await AsyncStorage.getItem(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    // 2. Fetch from Google Geocoding API if not cached
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${GOOGLE_GEOCODING_API_KEY}`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'OK' && data.results.length > 0) {
      const location = data.results[0].geometry.location;
      const coords = { lat: location.lat, lng: location.lng };
      
      // Save result to cache
      await AsyncStorage.setItem(cacheKey, JSON.stringify(coords));
      return coords;
    }
  } catch (error) {
    console.warn(`[Geocoding Error] Failed to geocode address: ${address}`, error);
  }

  return null;
}

/**
 * Ensures all house records have valid lat/lng coordinates
 */
export async function ensureHousesGeocoded(houses: HouseRecord[]): Promise<HouseRecord[]> {
  return Promise.all(
    houses.map(async (house) => {
      if (house.lat && house.lng) return house;
      const coords = await geocodeAddress(house.address);
      return coords ? { ...house, lat: coords.lat, lng: coords.lng } : house;
    })
  );
}
