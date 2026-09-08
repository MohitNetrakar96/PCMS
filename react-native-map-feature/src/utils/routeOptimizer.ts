import { HouseRecord, AgentLocation } from '../types';

/**
 * Haversine formula to compute distance in meters between two lat/lng points
 */
export function getDistanceMeters(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371e3; // Earth radius in meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Sorts pending houses by nearest-neighbor visiting order starting from agent's current position
 */
export function sortHousesByNearestNeighbor(
  currentLocation: AgentLocation,
  houses: HouseRecord[]
): HouseRecord[] {
  const pending = houses.filter(h => h.collection_status === 'pending' && h.lat && h.lng);
  const unvisited = [...pending];
  const orderedRoute: HouseRecord[] = [];

  let currentLat = currentLocation.latitude;
  let currentLng = currentLocation.longitude;

  while (unvisited.length > 0) {
    let nearestIdx = -1;
    let minDistance = Infinity;

    for (let i = 0; i < unvisited.length; i++) {
      const house = unvisited[i];
      const dist = getDistanceMeters(currentLat, currentLng, house.lat!, house.lng!);
      if (dist < minDistance) {
        minDistance = dist;
        nearestIdx = i;
      }
    }

    if (nearestIdx !== -1) {
      const [nextStop] = unvisited.splice(nearestIdx, 1);
      orderedRoute.push(nextStop);
      currentLat = nextStop.lat!;
      currentLng = nextStop.lng!;
    } else {
      break;
    }
  }

  // Append collected and skipped houses at the end
  const finished = houses.filter(h => h.collection_status !== 'pending');
  return [...orderedRoute, ...finished];
}
