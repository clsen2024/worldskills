from flask import Flask, request, render_template
import time
import socket
import sys
from datetime import datetime, timedelta

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/healthcheck')
def health():
    return '{"status": "200 OK"}'

@app.route('/request')
def request_info():
    want = request.args.get('want', '')

    if want == 'time':

        current_time = datetime.now()
        current_time -= timedelta(hours=3)
        current_time_str = current_time.strftime("%Y-%m-%d %H:%M:%S")
        return f"Current time is: {current_time_str}"

    elif want == 'myip':
        ip_address = socket.gethostbyname(socket.gethostname())
        return f"My IP address is: {ip_address}"

    else:
        return "Invalid request. Please provide 'want=time' or 'want=myip' in the query string."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
