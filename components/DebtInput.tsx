import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  Alert,
  Platform,
  Pressable,
  ScrollView,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  interpolateColor,
  withTiming,
  interpolate,
} from 'react-native-reanimated';
import { useAppColors } from '../utils/colors';
import { BlurView } from 'expo-blur';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

const CURRENCIES = [
  { code: 'USD', symbol: '$' },
  { code: 'EUR', symbol: '€' },
  { code: 'GBP', symbol: '£' },
  { code: 'JPY', symbol: '¥' },
  { code: 'None', symbol: '' },
];

export interface DebtInputData {
  totalDebt: number;
  interestRate: number;
  monthlyPayment: number;
  hourlyWage?: number;
  amountPaid: number;
  currency: { code: string; symbol: string };
}

interface DebtInputProps {
  onCalculate: (data: DebtInputData) => void;
  onClearForm: () => void;
  initialData?: Partial<DebtInputData> | null;
}

export default function DebtInput({ onCalculate, onClearForm, initialData }: DebtInputProps) {
  const colors = useAppColors();
  const [totalDebt, setTotalDebt] = useState('');
  const [interestRate, setInterestRate] = useState('');
  const [monthlyPayment, setMonthlyPayment] = useState('');
  const [hourlyWage, setHourlyWage] = useState('');
  const [amountPaid, setAmountPaid] = useState('');
  const [selectedCurrency, setSelectedCurrency] = useState(CURRENCIES[0]);

  // Animation values
  const calculateScale = useSharedValue(1);
  const calculateBg = useSharedValue(0);
  const resetScale = useSharedValue(1);
  const resetBg = useSharedValue(0);

  useEffect(() => {
    if (initialData) {
      setTotalDebt(initialData.totalDebt?.toString() || '');
      setInterestRate(initialData.interestRate?.toString() || '');
      setMonthlyPayment(initialData.monthlyPayment?.toString() || '');
      setHourlyWage(initialData.hourlyWage?.toString() || '');
      setAmountPaid(initialData.amountPaid?.toString() || '');
      if (initialData.currency) {
        setSelectedCurrency(initialData.currency);
      }
    }
  }, [initialData]);

  const resetForm = () => {
    setTotalDebt('');
    setInterestRate('');
    setMonthlyPayment('');
    setHourlyWage('');
    setAmountPaid('');
    setSelectedCurrency(CURRENCIES[0]);
    onClearForm();
  };

  const validateAndCalculate = () => {
    const debt = parseFloat(totalDebt);
    const rate = parseFloat(interestRate || '0');
    const payment = parseFloat(monthlyPayment);
    const wage = hourlyWage ? parseFloat(hourlyWage) : undefined;
    const paid = parseFloat(amountPaid || '0');

    if (isNaN(debt) || debt <= 0) {
      Alert.alert('Error', 'Please enter a valid debt amount');
      return;
    }

    if (isNaN(payment) || payment <= 0) {
      Alert.alert('Error', 'Please enter a valid monthly payment');
      return;
    }

    if (rate < 0 || rate > 100) {
      Alert.alert('Error', 'Interest rate must be between 0 and 100');
      return;
    }

    if (wage !== undefined && wage < 0) {
      Alert.alert('Error', 'Hourly wage must be positive');
      return;
    }

    if (paid < 0 || paid > debt) {
      Alert.alert('Error', 'Amount paid cannot be negative or exceed total debt');
      return;
    }

    const monthlyInterest = (rate / 100) / 12;
    const monthlyInterestAmount = (debt - paid) * monthlyInterest;

    if (payment <= monthlyInterestAmount) {
      Alert.alert(
        'Warning',
        'Your monthly payment is less than the interest accrued. You will never pay off this debt with the current payment.'
      );
      return;
    }

    onCalculate({
      totalDebt: debt,
      interestRate: rate,
      monthlyPayment: payment,
      amountPaid: paid,
      currency: selectedCurrency,
      ...(wage !== undefined && { hourlyWage: wage }),
    });
  };

  const calculateAnimatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: calculateScale.value }],
      backgroundColor: interpolateColor(
        calculateBg.value,
        [0, 1],
        [colors.primary, colors.primaryPressed]
      ),
    };
  });

  const resetAnimatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: resetScale.value }],
      backgroundColor: interpolateColor(
        resetBg.value,
        [0, 1],
        [colors.danger, colors.dangerPressed]
      ),
    };
  });

  const handleCalculatePressIn = () => {
    calculateScale.value = withSpring(0.98, { 
      damping: 12,
      stiffness: 200,
    });
    calculateBg.value = withTiming(1, { duration: 150 });
  };

  const handleCalculatePressOut = () => {
    calculateScale.value = withSpring(1, { 
      damping: 12,
      stiffness: 200,
    });
    calculateBg.value = withTiming(0, { duration: 200 });
  };

  const handleResetPressIn = () => {
    resetScale.value = withSpring(0.98, { 
      damping: 12,
      stiffness: 200,
    });
    resetBg.value = withTiming(1, { duration: 150 });
  };

  const handleResetPressOut = () => {
    resetScale.value = withSpring(1, { 
      damping: 12,
      stiffness: 200,
    });
    resetBg.value = withTiming(0, { duration: 200 });
  };

  return (
    <View style={[styles.container, { backgroundColor: colors.cardBackground }]}>
      <Text style={[styles.title, { color: colors.text }]}>Enter Your Debt Details</Text>

      <View style={styles.currencySection}>
        <Text style={[styles.label, { color: colors.text }]}>Select Currency</Text>
        <ScrollView 
          horizontal 
          showsHorizontalScrollIndicator={false}
          style={styles.currencyScroll}
          contentContainerStyle={styles.currencyContainer}>
          {CURRENCIES.map((currency) => (
            <Pressable
              key={currency.code}
              style={[
                styles.currencyButton,
                { backgroundColor: colors.inputBackground },
                selectedCurrency.code === currency.code && { backgroundColor: colors.primary },
              ]}
              onPress={() => setSelectedCurrency(currency)}>
              <Text style={[
                styles.currencyButtonText,
                { color: colors.textSecondary },
                selectedCurrency.code === currency.code && { color: 'white' },
              ]}>
                {currency.code} {currency.symbol}
              </Text>
            </Pressable>
          ))}
        </ScrollView>
      </View>
      
      <View style={styles.requiredSection}>
        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.text }]}>
            Total Debt {selectedCurrency.symbol} <Text style={styles.required}>*</Text>
          </Text>
          <TextInput
            style={[styles.input, { 
              backgroundColor: colors.inputBackground,
              borderColor: colors.inputBorder,
              color: colors.text,
            }]}
            keyboardType="numeric"
            value={totalDebt}
            onChangeText={setTotalDebt}
            placeholder={`e.g., 10000`}
            placeholderTextColor={colors.textTertiary}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.text }]}>
            Monthly Payment {selectedCurrency.symbol} <Text style={styles.required}>*</Text>
          </Text>
          <TextInput
            style={[styles.input, { 
              backgroundColor: colors.inputBackground,
              borderColor: colors.inputBorder,
              color: colors.text,
            }]}
            keyboardType="numeric"
            value={monthlyPayment}
            onChangeText={setMonthlyPayment}
            placeholder={`e.g., 500`}
            placeholderTextColor={colors.textTertiary}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.text }]}>Interest Rate (% APR)</Text>
          <TextInput
            style={[styles.input, { 
              backgroundColor: colors.inputBackground,
              borderColor: colors.inputBorder,
              color: colors.text,
            }]}
            keyboardType="numeric"
            value={interestRate}
            onChangeText={setInterestRate}
            placeholder="e.g., 5"
            placeholderTextColor={colors.textTertiary}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.text }]}>Amount Paid So Far {selectedCurrency.symbol}</Text>
          <TextInput
            style={[styles.input, { 
              backgroundColor: colors.inputBackground,
              borderColor: colors.inputBorder,
              color: colors.text,
            }]}
            keyboardType="numeric"
            value={amountPaid}
            onChangeText={setAmountPaid}
            placeholder={`e.g., 2000`}
            placeholderTextColor={colors.textTertiary}
          />
          <Text style={[styles.hint, { color: colors.textTertiary }]}>
            Track your progress by updating this amount as you pay off your debt
          </Text>
        </View>
      </View>

      <View style={styles.optionalSection}>
        <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>Optional Information</Text>
        <View style={styles.inputGroup}>
          <Text style={[styles.label, { color: colors.text }]}>Hourly Wage {selectedCurrency.symbol}</Text>
          <TextInput
            style={[styles.input, { 
              backgroundColor: colors.inputBackground,
              borderColor: colors.inputBorder,
              color: colors.text,
            }]}
            keyboardType="numeric"
            value={hourlyWage}
            onChangeText={setHourlyWage}
            placeholder={`e.g., 15`}
            placeholderTextColor={colors.textTertiary}
          />
          <Text style={[styles.hint, { color: colors.textTertiary }]}>
            Add your hourly wage to see how many work hours are needed to pay off the debt
          </Text>
        </View>
      </View>

      <View style={styles.buttonContainer}>
        <AnimatedPressable
          onPressIn={handleResetPressIn}
          onPressOut={handleResetPressOut}
          onPress={resetForm}
          style={[
            styles.button,
            {
              backgroundColor: colors.danger,
              shadowColor: colors.danger,
            },
            resetAnimatedStyle
          ]}>
          {Platform.OS === 'ios' && (
            <BlurView
              intensity={20}
              style={StyleSheet.absoluteFill}
              tint={colors.isDark ? 'dark' : 'light'}
            />
          )}
          <Text style={styles.buttonText}>Reset</Text>
        </AnimatedPressable>

        <AnimatedPressable
          onPressIn={handleCalculatePressIn}
          onPressOut={handleCalculatePressOut}
          onPress={validateAndCalculate}
          style={[
            styles.button,
            {
              backgroundColor: colors.primary,
              shadowColor: colors.primary,
            },
            calculateAnimatedStyle
          ]}>
          {Platform.OS === 'ios' && (
            <BlurView
              intensity={20}
              style={StyleSheet.absoluteFill}
              tint={colors.isDark ? 'dark' : 'light'}
            />
          )}
          <Text style={styles.buttonText}>Calculate</Text>
        </AnimatedPressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 20,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  title: {
    fontSize: 24,
    fontWeight: '600',
    marginBottom: 20,
  },
  currencySection: {
    marginBottom: 24,
  },
  currencyScroll: {
    marginTop: 8,
  },
  currencyContainer: {
    gap: 8,
    paddingVertical: 4,
  },
  currencyButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    marginRight: 8,
  },
  currencyButtonText: {
    fontSize: 16,
    fontWeight: '500',
  },
  requiredSection: {
    marginBottom: 24,
  },
  optionalSection: {
    borderTopWidth: 1,
    borderTopColor: '#e2e8f0',
    paddingTop: 20,
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '500',
    marginBottom: 16,
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 16,
    marginBottom: 8,
    fontWeight: '500',
  },
  required: {
    color: '#ef4444',
  },
  input: {
    borderWidth: 1,
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
  },
  hint: {
    fontSize: 14,
    marginTop: 6,
    fontStyle: 'italic',
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 8,
  },
  button: {
    flex: 1,
    height: 50,
    borderRadius: 25,
    alignItems: 'center',
    justifyContent: 'center',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
    overflow: Platform.OS === 'ios' ? 'hidden' : 'visible',
  },
  buttonText: {
    color: 'white',
    fontSize: 17,
    fontWeight: '600',
    letterSpacing: 0.5,
  },
});