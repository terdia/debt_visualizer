import React, { useEffect, useState } from 'react';
import { ScrollView, StyleSheet, View, SafeAreaView, useWindowDimensions } from 'react-native';
import DebtInput, { DebtInputData } from '../../components/DebtInput';
import { useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useAppColors } from '../../utils/colors';

const FORM_DATA_KEY = 'debtInputForm';

export default function InputScreen() {
  const { width } = useWindowDimensions();
  const router = useRouter();
  const colors = useAppColors();
  const [initialFormData, setInitialFormData] = useState<Partial<DebtInputData> | null>(null);

  useEffect(() => {
    loadFormData();
  }, []);

  const loadFormData = async () => {
    try {
      const savedForm = await AsyncStorage.getItem(FORM_DATA_KEY);
      if (savedForm) {
        setInitialFormData(JSON.parse(savedForm));
      }
    } catch (error) {
      console.error('Error loading form data:', error);
    }
  };

  const handleCalculate = async (data: DebtInputData) => {
    try {
      // Save form data
      await AsyncStorage.setItem(FORM_DATA_KEY, JSON.stringify(data));
      
      // Store the calculation data and timestamp
      const calculationData = {
        ...data,
        timestamp: new Date().toISOString(),
      };
      await AsyncStorage.setItem('debtCalculation', JSON.stringify(calculationData));
      
      // Navigate back to dashboard
      router.push('/');
    } catch (error) {
      console.error('Error saving data:', error);
    }
  };

  const handleClearForm = async () => {
    try {
      await AsyncStorage.removeItem(FORM_DATA_KEY);
      setInitialFormData(null);
    } catch (error) {
      console.error('Error clearing form data:', error);
    }
  };

  return (
    <SafeAreaView style={[styles.safeArea, { backgroundColor: colors.background }]}>
      <ScrollView 
        style={[styles.container, { backgroundColor: colors.background }]}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}>
        <View style={[styles.content, { maxWidth: Math.min(width, 600) }]}>
          <DebtInput 
            onCalculate={handleCalculate} 
            onClearForm={handleClearForm}
            initialData={initialFormData}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#f1f5f9',
  },
  container: {
    flex: 1,
    backgroundColor: '#f1f5f9',
  },
  scrollContent: {
    flexGrow: 1,
    alignItems: 'center',
  },
  content: {
    width: '100%',
    padding: 20,
  },
});