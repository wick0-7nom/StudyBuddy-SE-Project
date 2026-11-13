from flask import Flask, request, jsonify
from flask_cors import CORS
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation

app = Flask(__name__)
CORS(app)  # allows cross-origin requests from any device/phone

@app.route('/', methods=['GET'])
def home():
    return jsonify({'status': 'LDA Server is Live!'})

@app.route('/summarize', methods=['POST'])
def summarize():
    try:
        data = request.json
        text = data.get('text', '')

        if not text or len(text.strip()) == 0:
            return jsonify({'summary': 'No text found in the uploaded document.'}), 400

        # LDA Processing
        vectorizer = CountVectorizer(stop_words='english', max_features=1000)
        X = vectorizer.fit_transform([text])

        lda = LatentDirichletAllocation(n_components=1, random_state=42)
        lda.fit(X)

        feature_names = vectorizer.get_feature_names_out()
        top_words = [feature_names[i] for i in lda.components_[0].argsort()[:-8:-1]]

        summary = "📌 LDA Key Topic Summary:\n\n" + "\n".join([f"• {word.capitalize()}" for word in top_words])
        return jsonify({'summary': summary})

    except Exception as e:
        return jsonify({'summary': f'LDA Processing Error: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)