import { Linking, Platform } from 'react-native';

export async function openTurnByTurnNavigation(lat: number, lng: number, label?: string) {
  const destination = `${lat},${lng}`;
  const encodedLabel = encodeURIComponent(label || 'Customer Stop');

  if (Platform.OS === 'android') {
    const googleNavUrl = `google.navigation:q=${destination}&mode=d`;
    const supported = await Linking.canOpenURL(googleNavUrl);
    
    if (supported) {
      await Linking.openURL(googleNavUrl);
    } else {
      await Linking.openURL(`https://www.google.com/maps/dir/?api=1&destination=${destination}`);
    }
  } else {
    // iOS
    const googleMapsScheme = `comgooglemaps://?daddr=${destination}&directionsmode=driving`;
    const canOpenGoogle = await Linking.canOpenURL('comgooglemaps://');

    if (canOpenGoogle) {
      await Linking.openURL(googleMapsScheme);
    } else {
      // Fallback to Apple Maps
      const appleMapsUrl = `maps://app?daddr=${destination}&q=${encodedLabel}`;
      await Linking.openURL(appleMapsUrl);
    }
  }
}
