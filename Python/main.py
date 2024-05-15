import pandas as pd
import json
from datetime import datetime, timedelta
from utils.logs import Logs

class ContractParser:
    def __init__(self, file_path, application_date):
        self.file_path = file_path
        self.application_date = pd.to_datetime(application_date, format='%d.%m.%Y')
        self.data = None
        self.parsed_data = []
        self.logger = Logs(__name__).get_logger()

    def load_data(self):
        try:
            self.data = pd.read_csv(self.file_path).dropna(subset=['contracts'])
            self.logger.info("Data loaded successfully.", rows=self.data.shape[0])
        except Exception as e:
            self.logger.error("Failed to load data.", error=str(e))

    def add_contract(self, contract):
        self.parsed_data.append({
            'claim_id': contract.get('claim_id'),
            'claim_date': contract.get('claim_date'),
            'bank': contract.get('bank'),
            'loan_summa': contract.get('loan_summa'),
            'contract_date': contract.get('contract_date'),
            'summa': contract.get('summa')
        })

    def parse_contracts(self):
        try:
            for idx, row in self.data.iterrows():
                try:
                    contracts = json.loads(row['contracts'])
                    if isinstance(contracts, list):
                        for contract in contracts:
                            if isinstance(contract, dict):
                                self.add_contract(contract)
                            else:
                                self.logger.warning(f"Unexpected contract format in row {idx}: {contract}")
                    elif isinstance(contracts, dict):
                        self.add_contract(contracts)
                    else:
                        self.logger.warning(f"Unexpected contracts format in row {idx}: {contracts}\nFull row: {row}")
                except json.JSONDecodeError as e:
                    self.logger.error(f"Error decoding JSON for row {idx}.", error=str(e))
        except Exception as e:
            self.logger.error("Failed to parse contracts.", error=str(e))

    def get_parsed_data(self):
        try:
            df = pd.DataFrame(self.parsed_data)
            self.logger.info("Parsed data created.", rows=df.shape[0])
            return df
        except Exception as e:
            self.logger.error("Failed to create DataFrame from parsed data.", error=str(e))
            return pd.DataFrame()

    def calculate_tot_claim_cnt_l180d(self):
        try:
            df = self.get_parsed_data()
            df['claim_date'] = pd.to_datetime(df['claim_date'], format='%d.%m.%Y', errors='coerce')
            reference_date = df['claim_date'].max()
            if pd.isnull(reference_date):
                self.logger.info("No valid claim dates found.")
                return -3
            start_date = reference_date - timedelta(days=180)
            recent_claims = df[(df['claim_date'] >= start_date) & (df['claim_date'] <= reference_date)]
            claim_count = recent_claims['claim_id'].notnull().sum()
            return claim_count if claim_count > 0 else -3
        except Exception as e:
            self.logger.error("Failed to calculate total claims count in last 180 days.", error=str(e))
            return -3

    def calculate_disb_bank_loan_wo_tbc(self):
        try:
            df = self.get_parsed_data()
            excluded_banks = ['LIZ', 'LOM', 'MKO', 'SUG', None]
            filtered_loans = df[~df['bank'].isin(excluded_banks) & df['contract_date'].notnull()]
            filtered_loans.loc[:, 'loan_summa'] = pd.to_numeric(filtered_loans['loan_summa'], errors='coerce')
            loan_summa_total = filtered_loans['loan_summa'].dropna().sum()
            if filtered_loans.empty:
                return -1
            return loan_summa_total if loan_summa_total > 0 else -3
        except Exception as e:
            self.logger.error("Failed to calculate sum of loans without TBC loans.", error=str(e))
            return -3

    def calculate_day_sinlastloan(self):
        try:
            df = self.get_parsed_data()
            df['contract_date'] = pd.to_datetime(df['contract_date'], format='%d.%m.%Y', errors='coerce')
            valid_loans = df[df['summa'].notnull() & df['contract_date'].notnull()]
            if valid_loans.empty:
                return -1
            last_loan_date = valid_loans['contract_date'].max()
            days_since_last_loan = (self.application_date - last_loan_date).days
            return days_since_last_loan if days_since_last_loan >= 0 else -3
        except Exception as e:
            self.logger.error("Failed to calculate days since last loan.", error=str(e))
            return -3

    def save_features(self, output_file):
        try:
            tot_claim_cnt_l180d = self.calculate_tot_claim_cnt_l180d()
            disb_bank_loan_wo_tbc = self.calculate_disb_bank_loan_wo_tbc()
            day_sinlastloan = self.calculate_day_sinlastloan()
            features_df = pd.DataFrame({
                'tot_claim_cnt_l180d': [tot_claim_cnt_l180d],
                'disb_bank_loan_wo_tbc': [disb_bank_loan_wo_tbc],
                'day_sinlastloan': [day_sinlastloan]
            })
            features_df.to_csv(output_file, index=False)
            self.logger.info(f"Features saved to {output_file}")
        except Exception as e:
            self.logger.error("Failed to save features to CSV.", error=str(e))

if __name__ == "__main__":
    file_path = '/Users/apetrukh/Desktop/tbc_de_assessment/Python/data.csv'
    application_date = '14.05.2024'
    parser = ContractParser(file_path, application_date)
    parser.load_data()
    parser.parse_contracts()
    output_file = 'contract_features.csv'
    parser.save_features(output_file)
