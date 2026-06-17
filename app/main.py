from fastapi import FastAPI

app = FastAPI(
    title="FastAPI Container K8s Project",
    version="0.1.0"
)

@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}