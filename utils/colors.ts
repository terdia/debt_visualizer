import { useColorScheme } from 'react-native';

export function useAppColors() {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  return {
    isDark,
    // Background colors
    background: isDark ? '#0f172a' : '#f1f5f9',
    cardBackground: isDark ? '#1e293b' : '#ffffff',
    inputBackground: isDark ? '#334155' : '#f8fafc',
    
    // Text colors
    text: isDark ? '#f1f5f9' : '#1e293b',
    textSecondary: isDark ? '#94a3b8' : '#64748b',
    textTertiary: isDark ? '#64748b' : '#94a3b8',
    
    // Border colors
    border: isDark ? '#334155' : '#e2e8f0',
    inputBorder: isDark ? '#475569' : '#cbd5e1',
    
    // Button colors
    primary: isDark ? '#2563eb' : '#007AFF',
    primaryPressed: isDark ? '#1d4ed8' : '#0056B3',
    danger: isDark ? '#ef4444' : '#FF3B30',
    dangerPressed: isDark ? '#dc2626' : '#D70015',
    
    // Chart colors
    chartBackground: isDark ? '#1e293b' : '#ffffff',
    chartGrid: isDark ? '#334155' : '#e2e8f0',
    chartText: isDark ? '#94a3b8' : '#64748b',
    chartLine: isDark ? '#60a5fa' : '#2563eb',
  };
}