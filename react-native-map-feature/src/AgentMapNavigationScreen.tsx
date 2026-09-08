import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  SafeAreaView,
  Alert,
} from 'react-native';
import MapView, { Marker, Callout, PROVIDER_GOOGLE } from 'react-native-maps';
import NetInfo from '@react-native-community/netinfo';

import { HouseRecord, CollectionStatus } from './types';
import { useAgentLocation } from './hooks/useAgentLocation';
import { ensureHousesGeocoded } from './utils/geocoding';
import { sortHousesByNearestNeighbor, getDistanceMeters } from './utils/routeOptimizer';
import { openTurnByTurnNavigation } from './utils/navigationLauncher';
import {
  cacheHousesLocally,
  getCachedHouses,
  queueStatusUpdate,
  flushSyncQueue,
} from './utils/offlineSync';

interface AgentMapScreenProps {
  fetchHouseListApi: () => Promise<HouseRecord[]>;
  updateHouseStatusApi: (houseId: string, status: CollectionStatus) => Promise<void>;
}

export default function AgentMapNavigationScreen({
  fetchHouseListApi,
  updateHouseStatusApi,
}: AgentMapScreenProps) {
  const mapRef = useRef<MapView | null>(null);
  const { location: agentLocation, loading: locationLoading } = useAgentLocation();

  const [houses, setHouses] = useState<HouseRecord[]>([]);
  const [selectedHouseId, setSelectedHouseId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // 1. Initial Load & Offline Cache Strategy
  useEffect(() => {
    let isMounted = true;

    const loadData = async () => {
      try {
        let rawList: HouseRecord[] | null = null;
        const netState = await NetInfo.fetch();

        if (netState.isConnected) {
          rawList = await fetchHouseListApi();
          // Flush any pending offline sync queue
          await flushSyncQueue(updateHouseStatusApi);
        } else {
          rawList = await getCachedHouses();
        }

        if (!rawList) rawList = [];

        // Ensure all records have lat/lng
        const geocoded = await ensureHousesGeocoded(rawList);
        await cacheHousesLocally(geocoded);

        if (isMounted) {
          setHouses(geocoded);
          setLoading(false);
        }
      } catch (e) {
        console.warn('[Map Feature] Error loading house list:', e);
        const cached = await getCachedHouses();
        if (isMounted && cached) setHouses(cached);
        if (isMounted) setLoading(false);
      }
    };

    loadData();
    return () => { isMounted = false; };
  }, []);

  // 2. Compute Ordered Route using Nearest-Neighbor algorithm
  const orderedHouses = useMemo(() => {
    if (!agentLocation || houses.length === 0) return houses;
    return sortHousesByNearestNeighbor(agentLocation, houses);
  }, [agentLocation, houses]);

  const pendingQueue = useMemo(
    () => orderedHouses.filter(h => h.collection_status === 'pending'),
    [orderedHouses]
  );

  const nextHouse = pendingQueue[0] || null;

  // Auto-center map on next target when selection changes
  useEffect(() => {
    const target = houses.find(h => h.id === selectedHouseId) || nextHouse;
    if (target && target.lat && target.lng && mapRef.current) {
      mapRef.current.animateToRegion({
        latitude: target.lat,
        longitude: target.lng,
        latitudeDelta: 0.015,
        longitudeDelta: 0.015,
      }, 800);
    }
  }, [selectedHouseId, nextHouse]);

  // 3. Action Handlers
  const handleUpdateStatus = async (houseId: string, newStatus: CollectionStatus) => {
    // Optimistic UI Update
    const updated = houses.map(h =>
      h.id === houseId ? { ...h, collection_status: newStatus } : h
    );
    setHouses(updated);
    await cacheHousesLocally(updated);

    // Queue API update (handles offline fallback)
    await queueStatusUpdate(houseId, newStatus, updateHouseStatusApi);

    // Auto-select next pending house
    const remainingPending = updated.filter(h => h.collection_status === 'pending');
    if (remainingPending.length > 0) {
      setSelectedHouseId(remainingPending[0].id);
    } else {
      setSelectedHouseId(null);
      Alert.alert('Route Complete', 'All collection stops finished for today!');
    }
  };

  const handleStartNavigation = (house: HouseRecord) => {
    if (!house.lat || !house.lng) {
      Alert.alert('Invalid Location', 'Coordinates not available for this house.');
      return;
    }
    openTurnByTurnNavigation(house.lat, house.lng, house.name);
  };

  if (loading || locationLoading) {
    return (
      <View style={styles.centeredContainer}>
        <ActivityIndicator size="large" color="#2563eb" />
        <Text style={styles.loadingText}>Loading collection route &amp; map...</Text>
      </View>
    );
  }

  const initialRegion = agentLocation
    ? {
        latitude: agentLocation.latitude,
        longitude: agentLocation.longitude,
        latitudeDelta: 0.02,
        longitudeDelta: 0.02,
      }
    : {
        latitude: 12.9716,
        longitude: 77.5946,
        latitudeDelta: 0.05,
        longitudeDelta: 0.05,
      };

  return (
    <SafeAreaView style={styles.container}>
      {/* Interactive Map */}
      <View style={styles.mapContainer}>
        <MapView
          ref={mapRef}
          provider={PROVIDER_GOOGLE}
          style={styles.map}
          initialRegion={initialRegion}
          showsUserLocation
          showsMyLocationButton
        >
          {houses.map((house) => {
            if (!house.lat || !house.lng) return null;

            const isPending = house.collection_status === 'pending';
            const isCollected = house.collection_status === 'collected';

            const pinColor = isCollected ? '#22c55e' : isPending ? '#ef4444' : '#94a3b8';

            return (
              <Marker
                key={house.id}
                coordinate={{ latitude: house.lat, longitude: house.lng }}
                pinColor={pinColor}
                onPress={() => setSelectedHouseId(house.id)}
              >
                <Callout onPress={() => handleStartNavigation(house)}>
                  <View style={styles.calloutContainer}>
                    <Text style={styles.calloutTitle}>{house.name}</Text>
                    <Text style={styles.calloutSub}>{house.address}</Text>
                    <Text style={styles.calloutAmount}>Due: ₹{house.amount_due}</Text>
                    <View style={styles.calloutNavBtn}>
                      <Text style={styles.calloutNavText}>🧭 Navigate</Text>
                    </View>
                  </View>
                </Callout>
              </Marker>
            );
          })}
        </MapView>

        {/* Quick Action Floating Bar for Current Target */}
        {nextHouse && (
          <View style={styles.floatingNavCard}>
            <View style={styles.navCardHeader}>
              <View style={styles.targetBadge}>
                <Text style={styles.targetBadgeText}>⭐ NEXT STOP</Text>
              </View>
              {agentLocation && nextHouse.lat && nextHouse.lng && (
                <Text style={styles.distanceText}>
                  {(
                    getDistanceMeters(
                      agentLocation.latitude,
                      agentLocation.longitude,
                      nextHouse.lat,
                      nextHouse.lng
                    ) / 1000
                  ).toFixed(1)}{' '}
                  km away
                </Text>
              )}
            </View>

            <Text style={styles.navCardName}>{nextHouse.name}</Text>
            <Text style={styles.navCardAddress} numberOfLines={1}>{nextHouse.address}</Text>

            <View style={styles.actionRow}>
              <TouchableOpacity
                style={styles.navPrimaryBtn}
                onPress={() => handleStartNavigation(nextHouse)}
              >
                <Text style={styles.btnTextWhite}>🧭 Navigate</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.actionBtn, styles.collectBtn]}
                onPress={() => handleUpdateStatus(nextHouse.id, 'collected')}
              >
                <Text style={styles.btnTextWhite}>✓ Collected</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.actionBtn, styles.skipBtn]}
                onPress={() => handleUpdateStatus(nextHouse.id, 'skipped')}
              >
                <Text style={styles.btnTextDark}>⏭ Skip</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>

      {/* Numbered Route Queue List */}
      <View style={styles.queueContainer}>
        <Text style={styles.queueHeader}>
          📍 Route Queue ({pendingQueue.length} Pending)
        </Text>
        <FlatList
          data={orderedHouses}
          keyExtractor={(item) => item.id}
          renderItem={({ item, index }) => {
            const isPending = item.collection_status === 'pending';
            const isCollected = item.collection_status === 'collected';
            const isSelected = item.id === (selectedHouseId || nextHouse?.id);

            return (
              <TouchableOpacity
                style={[
                  styles.queueItem,
                  isSelected && styles.queueItemSelected,
                  !isPending && styles.queueItemInactive,
                ]}
                onPress={() => setSelectedHouseId(item.id)}
              >
                <View style={styles.queueIndexBadge}>
                  <Text style={styles.queueIndexText}>#{index + 1}</Text>
                </View>

                <View style={styles.queueInfo}>
                  <Text style={styles.queueName}>{item.name}</Text>
                  <Text style={styles.queueSub} numberOfLines={1}>{item.address}</Text>
                </View>

                <View style={styles.queueRight}>
                  <Text style={styles.queueAmount}>₹{item.amount_due}</Text>
                  <Text
                    style={[
                      styles.statusBadge,
                      isCollected ? styles.statusCollected : isPending ? styles.statusPending : styles.statusSkipped,
                    ]}
                  >
                    {item.collection_status.toUpperCase()}
                  </Text>
                </View>
              </TouchableOpacity>
            );
          }}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f8fafc' },
  centeredContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  loadingText: { marginTop: 12, fontSize: 14, color: '#64748b' },
  mapContainer: { flex: 1.2, position: 'relative' },
  map: { width: '100%', height: '100%' },
  
  // Callout
  calloutContainer: { width: 160, padding: 4 },
  calloutTitle: { fontWeight: 'bold', fontSize: 13, color: '#0f172a' },
  calloutSub: { fontSize: 10, color: '#64748b', marginVertical: 2 },
  calloutAmount: { fontSize: 11, fontWeight: 'bold', color: '#16a34a' },
  calloutNavBtn: { marginTop: 6, backgroundColor: '#2563eb', padding: 4, borderRadius: 4, alignItems: 'center' },
  calloutNavText: { color: '#fff', fontSize: 10, fontWeight: 'bold' },

  // Floating Nav Card
  floatingNavCard: {
    position: 'absolute',
    bottom: 12,
    left: 12,
    right: 12,
    backgroundColor: '#ffffff',
    borderRadius: 16,
    padding: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 10,
    elevation: 6,
  },
  navCardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  targetBadge: { backgroundColor: '#dbeafe', paddingHorizontal: 8, paddingVertical: 2, borderRadius: 100 },
  targetBadgeText: { color: '#2563eb', fontSize: 10, fontWeight: 'bold' },
  distanceText: { fontSize: 11, fontWeight: '600', color: '#64748b' },
  navCardName: { fontSize: 16, fontWeight: 'bold', color: '#0f172a', marginTop: 4 },
  navCardAddress: { fontSize: 12, color: '#64748b', marginBottom: 10 },
  actionRow: { flexDirection: 'row', gap: 8 },
  navPrimaryBtn: { flex: 1.2, backgroundColor: '#2563eb', paddingVertical: 10, borderRadius: 10, alignItems: 'center' },
  actionBtn: { flex: 1, paddingVertical: 10, borderRadius: 10, alignItems: 'center' },
  collectBtn: { backgroundColor: '#16a34a' },
  skipBtn: { backgroundColor: '#e2e8f0' },
  btnTextWhite: { color: '#ffffff', fontWeight: 'bold', fontSize: 12 },
  btnTextDark: { color: '#334155', fontWeight: 'bold', fontSize: 12 },

  // Queue List
  queueContainer: { flex: 0.8, backgroundColor: '#ffffff', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: 16 },
  queueHeader: { fontSize: 14, fontWeight: 'bold', color: '#0f172a', marginBottom: 10 },
  queueItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, paddingHorizontal: 12, borderRadius: 12, marginBottom: 8, backgroundColor: '#f8fafc', borderWidth: 1, borderColor: '#e2e8f0' },
  queueItemSelected: { borderColor: '#2563eb', backgroundColor: '#eff6ff' },
  queueItemInactive: { opacity: 0.6 },
  queueIndexBadge: { width: 28, height: 28, borderRadius: 8, backgroundColor: '#e2e8f0', justifyContent: 'center', alignItems: 'center', marginRight: 10 },
  queueIndexText: { fontWeight: 'bold', fontSize: 11, color: '#334155' },
  queueInfo: { flex: 1 },
  queueName: { fontWeight: 'bold', fontSize: 13, color: '#0f172a' },
  queueSub: { fontSize: 11, color: '#64748b' },
  queueRight: { alignItems: 'flex-end' },
  queueAmount: { fontWeight: 'bold', fontSize: 13, color: '#0f172a' },
  statusBadge: { fontSize: 9, fontWeight: 'bold', marginTop: 2 },
  statusCollected: { color: '#16a34a' },
  statusPending: { color: '#ef4444' },
  statusSkipped: { color: '#64748b' },
});
