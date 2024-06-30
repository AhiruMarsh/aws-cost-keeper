#!/usr/bin/env python
import os
import sys

sys.path.append(os.environ["REPOSITORY_HOME"] + "/app")
import main

def test_ok():
    response = main.lambda_handler(1, 2)

    assert response["statusCode"] == 200
