import requests

api_key = "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"
# api_key = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz"
image_url = "https://files.catbox.moe/7np2cc.jpeg"  # Your uploaded image URL

response = requests.post(
    "https://openrouter.ai/api/v1/chat/completions",
    # "https://api.fanar.qa/v1/chat/completions",
    headers={
        "Authorization": f"Bearer {api_key}",
        "HTTP-Referer": "http://localhost",  # Required
        "X-Title": "Test Qwen-VL"
    },
    json={
        "model": "qwen/qwen-2.5-vl-7b-instruct",  # Replace with qwen2.5-vl if available
        # "model": "Fanar-Oryx-IVU-1",

        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "image_url", "image_url": {"url": image_url}},
                    {"type": "text", "text": """
        You are a strict visual OCR tool. Your only job is to extract the most prominent brand name from a medicine box image.

        You must:
        - ONLY return the brand name (e.g., Panadol, Dermadep)
        - NEVER explain, rephrase, or add commentary
        - NEVER output anything except the name itself
        - NEVER return full sentences or parentheses

        If the image is blurry or unclear, return exactly:
        Unable to identify medicine name. Please try again by placing the front of the box clearly in front of the camera.

        If more than one box is shown, return exactly:
        Multiple medicine boxes detected. Please show only one medicine at a time.

        If the brand name contains symbols like ®️ or ™️, Do not include them.

        ❗IMPORTANT: Return the name exactly as shown, with no commentary. Do NOT say “Note: ...”, do NOT talk like a chatbot.

"""}
                ]
            }
        ]
    }
)

print(response.json())