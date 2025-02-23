import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAppColors } from '../utils/colors';
import { DebtProfile } from '../types/debt';
import { BlurView } from 'expo-blur';

interface DebtProfileListProps {
  profiles: DebtProfile[];
  activeProfileId: string | null;
  onSelectProfile: (id: string) => void;
  onEditProfile: (profile: DebtProfile) => void;
  onDeleteProfile: (id: string) => void;
}

export default function DebtProfileList({
  profiles,
  activeProfileId,
  onSelectProfile,
  onEditProfile,
  onDeleteProfile,
}: DebtProfileListProps) {
  const colors = useAppColors();

  const formatCurrency = (amount: number, currency: DebtProfile['currency']) => {
    if (!currency?.code || currency.code === 'None') {
      return amount.toLocaleString();
    }
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency.code,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.container}>
      {profiles.map((profile) => (
        <TouchableOpacity
          key={profile.id}
          style={[
            styles.card,
            {
              backgroundColor: colors.cardBackground,
              borderColor: profile.id === activeProfileId ? colors.primary : colors.border,
            },
          ]}
          onPress={() => onSelectProfile(profile.id)}>
          {Platform.OS === 'ios' && profile.id === activeProfileId && (
            <BlurView
              intensity={20}
              style={[StyleSheet.absoluteFill, styles.blur]}
              tint={colors.isDark ? 'dark' : 'light'}
            />
          )}
          
          <View style={styles.header}>
            <Text style={[styles.name, { color: colors.text }]}>{profile.name}</Text>
            <View style={styles.actions}>
              <TouchableOpacity
                style={[styles.actionButton, { backgroundColor: colors.primary + '15' }]}
                onPress={() => onEditProfile(profile)}>
                <Ionicons name="pencil" size={16} color={colors.primary} />
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.actionButton, { backgroundColor: colors.danger + '15' }]}
                onPress={() => onDeleteProfile(profile.id)}>
                <Ionicons name="trash" size={16} color={colors.danger} />
              </TouchableOpacity>
            </View>
          </View>

          <Text 
            style={[styles.description, { color: colors.textSecondary }]}
            numberOfLines={2}>
            {profile.description}
          </Text>

          <View style={styles.stats}>
            <View style={styles.stat}>
              <Text style={[styles.statLabel, { color: colors.textSecondary }]}>
                Total Debt
              </Text>
              <Text style={[styles.statValue, { color: colors.text }]}>
                {formatCurrency(profile.totalDebt, profile.currency)}
              </Text>
            </View>
            <View style={styles.stat}>
              <Text style={[styles.statLabel, { color: colors.textSecondary }]}>
                Paid
              </Text>
              <Text style={[styles.statValue, { color: colors.text }]}>
                {formatCurrency(profile.amountPaid, profile.currency)}
              </Text>
            </View>
          </View>

          <View style={[styles.progressBar, { backgroundColor: colors.border }]}>
            <View 
              style={[
                styles.progressFill,
                { 
                  width: `${(profile.amountPaid / profile.totalDebt) * 100}%`,
                  backgroundColor: colors.primary,
                }
              ]} 
            />
          </View>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 16,
    gap: 16,
  },
  card: {
    width: 280,
    borderRadius: 16,
    padding: 16,
    borderWidth: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
    overflow: Platform.OS === 'ios' ? 'hidden' : 'visible',
  },
  blur: {
    borderRadius: 14,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  name: {
    fontSize: 18,
    fontWeight: '600',
    flex: 1,
    marginRight: 8,
  },
  actions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  description: {
    fontSize: 14,
    marginBottom: 16,
  },
  stats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  stat: {
    flex: 1,
  },
  statLabel: {
    fontSize: 12,
    marginBottom: 4,
  },
  statValue: {
    fontSize: 16,
    fontWeight: '600',
  },
  progressBar: {
    height: 4,
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 2,
  },
});