# Dự Án Quản Lý Kho (PTUD)

Hệ thống Quản lý Danh mục Kho được xây dựng theo mô hình 3 lớp (**Boundary - Control - Entity** / **MVC**) trong môn Phân tích Thiết kế Ứng dụng.

---

## 1. Cấu trúc dự án

```
QuanLyKho/
├── backend-quanlykho/           # Backend (Node.js Express + PostgreSQL)
│   ├── Controllers/
│   │   └── Ctrl_QuanLyKho.js    # Lớp Điều khiển (Control)
│   ├── models/
│   │   └── Kho.js               # Lớp Thực thể (Entity) - truy vấn wms.kho
│   ├── Router/
│   │   └── server.js            # Khởi tạo API Server Express
│   ├── db.js                    # Kết nối cơ sở dữ liệu PostgreSQL
│   ├── .env                     # File cấu hình biến môi trường
│   ├── .env.example             # File mẫu biến môi trường
│   └── package.json
│
└── frontend-quanlykho/          # Frontend (React 19 + Vite)
    ├── src/
    │   ├── components/
    │   │   └── GD_QuanLyKho.jsx # Lớp Giao diện (Boundary)
    │   ├── App.jsx
    │   └── main.jsx
    ├── index.html
    └── package.json
```

---

## 2. Cấu hình và khởi chạy

### A. Khởi chạy Backend
```bash
cd backend-quanlykho

# Cài đặt thư viện (nếu chưa cài)
npm install

# Khởi chạy server (chạy ở cổng 5000)
npm start
# hoặc chế độ dev tự reload:
npm run dev
```

### B. Khởi chạy Frontend
```bash
cd frontend-quanlykho

# Cài đặt thư viện (nếu chưa cài)
npm install

# Khởi chạy ứng dụng web Vite
npm run dev
```

Mở trình duyệt truy cập: `http://localhost:5173`
