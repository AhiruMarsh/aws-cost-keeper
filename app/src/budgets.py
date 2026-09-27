#!/usr/bin/env python
import boto3

class AwsBudgets:
    """ AWS Budgetsを取得するためのクラス（要: アカウントID, 取得対象の予算名） """
    def __init__(self, account_id: str, budget_name: str):
        self._account_id  = account_id
        self._budget_name = budget_name

        # テスト等では読み取ることができないため、Noneを返す
        self._client = boto3.client('budgets')
        try:
            self._response = self._client.describe_budget(
                AccountId=self._account_id,
                BudgetName=self._budget_name,
            )
        except Exception as e:
            self._response = None

    def get_actual_cost(self) -> str:
        """ 今月の実績値を取得 """
        try:
            i = float(self._response['Budget']['CalculatedSpend']['ActualSpend']['Amount'])
        except Exception as e:
            print(e)
            i = "???"
            
        return i
    
    def get_forecast_cost(self) -> str:
        """ 今月の予測値を取得 """
        try:
            i = float(self._response['Budget']['CalculatedSpend']['ForecastedSpend']['Amount'])
        except Exception as e:
            print(e)
            i = "???"
            
        return i
