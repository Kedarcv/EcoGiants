import hmac
import hashlib
import base64
import json
import logging
import os
import time
import urllib.request
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from database import get_db, init_db, calculate_level

logger = logging.getLogger("eco-giants-api")

app = FastAPI(title="Eco-Giants API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _create_livekit_jwt(video_grants: dict) -> str:
    api_key = os.environ.get("LIVEKIT_API_KEY", "APIbTNp58iUneWh")
    api_secret = os.environ.get("LIVEKIT_API_SECRET", "yDau9pZ3QPKTH3QUWbSZNdWW4CwKBUDlD4Vaf8Rer2R")
    now = int(time.time())
    header = _b64url(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    claims = _b64url(json.dumps({
        "iss": api_key, "sub": "backend", "nbf": now, "exp": now + 3600,
        "video": video_grants,
    }).encode())
    sig = _b64url(hmac.new(api_secret.encode(), f"{header}.{claims}".encode(), hashlib.sha256).digest())
    return f"{header}.{claims}.{sig}"


def _create_agent_dispatch():
    """Create a dispatch rule on LiveKit Cloud so the agent auto-joins eco-giant-* rooms."""
    try:
        livekit_host = os.environ.get("LIVEKIT_URL", "wss://eco-giants-l8flnoop.livekit.cloud")
        host = livekit_host.replace("wss://", "https://").replace("ws://", "http://")
        token = _create_livekit_jwt({
            "roomCreate": True, "roomAdmin": True, "roomList": True, "agentCreate": True,
        })
        data = json.dumps({
            "roomName": "eco-giant-*",
            "agentName": "eco-giant",
        }).encode()
        req = urllib.request.Request(
            f"{host}/twirp/livekit.AgentService/CreateDispatch",
            data=data,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        urllib.request.urlopen(req, timeout=10)
        logger.info("Agent dispatch rule created")
    except Exception as e:
        logger.warning(f"Failed to create agent dispatch rule: {e}")


@app.on_event("startup")
async def startup():
    await init_db()
    _create_agent_dispatch()
    logger.info("Database initialized")


# ── Request / Response models ─────────────────────────────────────


class RegisterRequest(BaseModel):
    student_number: str
    name: str = ""


class LoginRequest(BaseModel):
    student_number: str


class UpdatePointsRequest(BaseModel):
    student_number: str
    points: int
    category: str = "General"
    item_name: str = ""


class QuizResultRequest(BaseModel):
    student_number: str
    lesson_topic: str
    score: int
    total_questions: int
    points_earned: int


class UserResponse(BaseModel):
    id: int
    student_number: str
    name: str
    total_points: int
    eco_level: str
    current_streak: int
    max_streak: int
    rank: Optional[int] = None


class LeaderboardEntry(BaseModel):
    rank: int
    student_number: str
    name: str
    total_points: int
    eco_level: str


# ── Auth endpoints ────────────────────────────────────────────────


@app.post("/api/register")
async def register(req: RegisterRequest):
    db = await get_db()
    try:
        existing = await db.execute(
            "SELECT id FROM users WHERE student_number = ?",
            (req.student_number,),
        )
        if await existing.fetchone():
            raise HTTPException(status_code=409, detail="Student number already registered")

        cursor = await db.execute(
            "INSERT INTO users (student_number, name) VALUES (?, ?)",
            (req.student_number, req.name or req.student_number),
        )
        await db.commit()
        user_id = cursor.lastrowid

        return {
            "id": user_id,
            "student_number": req.student_number,
            "name": req.name or req.student_number,
            "total_points": 0,
            "eco_level": "Seedling",
            "current_streak": 0,
            "max_streak": 0,
        }
    finally:
        await db.close()


@app.post("/api/login")
async def login(req: LoginRequest):
    db = await get_db()
    try:
        row = await db.execute(
            "SELECT * FROM users WHERE student_number = ?",
            (req.student_number,),
        )
        user = await row.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Student not found. Please register first.")

        return dict(user)
    finally:
        await db.close()


@app.get("/api/user/{student_number}")
async def get_user(student_number: str):
    db = await get_db()
    try:
        row = await db.execute(
            "SELECT * FROM users WHERE student_number = ?",
            (student_number,),
        )
        user = await row.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get rank
        rank_row = await db.execute(
            """SELECT COUNT(*) + 1 as rank FROM users
               WHERE total_points > (SELECT total_points FROM users WHERE student_number = ?)""",
            (student_number,),
        )
        rank_result = await rank_row.fetchone()

        return {
            **dict(user),
            "rank": rank_result["rank"] if rank_result else None,
        }
    finally:
        await db.close()


# ── Points / Progress ─────────────────────────────────────────────


@app.post("/api/points/add")
async def add_points(req: UpdatePointsRequest):
    db = await get_db()
    try:
        row = await db.execute(
            "SELECT * FROM users WHERE student_number = ?",
            (req.student_number,),
        )
        user = await row.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        new_total = user["total_points"] + req.points
        new_level = calculate_level(new_total)

        # Update streak
        today = datetime.now().strftime("%Y-%m-%d")
        last_active = user["last_active_date"]
        current_streak = user["current_streak"]
        max_streak = user["max_streak"]

        if last_active != today:
            if last_active:
                from datetime import date, timedelta
                last_date = date.fromisoformat(last_active)
                today_date = date.today()
                if (today_date - last_date).days == 1:
                    current_streak += 1
                elif (today_date - last_date).days > 1:
                    current_streak = 1
            else:
                current_streak = 1

            if current_streak > max_streak:
                max_streak = current_streak

        await db.execute(
            """UPDATE users SET
               total_points = ?, eco_level = ?, current_streak = ?,
               max_streak = ?, last_active_date = ?, updated_at = datetime('now')
               WHERE student_number = ?""",
            (new_total, new_level, current_streak, max_streak, today, req.student_number),
        )

        # Record disposal
        await db.execute(
            "INSERT INTO disposals (user_id, category, item_name, points_earned, verified) VALUES (?, ?, ?, ?, 1)",
            (user["id"], req.category, req.item_name, req.points),
        )

        await db.commit()

        return {
            "total_points": new_total,
            "eco_level": new_level,
            "current_streak": current_streak,
            "max_streak": max_streak,
            "points_added": req.points,
        }
    finally:
        await db.close()


@app.post("/api/quiz/submit")
async def submit_quiz(req: QuizResultRequest):
    db = await get_db()
    try:
        row = await db.execute(
            "SELECT * FROM users WHERE student_number = ?",
            (req.student_number,),
        )
        user = await row.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        new_total = user["total_points"] + req.points_earned
        new_level = calculate_level(new_total)

        await db.execute(
            "UPDATE users SET total_points = ?, eco_level = ?, updated_at = datetime('now') WHERE student_number = ?",
            (new_total, new_level, req.student_number),
        )

        await db.execute(
            "INSERT INTO quiz_results (user_id, lesson_topic, score, total_questions, points_earned) VALUES (?, ?, ?, ?, ?)",
            (user["id"], req.lesson_topic, req.score, req.total_questions, req.points_earned),
        )

        await db.commit()

        return {
            "total_points": new_total,
            "eco_level": new_level,
            "points_added": req.points_earned,
        }
    finally:
        await db.close()


# ── Leaderboard ───────────────────────────────────────────────────


@app.get("/api/leaderboard")
async def get_leaderboard(limit: int = 50):
    db = await get_db()
    try:
        rows = await db.execute(
            """SELECT student_number, name, total_points, eco_level
               FROM users ORDER BY total_points DESC LIMIT ?""",
            (limit,),
        )
        entries = await rows.fetchall()

        return [
            {
                "rank": i + 1,
                "student_number": e["student_number"],
                "name": e["name"],
                "total_points": e["total_points"],
                "eco_level": e["eco_level"],
            }
            for i, e in enumerate(entries)
        ]
    finally:
        await db.close()


# ── LiveKit Token ─────────────────────────────────────────────────


@app.post("/api/livekit/token")
async def get_livekit_token(body: dict):
    """Generate a LiveKit access token for the student to join a room."""
    import jwt
    import time
    import os

    student_number = body.get("student_number", "anonymous")
    room_name = body.get("room_name")
    if not room_name:
        room_name = f"eco-giant-{student_number}"

    api_key = os.environ.get("LIVEKIT_API_KEY", "APIbTNp58iUneWh")
    api_secret = os.environ.get("LIVEKIT_API_SECRET", "yDau9pZ3QPKTH3QUWbSZNdWW4CwKBUDlD4Vaf8Rer2R")

    now = int(time.time())
    payload = {
        "iss": api_key,
        "sub": f"student-{student_number}",
        "nbf": now,
        "exp": now + 21600,
        "video": {
            "room": room_name,
            "roomJoin": True,
            "canPublish": True,
            "canSubscribe": True,
            "canPublishData": True,
        },
    }

    token = jwt.encode(payload, api_secret, algorithm="HS256")

    return {
        "url": os.environ.get("LIVEKIT_URL", "wss://eco-giants-l8flnoop.livekit.cloud"),
        "token": token,
        "room": room_name,
    }


# ── Health ────────────────────────────────────────────────────────


@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "eco-giants-api"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
