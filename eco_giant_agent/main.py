import asyncio
import base64
import json
import logging
import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

from database import get_db, init_db, calculate_level
from gemini_live import GeminiLive

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("eco-giants-api")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

app = FastAPI(title="Eco-Giants API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup():
    await init_db()
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


@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "eco-giants-api"}


# ── Gemini Live WebSocket ─────────────────────────────────────────


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info("Gemini Live WebSocket connected")

    audio_input_queue = asyncio.Queue()
    video_input_queue = asyncio.Queue()
    text_input_queue = asyncio.Queue()

    async def audio_output_callback(data):
        await websocket.send_bytes(data)

    gemini_client = GeminiLive(
        api_key=GEMINI_API_KEY,
        model=os.getenv("GEMINI_MODEL", "gemini-3.1-flash-live-preview"),
        input_sample_rate=16000,
    )

    async def receive_from_client():
        try:
            while True:
                message = await websocket.receive()
                if message.get("bytes"):
                    await audio_input_queue.put(message["bytes"])
                elif message.get("text"):
                    try:
                        payload = json.loads(message["text"])
                        if isinstance(payload, dict):
                            if payload.get("type") == "image":
                                image_data = base64.b64decode(payload["data"])
                                await video_input_queue.put(image_data)
                                continue
                    except json.JSONDecodeError:
                        pass
                    await text_input_queue.put(message["text"])
        except WebSocketDisconnect:
            logger.info("WebSocket disconnected")
        except Exception as e:
            logger.error(f"Error receiving from client: {e}")

    receive_task = asyncio.create_task(receive_from_client())

    async def run_session():
        async for event in gemini_client.start_session(
            audio_input_queue=audio_input_queue,
            video_input_queue=video_input_queue,
            text_input_queue=text_input_queue,
            audio_output_callback=audio_output_callback,
        ):
            if event:
                await websocket.send_json(event)

    try:
        await run_session()
    except Exception as e:
        import traceback
        logger.error(f"Gemini session error: {type(e).__name__}: {e}\n{traceback.format_exc()}")
    finally:
        receive_task.cancel()
        try:
            await websocket.close()
        except:
            pass


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
