import requests

# api_key = "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"
api_key = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz"
image_url = "https://www.researchgate.net/profile/Sebastian-Huter/publication/346311721/figure/fig3/AS:961738669305859@1606307775884/English-version-of-the-consent-form-used-to-aquire-and-document-written-informed-consent.png"  # Your uploaded image URL

response = requests.post(
    # "https://openrouter.ai/api/v1/chat/completions",
    "https://api.fanar.qa/v1/chat/completions",
    headers={
        "Authorization": f"Bearer {api_key}",
        "HTTP-Referer": "http://localhost",  # Required
        "X-Title": "Test Qwen-VL"
    },
    json={
        # "model": "qwen/qwen-2.5-vl-7b-instruct",  # Replace with qwen2.5-vl if available
        "model": "Fanar-Oryx-IVU-1",

        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "image_url", "image_url": {"url": image_url}},
                    {"type": "text", "text": """
Give me all the text in this picture.
"""}
                ]
            }
        ]
    }
)

print(response.json())