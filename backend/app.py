import os

from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

app = Flask(__name__)
CORS(app)

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.getenv("OPENROUTER_API_KEY"),
)


@app.route("/ask", methods=["POST"])
@app.route("/api/ask", methods=["POST"])
def ask():

    try:
        data = request.get_json()

        question = data.get("question", "").strip()
        mode = data.get("mode", "Explain")

        if not question:
            return jsonify({
                "error": "Question is required"
            }), 400

        instructions = {
            "Explain": (
                "Explain the topic clearly for a college student. "
                "Break difficult concepts into simple parts. "
                "Use examples where useful."
            ),

            "Summarize": (
                "Summarize the topic concisely. "
                "Focus only on the most important points. "
                "Use bullet points when appropriate."
            ),

            "Quiz": (
                "Create a study quiz based on the topic. "
                "Create 5 questions with four options each. "
                "Clearly indicate the correct answer after each question."
            ),

            "Notes": (
                "Create well-structured study notes about the topic. "
                "Use headings, bullet points, definitions, examples, "
                "and important points."
            ),
        }

        system_instruction = instructions.get(
            mode,
            instructions["Explain"]
        )

        response = client.chat.completions.create(
            model="openai/gpt-5.6-luna",
            max_tokens=2048,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are an AI Study Assistant.\n\n"
                        + system_instruction
                    ),
                },
                {
                    "role": "user",
                    "content": question,
                },
            ],
        )

        answer = response.choices[0].message.content

        return jsonify({
            "answer": answer,
            "mode": mode,
        })

    except Exception as e:

        print("Error:", e)

        return jsonify({
            "error": str(e)
        }), 500


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )