import React, { useState } from 'react';
import { Platform, StyleSheet, View, Text } from 'react-native';
import { AdMobBanner } from 'expo-ads-admob';
import { useAppColors } from '../utils/colors';
import { AdUnits } from '../utils/adConfig';

export default function AdBanner() {
  const colors = useAppColors();
  const [adError, setAdError] = useState<string | null>(null);

  if (Platform.OS === 'web') {
    return null;
  }

  const handleAdError = (error: string) => {
    console.warn('Ad error:', error);
    setAdError(error);
  };

  return (
    <View style={[styles.container, { backgroundColor: colors.cardBackground }]}>
      {adError ? (
        <View style={styles.errorContainer}>
          <Text style={[styles.errorText, { color: colors.textSecondary }]}>
            Ad not available
          </Text>
        </View>
      ) : (
        <AdMobBanner
          bannerSize="banner"
          adUnitID={AdUnits.banner}
          servePersonalizedAds={true}
          onDidFailToReceiveAdWithError={handleAdError}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    alignItems: 'center',
    padding: 8,
    marginBottom: Platform.select({
      ios: 83, // Height of tab bar + safe area
      android: 60, // Height of tab bar
      default: 60,
    }),
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  errorContainer: {
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    fontSize: 12,
  },
});