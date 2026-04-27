from flask import Flask, request, jsonify
from PIL import Image
from transformers import DonutProcessor, VisionEncoderDecoderModel
import torch
import re
import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from sklearn.linear_model import LinearRegression
from datetime import datetime
import pytesseract
import numpy as np
# ================= TESSERACT PATH =================
pytesseract.pytesseract.tesseract_cmd = r"D:\Pro Files\tesseract.exe"

# ================= Firebase =================
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ================= Flask =================
app = Flask(__name__)

@app.route("/", methods=["GET"])
def home():
    return "Server running"

# ================= Donut OCR =================
MODEL_NAME = "naver-clova-ix/donut-base-finetuned-docvqa"
print("Loading Donut model...")
processor = DonutProcessor.from_pretrained(MODEL_NAME)
model = VisionEncoderDecoderModel.from_pretrained(MODEL_NAME)

device = "cuda" if torch.cuda.is_available() else "cpu"
model.to(device)

# ================= Helper =================
def run_query(image, question):
    pixel_values = processor(image, return_tensors="pt").pixel_values
    prompt = f"<s_docvqa><s_question>{question}</s_question><s_answer>"
    decoder_ids = processor.tokenizer(
        prompt,
        return_tensors="pt",
        add_special_tokens=False
    ).input_ids

    out = model.generate(
        pixel_values.to(device),
        decoder_input_ids=decoder_ids.to(device),
        max_length=model.decoder.config.max_position_embeddings,
        pad_token_id=processor.tokenizer.pad_token_id,
        eos_token_id=processor.tokenizer.eos_token_id,
    )

    seq = processor.batch_decode(out)[0]
    seq = seq.replace(processor.tokenizer.eos_token, "").replace(processor.tokenizer.pad_token, "")
    return re.sub(r"<.*?>", "", seq).strip()

def normalize_amount(s):
    if not s:
        return None
    s = re.sub(r"[^\d.]", "", s)
    try:
        return float(s)
    except:
        return None

def guess_category(text):
    t = text.lower()
    rules = [
        ("grocery|mart|milk|veg", "Groceries"),
        ("hotel|restaurant|food|cafe", "Food"),
        ("petrol|diesel|fuel", "Transport"),
        ("electric|water|wifi|eb", "Bills"),
        ("hospital|medical|pharmacy", "Health"),
        ("movie|cinema", "Entertainment"),
        ("amazon|flipkart|shopping|mall", "Shopping"),
    ]
    for r, c in rules:
        if re.search(r, t):
            return c
    return "Other"

# ---------------- Extract ----------------
@app.route("/extract", methods=["POST"])
def extract():
    try:
        print("EXTRACT API CALLED")

        file = request.files.get("file")
        if not file:
            return jsonify({"error": "file missing"}), 400

        # LOAD + FORCE SMALL SIZE
        img = Image.open(file).convert("RGB")
        img = img.resize((512, 512))   # ✅ FIXED SIZE (VERY IMPORTANT)

        #  LOW MEMORY FORMAT
        img = np.array(img).astype("uint8")
        img = Image.fromarray(img)

        # OCR text
        raw = pytesseract.image_to_string(img)

        # REDUCED MODEL CALLS (important)
        amount = normalize_amount(run_query(img, "total amount"))
        merchant = run_query(img, "merchant name")
        date = ""  # skip to save memory

        merchant = re.sub(r"(merchant name|store name|shop name|:)", "", merchant, flags=re.I).strip()
        merchant = merchant.title() if merchant else "Unknown"

        category = guess_category(raw + merchant)

        return jsonify({
            "merchant": merchant,
            "amount": amount,
            "date": date,
            "category": category
        })

    except Exception as e:
        print("EXTRACT ERROR:", e)

        #  NEVER RETURN 500 (prevents frontend crash)
        return jsonify({
            "merchant": "Unknown",
            "amount": 0,
            "date": "",
            "category": "Other",
            "error": str(e)
        }), 200

# ================= Predict Category Wise =================
@app.route("/predict", methods=["POST"])
def predict():
    try:
        print("PREDICT API CALLED")

        body = request.json or {}
        user_id = body.get("user_id")

        if not user_id:
            return jsonify({"error": "user_id required"}), 400

        print("USER ID:", user_id)

        docs = db.collection("users") \
            .document(user_id) \
            .collection("transactions") \
            .where("isExpense", "==", True) \
            .stream()

        rows = []

        for d in docs:
            x = d.to_dict()

            if "amount" not in x or "date" not in x or "categoryName" not in x:
                continue

            try:
                dt = x["date"]
                if not isinstance(dt, datetime):
                    dt = dt.to_datetime()

                rows.append({
                    "date": dt,
                    "amount": float(x["amount"]),
                    "category": str(x["categoryName"]).strip()
                })
            except Exception as inner_e:
                print("Skipping bad doc:", inner_e)
                continue

        print("TOTAL VALID ROWS:", len(rows))

        if not rows:
            return jsonify({"category_predictions": {}})

        df = pd.DataFrame(rows)
        df["month"] = df["date"].dt.to_period("M")

        predictions = {}

        categories = df["category"].dropna().unique()
        print("CATEGORIES FOUND:", categories)

        for cat in categories:
            cat_df = df[df["category"] == cat]

            monthly = (
                cat_df.groupby("month")["amount"]
                .sum()
                .sort_index()
                .reset_index()
            )

            print(f"Category: {cat}, Monthly rows: {len(monthly)}")

            # If only 1 month data → use same amount
            if len(monthly) == 1:
                predictions[cat] = round(float(monthly["amount"].iloc[0]), 2)
                continue

            # If 2 or 3 months data → use average
            if len(monthly) < 4:
                avg = monthly["amount"].mean()
                predictions[cat] = round(float(avg), 2)
                continue

            # If enough data → linear regression
            monthly["idx"] = range(len(monthly))

            X = monthly[["idx"]]
            y = monthly["amount"]

            lr = LinearRegression()
            lr.fit(X, y)

            next_idx = monthly["idx"].max() + 1
            pred = lr.predict([[next_idx]])[0]
            pred = max(pred, 0)

            predictions[cat] = round(float(pred), 2)

        print("FINAL PREDICTIONS:", predictions)

        return jsonify({
            "category_predictions": predictions
        })

    except Exception as e:
        print("PREDICT ERROR:", e)
        return jsonify({"error": str(e)}), 500

# ================= Main =================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)