export type CollectionStatus = 'pending' | 'collected' | 'skipped';

export interface HouseRecord {
  id: string;
  name: string;
  address: string;
  amount_due: number;
  collection_status: CollectionStatus;
  lat?: number;
  lng?: number;
}

export interface AgentLocation {
  latitude: number;
  longitude: number;
  heading?: number | null;
}

export interface PendingSyncMutation {
  houseId: string;
  status: CollectionStatus;
  timestamp: number;
}
