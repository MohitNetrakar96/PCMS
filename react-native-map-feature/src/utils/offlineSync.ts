import AsyncStorage from '@react-native-asyncstorage/asyncstorage';
import NetInfo from '@react-native-community/netinfo';
import { HouseRecord, PendingSyncMutation, CollectionStatus } from '../types';

const HOUSES_CACHE_KEY = '@pcms_daily_houses';
const SYNC_QUEUE_KEY = '@pcms_sync_queue';

export async function cacheHousesLocally(houses: HouseRecord[]): Promise<void> {
  await AsyncStorage.setItem(HOUSES_CACHE_KEY, JSON.stringify(houses));
}

export async function getCachedHouses(): Promise<HouseRecord[] | null> {
  const data = await AsyncStorage.getItem(HOUSES_CACHE_KEY);
  return data ? JSON.parse(data) : null;
}

export async function queueStatusUpdate(
  houseId: string,
  status: CollectionStatus,
  backendUpdateFn: (id: string, status: CollectionStatus) => Promise<void>
): Promise<void> {
  const state = await NetInfo.fetch();

  if (state.isConnected) {
    try {
      await backendUpdateFn(houseId, status);
      return;
    } catch (e) {
      console.warn('[Network Sync] Direct update failed. Enqueuing for retry...');
    }
  }

  // Queue mutation locally when offline
  const rawQueue = await AsyncStorage.getItem(SYNC_QUEUE_KEY);
  const queue: PendingSyncMutation[] = rawQueue ? JSON.parse(rawQueue) : [];
  
  // Remove duplicate entries for same house if present
  const filtered = queue.filter(item => item.houseId !== houseId);
  filtered.push({ houseId, status, timestamp: Date.now() });

  await AsyncStorage.setItem(SYNC_QUEUE_KEY, JSON.stringify(filtered));
}

export async function flushSyncQueue(
  backendUpdateFn: (id: string, status: CollectionStatus) => Promise<void>
): Promise<void> {
  const rawQueue = await AsyncStorage.getItem(SYNC_QUEUE_KEY);
  if (!rawQueue) return;

  const queue: PendingSyncMutation[] = JSON.parse(rawQueue);
  if (queue.length === 0) return;

  const remaining: PendingSyncMutation[] = [];

  for (const item of queue) {
    try {
      await backendUpdateFn(item.houseId, item.status);
    } catch (e) {
      remaining.push(item);
    }
  }

  await AsyncStorage.setItem(SYNC_QUEUE_KEY, JSON.stringify(remaining));
}
