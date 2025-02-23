import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, useWindowDimensions, Platform } from 'react-native';
import { LineChart } from 'react-native-chart-kit';
import { DebtInputData } from './DebtInput';
import { Ionicons } from '@expo/vector-icons';
import { useAppColors } from '../utils/colors';
import Slider from '@react-native-community/slider';
import Animated, {
  useAnimatedStyle,
  withSpring,
  useSharedValue,
  withSequence,
  withTiming,
} from 'react-native-reanimated';

interface DebtVisualizationProps {
  data: DebtInputData;
}

const AnimatedText = Animated.createAnimatedComponent(Text);

export default function DebtVisualization({ data }: DebtVisualizationProps) {
  const { width } = useWindowDimensions();
  const colors = useAppColors();
  const chartWidth = Math.min(width - 40, 600);
  const [sliderValue, setSliderValue] = useState(0);
  const [extraPayment, setExtraPayment] = useState(0);
  const scaleValue = useSharedValue(1);
  const opacityValue = useSharedValue(1);

  const calculateMonthsToPayoff = useCallback((additionalPayment = 0) => {
    if (!data) return 0;
    
    const { totalDebt, interestRate, monthlyPayment, amountPaid } = data;
    const remainingDebt = totalDebt - amountPaid;
    const monthlyRate = (interestRate / 100) / 12;
    const totalMonthlyPayment = monthlyPayment + additionalPayment;
    
    if (interestRate === 0) {
      return Math.ceil(remainingDebt / totalMonthlyPayment);
    }

    return Math.ceil(
      -Math.log(1 - (monthlyRate * remainingDebt) / totalMonthlyPayment) /
        Math.log(1 + monthlyRate)
    );
  }, [data]);

  const calculateDebtFreeDate = useCallback((months: number) => {
    const futureDate = new Date();
    futureDate.setMonth(futureDate.getMonth() + months);
    return futureDate.toLocaleDateString('en-US', { 
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }, []);

  const generatePayoffData = useCallback((additionalPayment = 0) => {
    if (!data) return [0];
    
    const months = calculateMonthsToPayoff(additionalPayment);
    const monthlyRate = (data.interestRate / 100) / 12;
    let balance = data.totalDebt - data.amountPaid;
    const balances = [balance];
    const totalMonthlyPayment = data.monthlyPayment + additionalPayment;

    for (let i = 1; i <= months; i++) {
      const interest = balance * monthlyRate;
      balance = balance + interest - totalMonthlyPayment;
      if (balance < 0) balance = 0;
      balances.push(balance);
    }

    return balances;
  }, [data, calculateMonthsToPayoff]);

  const handleSliderChange = useCallback((value: number) => {
    setSliderValue(value);
  }, []);

  const handleSlidingComplete = useCallback((value: number) => {
    setExtraPayment(value);
    scaleValue.value = withSequence(
      withSpring(1.05, { damping: 4, stiffness: 100 }),
      withSpring(1, { damping: 10, stiffness: 100 })
    );
    opacityValue.value = withSequence(
      withTiming(0.8, { duration: 100 }),
      withTiming(1, { duration: 200 })
    );
  }, []);

  useEffect(() => {
    // Update extra payment with a delay to prevent rapid updates
    const timer = setTimeout(() => {
      setExtraPayment(sliderValue);
    }, Platform.OS === 'android' ? 100 : 0);
    return () => clearTimeout(timer);
  }, [sliderValue]);

  const months = calculateMonthsToPayoff(extraPayment);
  const baseMonths = calculateMonthsToPayoff(0);
  const monthsSaved = Math.max(0, baseMonths - months);
  const workHours = data?.hourlyWage ? Math.ceil((data.totalDebt - data.amountPaid) / data.hourlyWage) : 0;
  const payoffData = generatePayoffData(extraPayment);
  const labels = Array.from({ length: Math.min(6, months + 1) }, (_, i) => 
    `${Math.floor(i * months / 5)}m`
  );

  const progressPercentage = data ? (data.amountPaid / data.totalDebt) * 100 : 0;
  const getMotivationalMessage = (percentage: number) => {
    if (percentage === 0) return "Ready to start your debt-free journey!";
    if (percentage < 25) return "Great start! Keep building momentum!";
    if (percentage < 50) return "You're making real progress! Keep pushing!";
    if (percentage < 75) return "You're over halfway there! The finish line is in sight!";
    if (percentage < 100) return "Almost there! You're so close to freedom!";
    return "Congratulations! You're debt-free! 🎉";
  };

  const formatCurrency = (amount: number) => {
    if (!data?.currency?.code || data.currency.code === 'None') {
      return amount.toLocaleString();
    }
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: data.currency.code,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const maxExtraPayment = Math.min(data?.totalDebt * 0.5 || 1000, 2000);

  const calculateTotalInterest = useCallback(() => {
    if (!data) return 0;
    const totalPayments = months * (data.monthlyPayment + extraPayment);
    return Math.max(0, totalPayments - (data.totalDebt - data.amountPaid));
  }, [data, months, extraPayment]);

  const totalInterest = calculateTotalInterest();

  const animatedTextStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scaleValue.value }],
    opacity: opacityValue.value,
  }));

  return (
    <View style={[styles.container, { backgroundColor: colors.cardBackground }]}>
      <Text style={[styles.title, { color: colors.text }]}>Debt Payoff Timeline</Text>
      
      <View style={styles.debtFreeContainer}>
        <View style={[styles.debtFreeDateCard, { backgroundColor: colors.primary + '15' }]}>
          <Ionicons name="calendar" size={24} color={colors.primary} />
          <AnimatedText style={[styles.debtFreeDate, { color: colors.primary }, animatedTextStyle]}>
            Debt-Free by {calculateDebtFreeDate(months)}
          </AnimatedText>
        </View>
      </View>

      <View style={[styles.whatIfContainer, { backgroundColor: colors.cardBackground }]}>
        <Text style={[styles.whatIfTitle, { color: colors.text }]}>
          What If I Pay More?
        </Text>
        <View style={styles.sliderContainer}>
          <Slider
            value={sliderValue}
            onValueChange={handleSliderChange}
            onSlidingComplete={handleSlidingComplete}
            minimumValue={0}
            maximumValue={maxExtraPayment}
            step={50}
            minimumTrackTintColor={colors.primary}
            maximumTrackTintColor={colors.border}
            thumbTintColor={colors.primary}
            style={styles.slider}
          />
          <View style={styles.sliderLabels}>
            <Text style={[styles.sliderLabel, { color: colors.textSecondary }]}>
              +{formatCurrency(0)}
            </Text>
            <Text style={[styles.sliderValue, { color: colors.primary }]}>
              +{formatCurrency(Math.round(sliderValue))}
            </Text>
            <Text style={[styles.sliderLabel, { color: colors.textSecondary }]}>
              +{formatCurrency(maxExtraPayment)}
            </Text>
          </View>
        </View>
        {monthsSaved > 0 && (
          <View style={[styles.savingsCard, { backgroundColor: colors.primary + '15' }]}>
            <Ionicons name="time" size={20} color={colors.primary} />
            <Text style={[styles.savingsText, { color: colors.primary }]}>
              Be debt-free {monthsSaved} months sooner!
            </Text>
          </View>
        )}
      </View>
      
      <View style={styles.progressContainer}>
        <View style={[styles.progressBar, { backgroundColor: colors.border }]}>
          <View 
            style={[
              styles.progressFill, 
              { width: `${progressPercentage}%` }
            ]} 
          />
        </View>
        <Text style={[styles.progressText, { color: colors.text }]}>
          {progressPercentage.toFixed(1)}% Paid Off
        </Text>
        <Text style={styles.motivationText}>
          {getMotivationalMessage(progressPercentage)}
        </Text>
      </View>

      <View style={styles.statsGrid}>
        <View style={[styles.statCard, { backgroundColor: colors.cardBackground, borderColor: colors.border }]}>
          <View style={[styles.statIconContainer, { backgroundColor: '#e0f2fe' }]}>
            <Ionicons name="time" size={24} color="#0284c7" />
          </View>
          <Text style={[styles.statTitle, { color: colors.textSecondary }]}>Time to Freedom</Text>
          <Text style={[styles.statValue, { color: colors.text }]}>{months} months</Text>
          <Text style={[styles.statSubtext, { color: colors.textTertiary }]}>({(months / 12).toFixed(1)} years)</Text>
        </View>

        <View style={[styles.statCard, { backgroundColor: colors.cardBackground, borderColor: colors.border }]}>
          <View style={[styles.statIconContainer, { backgroundColor: '#dcfce7' }]}>
            <Ionicons name="cash" size={24} color="#16a34a" />
          </View>
          <Text style={[styles.statTitle, { color: colors.textSecondary }]}>Amount Paid</Text>
          <Text style={[styles.statValue, { color: colors.text }]}>{formatCurrency(data?.amountPaid || 0)}</Text>
          <Text style={[styles.statSubtext, { color: colors.textTertiary }]}>of {formatCurrency(data?.totalDebt || 0)}</Text>
        </View>

        <View style={[styles.statCard, { backgroundColor: colors.cardBackground, borderColor: colors.border }]}>
          <View style={[styles.statIconContainer, { backgroundColor: '#fee2e2' }]}>
            <Ionicons name="trending-up" size={24} color="#dc2626" />
          </View>
          <Text style={[styles.statTitle, { color: colors.textSecondary }]}>Total Interest</Text>
          <Text style={[styles.statValue, { color: colors.text }]}>{formatCurrency(totalInterest)}</Text>
          <Text style={[styles.statSubtext, { color: colors.textTertiary }]}>over loan term</Text>
        </View>

        {(data?.hourlyWage ?? 0) > 0 && (
          <View style={[styles.statCard, { backgroundColor: colors.cardBackground, borderColor: colors.border }]}>
            <View style={[styles.statIconContainer, { backgroundColor: '#f3e8ff' }]}>
              <Ionicons name="briefcase" size={24} color="#9333ea" />
            </View>
            <Text style={[styles.statTitle, { color: colors.textSecondary }]}>Work Hours</Text>
            <Text style={[styles.statValue, { color: colors.text }]}>{workHours}</Text>
            <Text style={[styles.statSubtext, { color: colors.textTertiary }]}>hours needed</Text>
          </View>
        )}
      </View>

      <View style={styles.chartContainer}>
        <LineChart
          data={{
            labels,
            datasets: [{
              data: payoffData,
            }],
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
            style: {
              borderRadius: 16,
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
  debtFreeContainer: {
    marginBottom: 20,
  },
  debtFreeDateCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
    borderRadius: 12,
    gap: 12,
  },
  debtFreeDate: {
    fontSize: 18,
    fontWeight: '600',
  },
  whatIfContainer: {
    marginBottom: 24,
    padding: 16,
    borderRadius: 12,
  },
  whatIfTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
  },
  sliderContainer: {
    marginBottom: 12,
  },
  slider: {
    height: 40,
    width: '100%',
  },
  sliderLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: -8,
  },
  sliderLabel: {
    fontSize: 12,
  },
  sliderValue: {
    fontSize: 16,
    fontWeight: '600',
  },
  savingsCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 8,
    gap: 8,
  },
  savingsText: {
    fontSize: 14,
    fontWeight: '500',
  },
  progressContainer: {
    marginBottom: 24,
  },
  progressBar: {
    height: 12,
    borderRadius: 6,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#22c55e',
    borderRadius: 6,
  },
  progressText: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 8,
    textAlign: 'center',
  },
  motivationText: {
    fontSize: 16,
    color: '#059669',
    textAlign: 'center',
    marginTop: 8,
    fontWeight: '500',
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
    marginBottom: 24,
  },
  statCard: {
    flex: 1,
    minWidth: Platform.OS === 'web' ? 180 : 140,
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
    borderWidth: 1,
  },
  statIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  statTitle: {
    fontSize: 14,
    fontWeight: '500',
    marginBottom: 4,
    textAlign: 'center',
  },
  statValue: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 2,
    textAlign: 'center',
  },
  statSubtext: {
    fontSize: 12,
    textAlign: 'center',
  },
  chartContainer: {
    alignItems: 'center',
    marginHorizontal: -20,
  },
  chart: {
    marginVertical: 8,
    borderRadius: 16,
  },
});