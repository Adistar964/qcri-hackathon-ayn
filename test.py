import requests

headers = {
    "Authorization": "Bearer fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz",
    "Content-Type": "application/json",
}

response = requests.get("https://api.fanar.qa/v1/models", headers=headers)

print(response.json())