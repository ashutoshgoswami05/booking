# 🏨 Hotel Booking API

This API provides endpoints for **user authentication**, **hotel search**, and **admin hotel management**.  
Authentication is handled via **JWT access tokens** (with refresh token support).

---

## 🔑 Authentication Flow
- **Signup/Login** → Issues an access token (JWT)
- **Refresh** → Exchanges refresh token (stored in cookie) for new access token
- **Admin routes** → Require `Authorization: Bearer <token>` header

---

## 📌 API Endpoints

### 🔐 Auth
| Method | Endpoint       | Description                          | Security |
|--------|---------------|--------------------------------------|----------|
| POST   | `/auth/signup` | Register a new user                  | ❌ No    |
| POST   | `/auth/login`  | Login user & return JWT access token | ❌ No    |
| POST   | `/auth/refresh`| Refresh access token (via cookie)    | ❌ No    |

---

### 🌍 Public Hotel APIs
| Method | Endpoint           | Description                  | Security |
|--------|-------------------|------------------------------|----------|
| GET    | `/hotels/search`   | Search hotels by city & date | ❌ No    |
| GET    | `/hotels/{id}/info`| Get detailed hotel info      | ❌ No    |

---

### 🛠️ Admin Hotel Management
| Method | Endpoint                        | Description                           | Security |
|--------|--------------------------------|---------------------------------------|----------|
| POST   | `/admin/hotels`                 | Create new hotel                      | ✅ Yes   |
| GET    | `/admin/hotels/{id}`            | Retrieve hotel by ID                  | ✅ Yes   |
| PUT    | `/admin/hotels/{id}`            | Update hotel details                  | ✅ Yes   |
| DELETE | `/admin/hotels/{id}`            | Delete hotel by ID                    | ✅ Yes   |
| PATCH  | `/admin/hotels/{id}/activate`   | Activate/Deactivate hotel             | ✅ Yes   |
| GET    | `/admin/hotels/{id}/bookings`   | Get all bookings for a hotel          | ✅ Yes   |
| GET    | `/admin/hotels/{id}/reports`    | Get booking reports between dates     | ✅ Yes   |

---

### 🏠 Room Management (Admin)
| Method | Endpoint                                   | Description                    | Security |
|--------|-------------------------------------------|--------------------------------|----------|
| POST   | `/admin/hotels/{hotelId}/rooms`           | Create a room under a hotel    | ✅ Yes   |
| GET    | `/admin/hotels/{hotelId}/rooms`           | List rooms in a hotel          | ✅ Yes   |
| PATCH  | `/admin/inventory/rooms/{roomId}`         | Update inventory for a room    | ✅ Yes   |

---

## 🛡️ Security Notes
- **Public endpoints** require no authentication.
- **Admin endpoints** require a valid JWT token in the `Authorization` header:


