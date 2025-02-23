import AsyncStorage from '@react-native-async-storage/async-storage';
import { DebtProfile, DebtProfileInput } from '../types/debt';

const PROFILES_KEY = 'debtProfiles';
const ACTIVE_PROFILE_KEY = 'activeDebtProfile';

export async function saveDebtProfile(profile: DebtProfileInput): Promise<DebtProfile> {
  try {
    const profiles = await getDebtProfiles();
    
    const newProfile: DebtProfile = {
      ...profile,
      id: Math.random().toString(36).substr(2, 9),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await AsyncStorage.setItem(PROFILES_KEY, JSON.stringify([...profiles, newProfile]));
    
    // If this is the first profile, make it active
    if (profiles.length === 0) {
      await setActiveProfile(newProfile.id);
    }

    return newProfile;
  } catch (error) {
    console.error('Error saving debt profile:', error);
    throw error;
  }
}

export async function updateDebtProfile(id: string, updates: Partial<DebtProfileInput>): Promise<DebtProfile> {
  try {
    const profiles = await getDebtProfiles();
    const index = profiles.findIndex(p => p.id === id);
    
    if (index === -1) {
      throw new Error('Profile not found');
    }

    const updatedProfile: DebtProfile = {
      ...profiles[index],
      ...updates,
      updatedAt: new Date().toISOString(),
    };

    profiles[index] = updatedProfile;
    await AsyncStorage.setItem(PROFILES_KEY, JSON.stringify(profiles));

    return updatedProfile;
  } catch (error) {
    console.error('Error updating debt profile:', error);
    throw error;
  }
}

export async function deleteDebtProfile(id: string): Promise<void> {
  try {
    const profiles = await getDebtProfiles();
    const filteredProfiles = profiles.filter(p => p.id !== id);
    await AsyncStorage.setItem(PROFILES_KEY, JSON.stringify(filteredProfiles));

    // If active profile was deleted, set a new active profile
    const activeId = await getActiveProfile();
    if (activeId === id && filteredProfiles.length > 0) {
      await setActiveProfile(filteredProfiles[0].id);
    }
  } catch (error) {
    console.error('Error deleting debt profile:', error);
    throw error;
  }
}

export async function getDebtProfiles(): Promise<DebtProfile[]> {
  try {
    const profilesJson = await AsyncStorage.getItem(PROFILES_KEY);
    return profilesJson ? JSON.parse(profilesJson) : [];
  } catch (error) {
    console.error('Error getting debt profiles:', error);
    return [];
  }
}

export async function getDebtProfile(id: string): Promise<DebtProfile | null> {
  try {
    const profiles = await getDebtProfiles();
    return profiles.find(p => p.id === id) || null;
  } catch (error) {
    console.error('Error getting debt profile:', error);
    return null;
  }
}

export async function setActiveProfile(id: string): Promise<void> {
  try {
    await AsyncStorage.setItem(ACTIVE_PROFILE_KEY, id);
  } catch (error) {
    console.error('Error setting active profile:', error);
    throw error;
  }
}

export async function getActiveProfile(): Promise<string | null> {
  try {
    return await AsyncStorage.getItem(ACTIVE_PROFILE_KEY);
  } catch (error) {
    console.error('Error getting active profile:', error);
    return null;
  }
}