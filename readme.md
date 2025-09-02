
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

## ⚙️ Infrastructure & Deployment (CI/CD)

This project uses **Terraform + GitHub Actions** to provision infrastructure and deploy the app to **AWS EKS**.

### 1️⃣ Spin up the Terraform state bucket
Run the workflow:
👉 [tf_state_infra.yaml](https://github.com/ashutoshgoswami05/booking/actions/workflows/tf_state_infra.yaml)  
This creates the **S3 bucket** + **DynamoDB table** for Terraform remote state.

### 2️⃣ Provision AWS Infrastructure
Run the workflow:
👉 [infra.yaml](https://github.com/ashutoshgoswami05/booking/actions/workflows/infra.yaml)  
This sets up the **VPC, EKS cluster, IAM roles, and networking**.

### 3️⃣ Build & Deploy Application
Run the workflow:
👉 [deployImage.yaml](https://github.com/ashutoshgoswami05/booking/actions/workflows/deployImage.yaml)  
This:
- Builds the Docker image
- Pushes it to **Amazon ECR**
- Deploys the app to **Amazon EKS** using Helm

---

## ✅ Best Practices
- Never commit sensitive values into `values.yaml`
- Use `values.secret.yaml` locally and add it to `.gitignore`
- Store sensitive config in **GitHub Actions Secrets** or **External Secrets Operator**

---

## 📖 Resources
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)
- [External Secrets Operator](https://external-secrets.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)  
