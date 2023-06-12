#!/usr/bin/env python
# https://github.com/satory074/awscost_to_discord_sample/blob/master/lambda_function.py
# https://cpu100per.aminchu.net/aws/aws-cost-post-to-slack/

import os
import logging
import json
import datetime
import boto3
import requests
import random

# AWS 環境定数
ACCOUNT_ID  = os.environ['AWS_ACCOUNT_ID']
BUDGET_NAME = os.environ['AWS_BUDGET_NAME']

# Discord 環境定数
WEBHOOK_URL = os.environ['DISCORD_WEBHOOK_URL']
USER_NAME   = "AWSコスト通知"
AVATAR_URL  = [
    "https://www.p25thfes.jp/topics/img/twitter_icon/PE_1.png",
    "https://www.p25thfes.jp/topics/img/twitter_icon/PE_2.png",
    "https://www.p25thfes.jp/topics/img/twitter_icon/PE_3.png",
    "https://www.p25thfes.jp/topics/img/twitter_icon/PE_4.png",
    "https://www.p25thfes.jp/topics/img/twitter_icon/PE_5.png",
    "https://www.p25thfes.jp/topics/img/twitter_icon/PE_6.png",
    "https://www.p25thfes.jp/topics/img/twitter_icon/PE_7.png",  
]

# ダイス
DICE = random.randrange(len(AVATAR_URL))

# タイムゾーン設定
jst_delta = datetime.timezone(datetime.timedelta(hours=9))
JST_NOW   = datetime.datetime.now(jst_delta)

class MyAwsBudgets:
    """ AWS Budgetsを取得するためのクラス（要: アカウントID, 取得対象の予算名） """
    def __init__(self, account_id, budget_name):
        self._account_id  = account_id
        self._budget_name = budget_name

        self._client   = boto3.client('budgets')
        self._response = self._client.describe_budget(
            AccountId=self._account_id,
            BudgetName=self._budget_name,
        )

    def get_budget(self):
        """ 予算額 """
        try:
            i = float(self._response['Budget']['BudgetLimit']['Amount'])
        except Exception as e:
            print(e)
            i = "???"
            
        return i
    
    def get_cost(self):
        """ 実際（前々日）の料金 """
        try:
            i = float(self._response['Budget']['CalculatedSpend']['ActualSpend']['Amount'])
        except Exception as e:
            print(e)
            i = "???"
            
        return i
    
    def get_forecast(self):
        """ 今月の予測料金 """
        try:
            i = float(self._response['Budget']['CalculatedSpend']['ForecastedSpend']['Amount'])
        except Exception as e:
            print(e)
            i = "???"
            
        return i

class DiscordWebhook:
    """ DiscordにWebhookでメッセージを飛ばすクラス （要: Webhook URL, BOT名, BOT画像） """
    def __init__(self, webhook_url, username, avatar_url):
        self._webhook_url = webhook_url
        self._username    = username
        self._avatar_url  = avatar_url

    def simple_text(self, content):
        """ テキスト送信 （要: テキスト） """
        data = {
            "username": self._username,
            "avatar_url": self._avatar_url,
            "content": content,
        }

        try:
            requests.post(self._webhook_url, data)
        except requests.exceptions.RequestException as e:
            print(e)
        
def lambda_handler(event, context):
    webhook     = DiscordWebhook(WEBHOOK_URL, USER_NAME, AVATAR_URL[DICE])
    
    aws_budgets = MyAwsBudgets(ACCOUNT_ID, BUDGET_NAME)
    #budget     = aws_budgets.get_budget()
    cost        = aws_budgets.get_cost()
    forecast    = aws_budgets.get_forecast()

    notify_data = f"**{str(JST_NOW.strftime('%m月%d日'))}**　[前々日までの合計]: `${cost}`　[月末の予測]: `${forecast}`"

    webhook.simple_text(notify_data)
