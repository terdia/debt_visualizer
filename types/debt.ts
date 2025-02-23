export interface DebtProfile {
  id: string;
  name: string;
  description: string;
  createdAt: string;
  updatedAt: string;
  totalDebt: number;
  interestRate: number;
  monthlyPayment: number;
  hourlyWage?: number;
  amountPaid: number;
  currency: { code: string; symbol: string };
}

export interface DebtProfileInput {
  name: string;
  description: string;
  totalDebt: number;
  interestRate: number;
  monthlyPayment: number;
  hourlyWage?: number;
  amountPaid: number;
  currency: { code: string; symbol: string };
}