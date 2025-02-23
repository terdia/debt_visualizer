import React, { useState, useEffect } from 'react';
import {
  Modal,
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Platform,
} from 'react-native';
import { useAppColors } from '../utils/colors';
import { DebtProfile, DebtProfileInput } from '../types/debt';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';

interface DebtProfileModalProps {
  visible: boolean;
  onClose: () => void;
  onSave: (profile: DebtProfileInput) => void;
  initialData?: DebtProfile;
}

const CURRENCIES = [
  { code: 'USD', symbol: '$' },
  { code: 'EUR', symbol: '€' },
  { code: 'GBP', symbol: '£' },
  { code: 'JPY', symbol: '¥' },
  { code: 'None', symbol: '' },
];

export default function DebtProfileModal({
  visible,
  onClose,
  onSave,
  initialData,
}: DebtProfileModalProps) {
  const colors = useAppColors();
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [totalDebt, setTotalDebt] = useState('');
  const [interestRate, setInterestRate] = useState('');
  const [monthlyPayment, setMonthlyPayment] = useState('');
  const [hourlyWage, setHourlyWage] = useState('');
  const [amountPaid, setAmountPaid] = useState('');
  const [selectedCurrency, setSelectedCurrency] = useState(CURRENCIES[0]);

  useEffect(() => {
    if (initialData) {
      setName(initialData.name);
      setDescription(initialData.description);
      setTotalDebt(initialData.totalDebt.toString());
      setInterestRate(initialData.interestRate.toString());
      setMonthlyPayment(initialData.monthlyPayment.toString());
      setHourlyWage(initialData.hourlyWage?.toString() || '');
      setAmountPaid(initialData.amountPaid.toString());
      setSelectedCurrency(initialData.currency);
    } else {
      resetForm();
    }
  }, [initialData]);

  const resetForm = () => {
    setName('');
    setDescription('');
    setTotalDebt('');
    setInterestRate('');
    setMonthlyPayment('');
    setHourlyWage('');
    setAmountPaid('');
    setSelectedCurrency(CURRENCIES[0]);
  };

  const handleSave = () => {
    const profileData: DebtProfileInput = {
      name,
      description,
      totalDebt: parseFloat(totalDebt),
      interestRate: parseFloat(interestRate || '0'),
      monthlyPayment: parseFloat(monthlyPayment),
      amountPaid: parseFloat(amountPaid || '0'),
      currency: selectedCurrency,
      ...(hourlyWage ? { hourlyWage: parseFloat(hourlyWage) } : {}),
    };

    onSave(profileData);
    resetForm();
    onClose();
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={true}
      onRequestClose={onClose}>
      <View style={styles.modalOverlay}>
        <View style={[styles.modalContent, { backgroundColor: colors.cardBackground }]}>
          <View style={styles.modalHeader}>
            <Text style={[styles.modalTitle, { color: colors.text }]}>
              {initialData ? 'Edit Debt Profile' : 'New Debt Profile'}
            </Text>
            <TouchableOpacity onPress={onClose}>
              <Ionicons name="close" size={24} color={colors.textSecondary} />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.form}>
            <View style={styles.inputGroup}>
              <Text style={[styles.label, { color: colors.text }]}>
                Profile Name <Text style={styles.required}>*</Text>
              </Text>
              <TextInput
                style={[styles.input, { 
                  backgroundColor: colors.inputBackground,
                  borderColor: colors.inputBorder,
                  color: colors.text,
                }]}
                value={name}
                onChangeText={setName}
                placeholder="e.g., Student Loans"
                placeholderTextColor={colors.textTertiary}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={[styles.label, { color: colors.text }]}>Description</Text>
              <TextInput
                style={[styles.input, { 
                  backgroundColor: colors.inputBackground,
                  borderColor: colors.inputBorder,
                  color: colors.text,
                  height: 80,
                }]}
                value={description}
                onChangeText={setDescription}
                placeholder="Add some details about this debt"
                placeholderTextColor={colors.textTertiary}
                multiline
                textAlignVertical="top"
              />
            </View>

            <View style={styles.currencySection}>
              <Text style={[styles.label, { color: colors.text }]}>Select Currency</Text>
              <ScrollView 
                horizontal 
                showsHorizontalScrollIndicator={false}
                style={styles.currencyScroll}
                contentContainerStyle={styles.currencyContainer}>
                {CURRENCIES.map((currency) => (
                  <TouchableOpacity
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
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

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
                value={totalDebt}
                onChangeText={setTotalDebt}
                keyboardType="numeric"
                placeholder="e.g., 10000"
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
                value={monthlyPayment}
                onChangeText={setMonthlyPayment}
                keyboardType="numeric"
                placeholder="e.g., 500"
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
                value={interestRate}
                onChangeText={setInterestRate}
                keyboardType="numeric"
                placeholder="e.g., 5"
                placeholderTextColor={colors.textTertiary}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={[styles.label, { color: colors.text }]}>
                Amount Paid So Far {selectedCurrency.symbol}
              </Text>
              <TextInput
                style={[styles.input, { 
                  backgroundColor: colors.inputBackground,
                  borderColor: colors.inputBorder,
                  color: colors.text,
                }]}
                value={amountPaid}
                onChangeText={setAmountPaid}
                keyboardType="numeric"
                placeholder="e.g., 2000"
                placeholderTextColor={colors.textTertiary}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={[styles.label, { color: colors.text }]}>
                Hourly Wage {selectedCurrency.symbol}
              </Text>
              <TextInput
                style={[styles.input, { 
                  backgroundColor: colors.inputBackground,
                  borderColor: colors.inputBorder,
                  color: colors.text,
                }]}
                value={hourlyWage}
                onChangeText={setHourlyWage}
                keyboardType="numeric"
                placeholder="e.g., 15"
                placeholderTextColor={colors.textTertiary}
              />
            </View>
          </ScrollView>

          <View style={styles.buttonContainer}>
            <TouchableOpacity
              style={[styles.button, { backgroundColor: colors.primary }]}
              onPress={handleSave}>
              {Platform.OS === 'ios' && (
                <BlurView
                  intensity={20}
                  style={StyleSheet.absoluteFill}
                  tint={colors.isDark ? 'dark' : 'light'}
                />
              )}
              <Text style={styles.buttonText}>
                {initialData ? 'Save Changes' : 'Create Profile'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  modalContent: {
    width: '100%',
    maxWidth: 500,
    maxHeight: '90%',
    borderRadius: 16,
    overflow: 'hidden',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e2e8f0',
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: '600',
  },
  form: {
    padding: 16,
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
  currencySection: {
    marginBottom: 16,
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
  buttonContainer: {
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#e2e8f0',
  },
  button: {
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