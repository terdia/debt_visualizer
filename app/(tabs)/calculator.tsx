import React, { useState, useCallback } from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  Text,
  TextInput,
  SafeAreaView,
  useWindowDimensions,
  TouchableOpacity,
  Platform,
} from 'react-native';
import { useAppColors } from '../../utils/colors';
import { LineChart } from 'react-native-chart-kit';
import { Ionicons } from '@expo/vector-icons';

interface DebtInput {
  id: string;
  name: string;
  amount: string;
  interest: string;
  monthlyPayment: string;
}

interface PayoffResult {
  months: number;
  totalInterest: number;
  monthlyData: number[];
  paymentSchedule: {
    debtId: string;
    payments: number[];
  }[];
}

export default function CalculatorScreen() {
  const { width } = useWindowDimensions();
  const colors = useAppColors();
  const [debts, setDebts] = useState<DebtInput[]>([
    { 
      id: '1',
      name: 'Debt #1',
      amount: '',
      interest: '',
      monthlyPayment: '',
    },
  ]);
  const [extraPayment, setExtraPayment] = useState('100');
  const chartWidth = Math.min(width - 40, 600);

  const addDebt = useCallback(() => {
    setDebts(current => [...current, {
      id: (current.length + 1).toString(),
      name: `Debt #${current.length + 1}`,
      amount: '',
      interest: '',
      monthlyPayment: '',
    }]);
  }, []);

  const removeDebt = useCallback((index: number) => {
    if (debts.length > 1) {
      setDebts(current => current.filter((_, i) => i !== index));
    }
  }, [debts.length]);

  const updateDebt = useCallback((index: number, field: keyof DebtInput, value: string) => {
    setDebts(current => {
      const newDebts = [...current];
      newDebts[index] = { ...newDebts[index], [field]: value };
      return newDebts;
    });
  }, []);

  const validateDebts = useCallback(() => {
    return debts.every(debt => {
      const amount = parseFloat(debt.amount);
      const interest = parseFloat(debt.interest);
      const payment = parseFloat(debt.monthlyPayment);
      
      return (
        !isNaN(amount) && amount > 0 &&
        !isNaN(interest) && interest >= 0 &&
        !isNaN(payment) && payment > 0 &&
        payment >= (amount * (parseFloat(debt.interest) / 100 / 12)) // Payment covers at least monthly interest
      );
    });
  }, [debts]);

  const calculatePayoffStrategies = useCallback(() => {
    if (!validateDebts() || debts.length < 2) return null;

    const minPaymentsSum = debts.reduce((sum, debt) => 
      sum + parseFloat(debt.monthlyPayment), 0
    );
    const totalMonthlyPayment = minPaymentsSum + parseFloat(extraPayment);

    const snowballDebts = [...debts].sort((a, b) => 
      parseFloat(a.amount) - parseFloat(b.amount)
    );
    const avalancheDebts = [...debts].sort((a, b) => 
      parseFloat(b.interest) - parseFloat(a.interest)
    );

    return {
      snowball: simulatePayoff(snowballDebts, totalMonthlyPayment),
      avalanche: simulatePayoff(avalancheDebts, totalMonthlyPayment),
    };
  }, [debts, extraPayment, validateDebts]);

  const simulatePayoff = useCallback((orderedDebts: DebtInput[], totalMonthlyPayment: number): PayoffResult => {
    let months = 0;
    let totalInterest = 0;
    const balances = orderedDebts.map(debt => parseFloat(debt.amount));
    const monthlyData = [balances.reduce((a, b) => a + b, 0)];
    const minPayments = orderedDebts.map(debt => parseFloat(debt.monthlyPayment));
    const paymentSchedule = orderedDebts.map(debt => ({
      debtId: debt.id,
      payments: [parseFloat(debt.amount)]
    }));

    while (balances.some(b => b > 0) && months < 360) {
      // Calculate interest first
      for (let i = 0; i < orderedDebts.length; i++) {
        if (balances[i] <= 0) continue;
        
        const monthlyRate = parseFloat(orderedDebts[i].interest) / 100 / 12;
        const interest = balances[i] * monthlyRate;
        totalInterest += interest;
        balances[i] += interest;
      }

      // Apply minimum payments
      let remainingPayment = totalMonthlyPayment;
      for (let i = 0; i < orderedDebts.length; i++) {
        if (balances[i] <= 0) continue;
        
        const payment = Math.min(minPayments[i], balances[i]);
        balances[i] -= payment;
        remainingPayment -= payment;
      }

      // Apply extra payment to target debt
      if (remainingPayment > 0) {
        for (let i = 0; i < balances.length; i++) {
          if (balances[i] <= 0) continue;
          
          const payment = Math.min(remainingPayment, balances[i]);
          balances[i] -= payment;
          remainingPayment -= payment;
          if (remainingPayment <= 0) break;
        }
      }

      months++;
      monthlyData.push(balances.reduce((a, b) => a + b, 0));
      balances.forEach((balance, i) => {
        paymentSchedule[i].payments.push(balance);
      });
    }

    return { 
      months, 
      totalInterest: Math.round(totalInterest), 
      monthlyData,
      paymentSchedule 
    };
  }, []);

  const results = calculatePayoffStrategies();
  const showComparison = debts.length >= 2 && results;
  const totalDebt = debts.reduce((sum, debt) => 
    sum + (parseFloat(debt.amount) || 0), 0
  );

  const getRecommendation = useCallback(() => {
    if (!results) return null;

    const interestDiff = results.snowball.totalInterest - results.avalanche.totalInterest;
    const timeDiff = results.snowball.months - results.avalanche.months;

    if (interestDiff > 1000) {
      return {
        method: 'Avalanche Method',
        reason: `Save $${interestDiff.toLocaleString()} in interest by targeting high-interest debt first`,
        icon: 'trending-down'
      };
    } else if (interestDiff < -1000) {
      return {
        method: 'Snowball Method',
        reason: `Build momentum with quick wins and only pay $${Math.abs(interestDiff).toLocaleString()} more in interest`,
        icon: 'snow'
      };
    } else {
      return {
        method: 'Either Method',
        reason: 'Both methods are equally effective for your situation',
        icon: 'checkmark-circle'
      };
    }
  }, [results]);

  const recommendation = getRecommendation();

  return (
    <SafeAreaView style={[styles.safeArea, { backgroundColor: colors.background }]}>
      <ScrollView
        style={[styles.container, { backgroundColor: colors.background }]}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}>
        <View style={[styles.content, { maxWidth: Math.min(width, 600) }]}>
          {/* Strategy Explanation */}
          <View style={[styles.card, { backgroundColor: colors.cardBackground, marginBottom: 16 }]}>
            <Text style={[styles.title, { color: colors.text }]}>Debt Payoff Strategies</Text>
            
            <View style={styles.strategyExplanation}>
              <View style={styles.strategySection}>
                <View style={[styles.strategyIcon, { backgroundColor: '#3b82f615' }]}>
                  <Ionicons name="snow" size={24} color="#3b82f6" />
                </View>
                <View style={styles.strategyContent}>
                  <Text style={[styles.strategyTitle, { color: colors.text }]}>Debt Snowball</Text>
                  <Text style={[styles.strategyDesc, { color: colors.textSecondary }]}>
                    Pay minimum on all debts, then put extra money toward the smallest debt first. 
                    Great for motivation through quick wins.
                  </Text>
                </View>
              </View>

              <View style={styles.strategySection}>
                <View style={[styles.strategyIcon, { backgroundColor: '#ef444415' }]}>
                  <Ionicons name="trending-down" size={24} color="#ef4444" />
                </View>
                <View style={styles.strategyContent}>
                  <Text style={[styles.strategyTitle, { color: colors.text }]}>Debt Avalanche</Text>
                  <Text style={[styles.strategyDesc, { color: colors.textSecondary }]}>
                    Pay minimum on all debts, then put extra money toward the highest interest debt first. 
                    Saves the most money in interest.
                  </Text>
                </View>
              </View>
            </View>
          </View>

          {/* Debt Inputs */}
          <View style={[styles.card, { backgroundColor: colors.cardBackground }]}>
            <Text style={[styles.subtitle, { color: colors.text }]}>Your Debts</Text>

            {debts.map((debt, index) => (
              <View key={debt.id} style={[styles.debtContainer, { borderColor: colors.border }]}>
                <View style={styles.debtHeader}>
                  <Text style={[styles.debtTitle, { color: colors.text }]}>{debt.name}</Text>
                  {debts.length > 1 && (
                    <TouchableOpacity
                      onPress={() => removeDebt(index)}
                      style={[styles.removeButton, { backgroundColor: colors.danger + '20' }]}>
                      <Ionicons name="close" size={20} color={colors.danger} />
                    </TouchableOpacity>
                  )}
                </View>

                <View style={styles.inputGroup}>
                  <Text style={[styles.label, { color: colors.text }]}>Amount ($)</Text>
                  <TextInput
                    style={[styles.input, {
                      backgroundColor: colors.inputBackground,
                      borderColor: colors.inputBorder,
                      color: colors.text,
                    }]}
                    value={debt.amount}
                    onChangeText={(value) => updateDebt(index, 'amount', value)}
                    keyboardType="numeric"
                    placeholder="e.g., 10000"
                    placeholderTextColor={colors.textTertiary}
                  />
                </View>

                <View style={styles.inputGroup}>
                  <Text style={[styles.label, { color: colors.text }]}>Interest Rate (%)</Text>
                  <TextInput
                    style={[styles.input, {
                      backgroundColor: colors.inputBackground,
                      borderColor: colors.inputBorder,
                      color: colors.text,
                    }]}
                    value={debt.interest}
                    onChangeText={(value) => updateDebt(index, 'interest', value)}
                    keyboardType="numeric"
                    placeholder="e.g., 5"
                    placeholderTextColor={colors.textTertiary}
                  />
                </View>

                <View style={styles.inputGroup}>
                  <Text style={[styles.label, { color: colors.text }]}>Minimum Monthly Payment ($)</Text>
                  <TextInput
                    style={[styles.input, {
                      backgroundColor: colors.inputBackground,
                      borderColor: colors.inputBorder,
                      color: colors.text,
                    }]}
                    value={debt.monthlyPayment}
                    onChangeText={(value) => updateDebt(index, 'monthlyPayment', value)}
                    keyboardType="numeric"
                    placeholder="e.g., 200"
                    placeholderTextColor={colors.textTertiary}
                  />
                </View>
              </View>
            ))}

            <View style={[styles.extraPaymentContainer, { borderColor: colors.border }]}>
              <Text style={[styles.label, { color: colors.text }]}>Extra Monthly Payment ($)</Text>
              <TextInput
                style={[styles.input, {
                  backgroundColor: colors.inputBackground,
                  borderColor: colors.inputBorder,
                  color: colors.text,
                }]}
                value={extraPayment}
                onChangeText={setExtraPayment}
                keyboardType="numeric"
                placeholder="e.g., 100"
                placeholderTextColor={colors.textTertiary}
              />
              <Text style={[styles.hint, { color: colors.textTertiary }]}>
                Additional amount above minimum payments to speed up debt payoff
              </Text>
            </View>

            <TouchableOpacity
              style={[styles.addButton, { backgroundColor: colors.primary + '15' }]}
              onPress={addDebt}>
              <Ionicons name="add" size={24} color={colors.primary} />
              <Text style={[styles.addButtonText, { color: colors.primary }]}>Add Another Debt</Text>
            </TouchableOpacity>

            {!showComparison && debts.length < 2 && (
              <View style={[styles.infoCard, { backgroundColor: colors.primary + '15' }]}>
                <Ionicons name="information-circle" size={24} color={colors.primary} />
                <Text style={[styles.infoText, { color: colors.primary }]}>
                  Add at least one more debt to compare payoff strategies
                </Text>
              </View>
            )}

            {showComparison && results && recommendation && (
              <View style={styles.resultsContainer}>
                <View style={[styles.recommendationCard, { backgroundColor: colors.primary + '15' }]}>
                  <View style={styles.recommendationHeader}>
                    <Ionicons name={recommendation.icon as any} size={24} color={colors.primary} />
                    <Text style={[styles.recommendationTitle, { color: colors.primary }]}>
                      {recommendation.method}
                    </Text>
                  </View>
                  <Text style={[styles.recommendationDesc, { color: colors.textSecondary }]}>
                    {recommendation.reason}
                  </Text>
                </View>

                <View style={[styles.comparisonCard, { backgroundColor: colors.cardBackground }]}>
                  <View style={[styles.methodCard, { borderColor: colors.border }]}>
                    <View style={styles.methodHeader}>
                      <Ionicons name="snow" size={24} color="#3b82f6" />
                      <Text style={[styles.methodTitle, { color: colors.text }]}>Snowball</Text>
                    </View>
                    <View style={styles.methodStats}>
                      <Text style={[styles.statLabel, { color: colors.textSecondary }]}>
                        Time to Debt-Free:
                      </Text>
                      <Text style={[styles.statValue, { color: colors.text }]}>
                        {results.snowball.months} months
                      </Text>
                      <Text style={[styles.statLabel, { color: colors.textSecondary }]}>
                        Total Interest:
                      </Text>
                      <Text style={[styles.statValue, { color: colors.text }]}>
                        ${results.snowball.totalInterest.toLocaleString()}
                      </Text>
                    </View>
                  </View>

                  <View style={[styles.methodCard, { borderColor: colors.border }]}>
                    <View style={styles.methodHeader}>
                      <Ionicons name="trending-down" size={24} color="#ef4444" />
                      <Text style={[styles.methodTitle, { color: colors.text }]}>Avalanche</Text>
                    </View>
                    <View style={styles.methodStats}>
                      <Text style={[styles.statLabel, { color: colors.textSecondary }]}>
                        Time to Debt-Free:
                      </Text>
                      <Text style={[styles.statValue, { color: colors.text }]}>
                        {results.avalanche.months} months
                      </Text>
                      <Text style={[styles.statLabel, { color: colors.textSecondary }]}>
                        Total Interest:
                      </Text>
                      <Text style={[styles.statValue, { color: colors.text }]}>
                        ${results.avalanche.totalInterest.toLocaleString()}
                      </Text>
                    </View>
                  </View>
                </View>

                <View style={styles.chartContainer}>
                  <Text style={[styles.chartTitle, { color: colors.text }]}>Balance Over Time</Text>
                  <LineChart
                    data={{
                      labels: Array.from({ length: 6 }, (_, i) => 
                        `${Math.floor(i * Math.max(results.snowball.months, results.avalanche.months) / 5)}m`
                      ),
                      datasets: [
                        {
                          data: results.snowball.monthlyData,
                          color: () => '#3b82f6',
                          strokeWidth: 2,
                        },
                        {
                          data: results.avalanche.monthlyData,
                          color: () => '#ef4444',
                          strokeWidth: 2,
                        },
                      ],
                      legend: ['Snowball', 'Avalanche'],
                    }}
                    width={chartWidth}
                    height={220}
                    chartConfig={{
                      backgroundColor: colors.chartBackground,
                      backgroundGradientFrom: colors.chartBackground,
                      backgroundGradientTo: colors.chartBackground,
                      decimalPlaces: 0,
                      color: (opacity = 1) => `rgba(37, 99, 235, ${opacity})`,
                      labelColor: (opacity = 1) => colors.chartText,
                      strokeWidth: 2,
                      style: {
                        borderRadius: 16,
                      },
                      propsForDots: {
                        r: '4',
                      },
                      propsForLabels: {
                        fontSize: Platform.OS === 'web' ? 12 : 10,
                      },
                    }}
                    bezier
                    style={styles.chart}
                    withInnerLines={false}
                    withOuterLines={true}
                    withVerticalLines={false}
                    withHorizontalLines={true}
                    withVerticalLabels={true}
                    withHorizontalLabels={true}
                    fromZero={true}
                  />
                  <View style={styles.chartLegend}>
                    <View style={styles.legendItem}>
                      <View style={[styles.legendDot, { backgroundColor: '#3b82f6' }]} />
                      <Text style={[styles.legendText, { color: colors.textSecondary }]}>
                        Snowball Method
                      </Text>
                    </View>
                    <View style={styles.legendItem}>
                      <View style={[styles.legendDot, { backgroundColor: '#ef4444' }]} />
                      <Text style={[styles.legendText, { color: colors.textSecondary }]}>
                        Avalanche Method
                      </Text>
                    </View>
                  </View>
                </View>
              </View>
            )}
          </View>
        </View>
      </ScrollView>
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
    paddingVertical: 20,
  },
  content: {
    width: '100%',
    paddingHorizontal: 20,
  },
  card: {
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
    fontWeight: '700',
    marginBottom: 20,
  },
  subtitle: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 16,
  },
  strategyExplanation: {
    marginBottom: 20,
  },
  strategySection: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  strategyIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  strategyContent: {
    flex: 1,
  },
  strategyTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
  },
  strategyDesc: {
    fontSize: 14,
    lineHeight: 20,
  },
  debtContainer: {
    marginBottom: 16,
    borderWidth: 1,
    borderRadius: 12,
    padding: 16,
  },
  debtHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  debtTitle: {
    fontSize: 18,
    fontWeight: '600',
  },
  removeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    marginBottom: 8,
    fontWeight: '500',
  },
  input: {
    borderWidth: 1,
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
  },
  extraPaymentContainer: {
    marginBottom: 24,
    borderWidth: 1,
    borderRadius: 12,
    padding: 16,
  },
  hint: {
    fontSize: 12,
    marginTop: 4,
    fontStyle: 'italic',
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
    gap: 8,
  },
  addButtonText: {
    fontSize: 16,
    fontWeight: '600',
  },
  infoCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: 12,
    gap: 12,
  },
  infoText: {
    flex: 1,
    fontSize: 14,
    lineHeight: 20,
  },
  resultsContainer: {
    marginTop: 24,
  },
  recommendationCard: {
    padding: 16,
    borderRadius: 12,
    marginBottom: 24,
  },
  recommendationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 8,
  },
  recommendationTitle: {
    fontSize: 18,
    fontWeight: '600',
  },
  recommendationDesc: {
    fontSize: 14,
    lineHeight: 20,
  },
  comparisonCard: {
    flexDirection: 'row',
    gap: 16,
    marginBottom: 24,
  },
  methodCard: {
    flex: 1,
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
  },
  methodHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  methodTitle: {
    fontSize: 16,
    fontWeight: '600',
  },
  methodStats: {
    gap: 4,
  },
  statLabel: {
    fontSize: 12,
  },
  statValue: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
  },
  chartContainer: {
    marginTop: 8,
  },
  chartTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
  },
  chart: {
    marginVertical: 8,
    borderRadius: 16,
  },
  chartLegend: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 20,
    marginTop: 12,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  legendText: {
    fontSize: 14,
  },
});