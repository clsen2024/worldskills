from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/v1/app', methods=['GET'])
def get_app():
    return jsonify({"code": "v1"})

@app.route('/health', methods=['GET'])
def get_health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)