from typing import Any

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def root() -> dict[str, Any]:
    return {"message": "Hello World"}
