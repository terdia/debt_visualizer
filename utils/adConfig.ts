import { Platform } from 'react-native';

// Test ad unit IDs for development
const TEST_ADS = {
  appId: Platform.select({
    ios: 'ca-app-pub-3940256099942544~1458002511',
    android: 'ca-app-pub-3940256099942544~3347511713',
    default: 'ca-app-pub-3940256099942544~3347511713',
  }),
  banner: Platform.select({
    ios: 'ca-app-pub-3940256099942544/2934735716',
    android: 'ca-app-pub-3940256099942544/6300978111',
    default: 'ca-app-pub-3940256099942544/6300978111',
  }),
  interstitial: Platform.select({
    ios: 'ca-app-pub-3940256099942544/4411468910',
    android: 'ca-app-pub-3940256099942544/1033173712',
    default: 'ca-app-pub-3940256099942544/1033173712',
  }),
  rewarded: Platform.select({
    ios: 'ca-app-pub-3940256099942544/1712485313',
    android: 'ca-app-pub-3940256099942544/5224354917',
    default: 'ca-app-pub-3940256099942544/5224354917',
  }),
  appOpen: Platform.select({
    ios: 'ca-app-pub-3940256099942544/5575463023',
    android: 'ca-app-pub-3940256099942544/3419835294',
    default: 'ca-app-pub-3940256099942544/3419835294',
  }),
  native: Platform.select({
    ios: 'ca-app-pub-3940256099942544/3986624511',
    android: 'ca-app-pub-3940256099942544/2247696110',
    default: 'ca-app-pub-3940256099942544/2247696110',
  }),
};

// Production ad unit IDs
const PRODUCTION_ADS = {
  appId: Platform.select({
    ios: 'ca-app-pub-6615281019642096~6264061999',
    android: 'ca-app-pub-6615281019642096~6264061999',
    default: 'ca-app-pub-6615281019642096~6264061999',
  }),
  banner: Platform.select({
    ios: 'ca-app-pub-6615281019642096/1778022078',
    android: 'ca-app-pub-6615281019642096/1778022078',
    default: 'ca-app-pub-6615281019642096/1778022078',
  }),
  interstitial: Platform.select({
    ios: 'ca-app-pub-6615281019642096/1778022078',
    android: 'ca-app-pub-6615281019642096/1778022078',
    default: 'ca-app-pub-6615281019642096/1778022078',
  }),
  // Add other production ad units when available
  rewarded: Platform.select({
    ios: 'ca-app-pub-6615281019642096/1778022078',
    android: 'ca-app-pub-6615281019642096/1778022078',
    default: 'ca-app-pub-6615281019642096/1778022078',
  }),
};

// Use test ads in development, production ads in production
const isProduction = process.env.NODE_ENV === 'production';
export const AdUnits = isProduction ? PRODUCTION_ADS : TEST_ADS;