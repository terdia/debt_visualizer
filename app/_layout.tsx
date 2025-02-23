import React from 'react';
import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useColorScheme } from 'react-native';
import { useAppColors } from '../utils/colors';
import { NavigationContainer } from '@react-navigation/native';

declare global {
  interface Window {
    frameworkReady?: () => void;
  }
}

export default function RootLayout() {
  const colorScheme = useColorScheme();
  const colors = useAppColors();

  useEffect(() => {
    window.frameworkReady?.();
  }, []);

  return (
    <NavigationContainer>
      <Stack 
        screenOptions={{ 
          headerShown: false,
          contentStyle: { backgroundColor: colors.background }
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack>
      <StatusBar style={colorScheme === 'dark' ? 'light' : 'dark'} />
    </NavigationContainer>
  );
}