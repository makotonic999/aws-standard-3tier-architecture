# Realtime Server Survival Board
from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import declarative_base, Session
from datetime import datetime
import os
import requests

app = FastAPI()

# DB接続
DB_URL = f"mysql+pymysql://{os.environ['DB_USER']}:{os.environ['DB_PASSWORD']}@{os.environ['DB_HOST']}/myappdb"
engine = create_engine(DB_URL)
Base = declarative_base()

# メッセージテーブル
class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True)
    content = Column(String(255))
    az = Column(String(50))
    created_at = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(engine)

# AZ取得
def get_az():
    try:
        uri = os.environ.get("ECS_CONTAINER_METADATA_URI_V4")
        res = requests.get(f"{uri}/task", timeout=1)
        return res.json().get("AvailabilityZone", "unknown")
    except:
        return "unknown"

# HTML
def render_html(az: str, messages: list):
    rows = "".join(f"<tr><td>{m.created_at}</td><td>{m.az}</td><td>{m.content}</td></tr>" for m in messages)
    return f"""
    <html><body>
    <h1>現在のAZ: {az}</h1>
    <form method="post" action="/post">
        <input name="content" placeholder="メッセージを入力" required>
        <button type="submit">投稿</button>
    </form>
    <table border="1">
        <tr><th>日時</th><th>AZ</th><th>メッセージ</th></tr>
        {rows}
    </table>
    </body></html>
    """

@app.get("/", response_class=HTMLResponse)
def index():
    az = get_az()
    with Session(engine) as session:
        messages = session.query(Message).order_by(Message.created_at.desc()).all()
    return render_html(az, messages)

@app.post("/post")
def post_message(content: str = Form(...)):
    az = get_az()
    with Session(engine) as session:
        session.add(Message(content=content, az=az))
        session.commit()
    from fastapi.responses import RedirectResponse
    return RedirectResponse("/", status_code=303)

@app.get("/health")
def health():
    return {"status": "healthy"}
