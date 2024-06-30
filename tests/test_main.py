#!/usr/bin/env python
import os
import sys

import app.main

def test_ok():
    response = app.main.lambda_handler(1, 2)

    assert response["statusCode"] == 200
