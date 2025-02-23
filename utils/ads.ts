import { Platform } from 'react-native';
import { AdMobInterstitial, AdMobRewarded } from 'expo-ads-admob';
import { AdUnits } from './adConfig';

const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second

async function retry<T>(
  operation: () => Promise<T>,
  retries: number = MAX_RETRIES,
  delay: number = RETRY_DELAY
): Promise<T> {
  try {
    return await operation();
  } catch (error) {
    if (retries > 0) {
      await new Promise(resolve => setTimeout(resolve, delay));
      return retry(operation, retries - 1, delay);
    }
    throw error;
  }
}

export async function showInterstitial() {
  if (Platform.OS === 'web') return;
  
  try {
    await retry(async () => {
      await AdMobInterstitial.setAdUnitID(AdUnits.interstitial);
      await AdMobInterstitial.requestAdAsync();
      await AdMobInterstitial.showAdAsync();
    });
  } catch (error) {
    console.warn('Interstitial ad error:', error);
  }
}

export async function showRewarded() {
  if (Platform.OS === 'web') return;

  try {
    await retry(async () => {
      await AdMobRewarded.setAdUnitID(AdUnits.rewarded);
      await AdMobRewarded.requestAdAsync();
      await AdMobRewarded.showAdAsync();
    });
  } catch (error) {
    console.warn('Rewarded ad error:', error);
  }
}