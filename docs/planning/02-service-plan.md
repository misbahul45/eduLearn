# Planning — Service Implementation

## Auth (`app/api/auth.py`)

| Endpoint | Sekarang | Nanti |
|----------|----------|-------|
| `POST /login` | 501 | bcrypt verify → JWT access + refresh token |
| `POST /register` | 501 | bcrypt hash → insert user → JWT |
| `POST /refresh` | 501 | verify refresh token → rotate |
| `POST /logout` | 501 | revoke refresh token |
| `GET /me` | 501 | query user by JWT sub |

## Chat Persistence (`app/api/chat.py`, `chat_ws.py`)

- Setiap `user_message`: INSERT ke `messages` + update `conversations.updated_at`
- Setiap `final`: INSERT assistant message, update conversation summary
- `conversation_id` baru: INSERT ke `conversations`

## Predictions (`app/api/predictions.py`)

- `GET /latest`: SELECT terakhir dari `prediction_histories` WHERE user_id
- `GET /history`: SELECT range 30 hari
- `GET /analysis`: SELECT COUNT + AVG + SUM agregat

## Users (`app/api/users.py`)

- `GET /me`: dari JWT sub
- `GET /stats`: SELECT dari `conversations` + `prediction_histories`
