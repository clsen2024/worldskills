from flask import Flask, request, jsonify, make_response
import jwt
import datetime
import base64
import json

app = Flask(__name__)

SECRET_KEY = 'jwtsecret'

@app.route('/v1/token', methods=['GET'])
def get_token():
    payload = {
        'isAdmin': False,
        'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return jsonify({'token': token})

@app.route('/v1/token/verify', methods=['GET'])
def verify_token():
    token = request.headers.get('Authorization')
    if not token:
        return make_response('Token is missing', 403)

    decoded = jwt.decode(token, options={"verify_signature": False})
    isAdmin = decoded.get('isAdmin', False)
    if isAdmin:
        return 'You are admin!'
    else:
        return 'You are not permitted'

@app.route('/v1/token/none', methods=['GET'])
def get_none_alg_token():
    payload = {
        'isAdmin': True,
        'exp': (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)).timestamp()
    }

    header = {
        'alg': 'none',
        'typ': 'JWT'
    }

    encoded_header = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
    encoded_payload = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")

    token = f"{encoded_header}.{encoded_payload}."
    return jsonify({'token': token})

@app.route('/healthcheck', methods=['GET'])
def health_check():
    return make_response('ok', 200)

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)