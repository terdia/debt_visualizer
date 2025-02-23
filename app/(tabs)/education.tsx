import React, { useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  Text,
  SafeAreaView,
  useWindowDimensions,
  TouchableOpacity,
} from 'react-native';
import { useAppColors } from '../../utils/colors';
import { Ionicons } from '@expo/vector-icons';

const DEBT_EDUCATION = {
  strategies: [
    {
      title: 'Debt Avalanche Method',
      description: 'Focus on high-interest debt first while making minimum payments on others. This method saves the most money in interest over time.',
      icon: 'trending-down',
      tips: [
        'List all debts by interest rate',
        'Pay minimum on all debts',
        'Put extra money toward highest-interest debt',
        'Repeat process as each debt is paid off'
      ]
    },
    {
      title: 'Debt Snowball Method',
      description: 'Pay off smallest debts first for psychological wins. This builds momentum and motivation through quick victories.',
      icon: 'snow',
      tips: [
        'List debts from smallest to largest',
        'Pay minimum on all debts',
        'Put extra money toward smallest debt',
        'Use freed-up money for next smallest debt'
      ]
    }
  ],
  prevention: [
    {
      title: 'Emergency Fund Building',
      description: 'Build a safety net to avoid future debt from unexpected expenses.',
      icon: 'save',
      tips: [
        'Start with $1,000 emergency fund',
        'Aim for 3-6 months of expenses',
        'Keep in high-yield savings account',
        'Only use for true emergencies'
      ]
    },
    {
      title: 'Smart Budgeting',
      description: 'Create and stick to a realistic budget to prevent overspending and new debt.',
      icon: 'wallet',
      tips: [
        'Track all expenses for a month',
        'Use 50/30/20 rule: needs/wants/savings',
        'Plan for irregular expenses',
        'Review and adjust monthly'
      ]
    }
  ],
  psychology: [
    {
      title: 'Understanding Money Habits',
      description: 'Identify and change spending triggers and behaviors that lead to debt.',
      icon: 'bulb',
      tips: [
        'Track emotional spending triggers',
        'Wait 24 hours before large purchases',
        'Find free alternatives to spending',
        'Celebrate financial wins appropriately'
      ]
    },
    {
      title: 'Building Better Habits',
      description: 'Develop positive financial habits that support long-term financial health.',
      icon: 'leaf',
      tips: [
        'Automate savings and payments',
        'Check accounts weekly',
        'Learn about personal finance',
        'Share goals with accountability partner'
      ]
    }
  ]
};

interface SectionProps {
  title: string;
  items: any[];
}

function Section({ title, items }: SectionProps) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {items.map((item, index) => (
        <ExpandableCard key={index} {...item} />
      ))}
    </View>
  );
}

interface ExpandableCardProps {
  title: string;
  description: string;
  icon: string;
  tips: string[];
}

function ExpandableCard({ title, description, icon, tips }: ExpandableCardProps) {
  const [expanded, setExpanded] = useState(false);
  const colors = useAppColors();

  return (
    <View style={[styles.card, { backgroundColor: colors.cardBackground }]}>
      <TouchableOpacity
        style={styles.cardHeader}
        onPress={() => setExpanded(!expanded)}>
        <View style={styles.cardTitleContainer}>
          <Ionicons name={icon as any} size={24} color={colors.primary} />
          <Text style={[styles.cardTitle, { color: colors.text }]}>{title}</Text>
        </View>
        <Ionicons
          name={expanded ? 'chevron-up' : 'chevron-down'}
          size={24}
          color={colors.textSecondary}
        />
      </TouchableOpacity>
      
      <Text style={[styles.cardDescription, { color: colors.textSecondary }]}>
        {description}
      </Text>
      
      {expanded && (
        <View style={[styles.tipsContainer, { borderTopColor: colors.border }]}>
          <Text style={[styles.tipsTitle, { color: colors.text }]}>Action Steps:</Text>
          {tips.map((tip, index) => (
            <View key={index} style={styles.tipRow}>
              <Ionicons name="checkmark-circle" size={20} color={colors.primary} />
              <Text style={[styles.tipText, { color: colors.textSecondary }]}>{tip}</Text>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

export default function EducationScreen() {
  const { width } = useWindowDimensions();
  const colors = useAppColors();

  return (
    <SafeAreaView style={[styles.safeArea, { backgroundColor: colors.background }]}>
      <ScrollView
        style={[styles.container, { backgroundColor: colors.background }]}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}>
        <View style={[styles.content, { maxWidth: Math.min(width, 600) }]}>
          <Text style={[styles.title, { color: colors.text }]}>Debt-Free Journey</Text>
          <Text style={[styles.subtitle, { color: colors.textSecondary }]}>
            Learn proven strategies and build better financial habits
          </Text>

          <Section title="Debt Payoff Strategies" items={DEBT_EDUCATION.strategies} />
          <Section title="Debt Prevention" items={DEBT_EDUCATION.prevention} />
          <Section title="Financial Psychology" items={DEBT_EDUCATION.psychology} />
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
    paddingBottom: 32,
  },
  content: {
    width: '100%',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    marginBottom: 24,
  },
  section: {
    marginBottom: 32,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#334155',
    marginBottom: 16,
  },
  card: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  cardTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginLeft: 12,
    flex: 1,
  },
  cardDescription: {
    fontSize: 16,
    lineHeight: 24,
  },
  tipsContainer: {
    marginTop: 16,
    paddingTop: 16,
    borderTopWidth: 1,
  },
  tipsTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 12,
  },
  tipRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  tipText: {
    fontSize: 16,
    marginLeft: 8,
    flex: 1,
  },
});