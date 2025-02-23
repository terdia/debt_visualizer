import React, { useState, useEffect } from 'react';
import { ScrollView, StyleSheet, View, SafeAreaView, useWindowDimensions, Text, TouchableOpacity, Platform } from 'react-native';
import DebtVisualization from '../../components/DebtVisualization';
import DebtProfileList from '../../components/DebtProfileList';
import DebtProfileModal from '../../components/DebtProfileModal';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useFocusEffect } from '@react-navigation/native';
import { useAppColors } from '../../utils/colors';
import { BlurView } from 'expo-blur';
import { DebtProfile } from '../../types/debt';
import {
  getDebtProfiles,
  getActiveProfile,
  setActiveProfile,
  saveDebtProfile,
  updateDebtProfile,
  deleteDebtProfile,
} from '../../utils/storage';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

const AnimatedTouchableOpacity = Animated.createAnimatedComponent(TouchableOpacity);

export default function DashboardScreen() {
  const [profiles, setProfiles] = useState<DebtProfile[]>([]);
  const [activeProfileId, setActiveProfileId] = useState<string | null>(null);
  const [modalVisible, setModalVisible] = useState(false);
  const [editingProfile, setEditingProfile] = useState<DebtProfile | undefined>();
  const { width } = useWindowDimensions();
  const router = useRouter();
  const colors = useAppColors();
  const clearScale = useSharedValue(1);
  const clearOpacity = useSharedValue(1);

  const loadProfiles = async () => {
    const loadedProfiles = await getDebtProfiles();
    setProfiles(loadedProfiles);
    
    const activeId = await getActiveProfile();
    setActiveProfileId(activeId);
  };

  useEffect(() => {
    loadProfiles();
  }, []);

  useFocusEffect(
    React.useCallback(() => {
      loadProfiles();
    }, [])
  );

  const handleSelectProfile = async (id: string) => {
    await setActiveProfile(id);
    setActiveProfileId(id);
  };

  const handleAddProfile = () => {
    setEditingProfile(undefined);
    setModalVisible(true);
  };

  const handleEditProfile = (profile: DebtProfile) => {
    setEditingProfile(profile);
    setModalVisible(true);
  };

  const handleDeleteProfile = async (id: string) => {
    await deleteDebtProfile(id);
    await loadProfiles();
  };

  const handleSaveProfile = async (profileData: Omit<DebtProfile, 'id' | 'createdAt' | 'updatedAt'>) => {
    if (editingProfile) {
      await updateDebtProfile(editingProfile.id, profileData);
    } else {
      await saveDebtProfile(profileData);
    }
    await loadProfiles();
  };

  const activeProfile = profiles.find(p => p.id === activeProfileId);

  return (
    <SafeAreaView style={[styles.safeArea, { backgroundColor: colors.background }]}>
      <ScrollView 
        style={[styles.container, { backgroundColor: colors.background }]}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}>
        <View style={[styles.content, { maxWidth: Math.min(width, 600) }]}>
          <View style={styles.header}>
            <Text style={[styles.title, { color: colors.text }]}>Debt Profiles</Text>
            <TouchableOpacity
              style={[styles.addButton, { backgroundColor: colors.primary + '15' }]}
              onPress={handleAddProfile}>
              <Ionicons name="add" size={24} color={colors.primary} />
            </TouchableOpacity>
          </View>

          <DebtProfileList
            profiles={profiles}
            activeProfileId={activeProfileId}
            onSelectProfile={handleSelectProfile}
            onEditProfile={handleEditProfile}
            onDeleteProfile={handleDeleteProfile}
          />

          {activeProfile ? (
            <DebtVisualization data={activeProfile} />
          ) : (
            <View style={[styles.emptyContainer, { backgroundColor: colors.cardBackground }]}>
              <Ionicons name="calculator-outline" size={64} color={colors.textSecondary} />
              <Text style={[styles.emptyTitle, { color: colors.text }]}>No Active Profile</Text>
              <Text style={[styles.emptyText, { color: colors.textSecondary }]}>
                Select a debt profile or create a new one to see your payoff timeline and statistics.
              </Text>
              <TouchableOpacity
                style={[styles.startButton, { backgroundColor: colors.primary }]}
                onPress={handleAddProfile}>
                <Text style={styles.startButtonText}>Create Profile</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </ScrollView>

      <DebtProfileModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
        onSave={handleSaveProfile}
        initialData={editingProfile}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  container: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    alignItems: 'center',
  },
  content: {
    width: '100%',
    padding: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
  },
  addButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyContainer: {
    padding: 32,
    borderRadius: 16,
    alignItems: 'center',
    marginTop: 16,
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: '600',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 24,
  },
  startButton: {
    height: 50,
    borderRadius: 25,
    width: '100%',
    maxWidth: 300,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
    overflow: Platform.OS === 'ios' ? 'hidden' : 'visible',
  },
  startButtonText: {
    color: 'white',
    fontSize: 17,
    fontWeight: '600',
    letterSpacing: 0.5,
  },
});