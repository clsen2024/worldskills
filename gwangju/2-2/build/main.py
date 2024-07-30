from fastapi import FastAPI, Response
import uvicorn

app = FastAPI()


@app.get("/")
def return_version():
    return Response(content="This is Blue Page", status_code=200)


@app.get("/healthcheck")
def return_healthz():
    return Response(content="healthy", status_code=200)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
