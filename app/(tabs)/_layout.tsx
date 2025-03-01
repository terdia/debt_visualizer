import React from 'react';
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Platform, useColorScheme, View } from 'react-native';
import { useAppColors } from '../../utils/colors';

export default function TabLayout() {
  const colorScheme = useColorScheme();
  const colors = useAppColors();
  const isDark = colorScheme === 'dark';

  return (
    <View style={{ flex: 1 }}>
      <Tabs
        screenOptions={{
          tabBarActiveTintColor: colors.primary,
          tabBarInactiveTintColor: colors.textSecondary,
          headerShown: false,
          tabBarStyle: {
            ...Platform.select({
              ios: {
                paddingBottom: 0,
              },
              android: {
                paddingBottom: 4,
              },
            }),
            backgroundColor: colors.cardBackground,
            borderTopColor: colors.border,
          },
        }}>
        <Tabs.Screen
          name="index"
          options={{
            title: 'Dashboard',
            tabBarIcon: ({ focused, color, size }) => (
              <Ionicons 
                name={focused ? 'pie-chart' : 'pie-chart-outline'}
                size={size} 
                color={color} 
              />
            ),
          }}
        />
        <Tabs.Screen
          name="education"
          options={{
            title: 'Learn',
            tabBarIcon: ({ focused, color, size }) => (
              <Ionicons 
                name={focused ? 'book' : 'book-outline'}
                size={size} 
                color={color} 
              />
            ),
          }}
        />
      </Tabs>
    </View>
  );
}