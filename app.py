from flask import Flask

counter = 0

app = Flask(__name__)

@app.route("/")
def code():
    return "<h1>Hello</h1>"

@app.route("/health")
def health():
    return "OK"

@app.route("/counter")
def counter_route():
    global counter
    counter = counter + 1
    return str(counter)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
