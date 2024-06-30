#!/usr/bin/env python
import random
import requests

class Discord:
    def __init__(self, webhook_url: str, username: str, avatar_url: str = None):
        """ DiscordにWebhookでメッセージを飛ばすクラス （要: Webhook URL, BOT名, BOT画像） """
        self._webhook_url = webhook_url
        self._username    = username

        # BOT画像の指定が無い場合は、以下のリストからランダムで選択する
        if (avatar_url == None):
            AVATAR_INIT_URL = [
                "https://www.p25thfes.jp/topics/img/twitter_icon/PE_1.png",
                "https://www.p25thfes.jp/topics/img/twitter_icon/PE_2.png",
                "https://www.p25thfes.jp/topics/img/twitter_icon/PE_3.png",
                "https://www.p25thfes.jp/topics/img/twitter_icon/PE_4.png",
                "https://www.p25thfes.jp/topics/img/twitter_icon/PE_5.png",
                "https://www.p25thfes.jp/topics/img/twitter_icon/PE_6.png",
                "https://www.p25thfes.jp/topics/img/twitter_icon/PE_7.png",  
            ]
            AVATAR_INIT_DICE = random.randrange(len(AVATAR_INIT_URL))
            
            self._avatar_url = AVATAR_INIT_URL[AVATAR_INIT_DICE]
        else:
            self._avatar_url  = avatar_url

    def send_text(self, content: str) -> int:
        """ テキスト送信 （要: テキスト） """
        data = {
            "username": self._username,
            "avatar_url": self._avatar_url,
            "content": content,
        }

        try:
            r = requests.post(self._webhook_url, data)
        except requests.exceptions.RequestException as e:
            raise
        
        return int(r.status_code)
