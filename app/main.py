#!/usr/bin/env python
# https://github.com/satory074/awscost_to_discord_sample/blob/master/lambda_function.py
# https://cpu100per.aminchu.net/aws/aws-cost-post-to-slack/

import os
import boto3
import datetime
import json

import budgets
import discord

# タイムゾーン 設定
TIMEZONE_DELTA = datetime.timezone(datetime.timedelta(hours=9))
JST_NOW   = datetime.datetime.now(TIMEZONE_DELTA)

# AWS 設定
ACCOUNT_ID  = boto3.client("sts").get_caller_identity()["Account"]
BUDGET_NAME = os.environ['AWS_BUDGET_NAME']

# Discord 設定
WEBHOOK_URL = os.environ['DISCORD_WEBHOOK_URL']

# Webhook 設定
WEBHOOK_NAME = "AWSコスト通知"
        
def lambda_handler(event, context):
    webhook     = discord.Discord(WEBHOOK_URL, WEBHOOK_NAME)
    
    aws_budgets = budgets.AwsBudgets(ACCOUNT_ID, BUDGET_NAME)
    cost        = aws_budgets.get_actual_cost()
    forecast    = aws_budgets.get_forecast_cost()

    notify_data = f"**{str(JST_NOW.strftime('%m月%d日'))}**　[前々日までの合計]: `${cost}`　[月末の予測]: `${forecast}`" 

    response = webhook.send_text(notify_data)
    return {
        "statusCode": response.status_code,
        "body": json.dumps({
            "message": response,
        }),
    }
