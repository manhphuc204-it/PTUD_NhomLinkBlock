# API Contract — Phân hệ Quản trị hệ thống

> Phiên bản: 1.0 · Ngày tạo: 2026-11-17
> Nguồn BA: `ThucHanh/TH Tuan2/QuanLyTaiKhoan_BaoTriHeThong.docx`
> Nguồn DB: `backend/db/migrations/001_admin_module.sql`

---

## 1. Quy ước chung

### 1.1 Base URL

```
/api/v1
```

### 1.2 Xác thực

| Middleware          | Mô tả                                                                                        |
| ------------------- | --------------------------------------------------------------------------------------------- |
| `authenticate`      | Kiểm tra JWT trong cookie `token` (httpOnly). Trả `401` nếu thiếu hoặc hết hạn.              |
| `requireAdmin`      | Chạy sau `authenticate`. Kiểm tra `ma_vai_tro === 'QUAN_TRI'`. Trả `403` nếu không đủ quyền. |
| `maintenanceGuard`  | Chạy trước mọi route (trừ auth). Nếu `CHE_DO_BAO_TRI = 'true'` và user không phải `QUAN_TRI`, trả `503`. |

### 1.3 Định dạng response thành công

```jsonc
{
  "success": true,
  "message": "Thông báo tiếng Việt theo BA",
  "data": { /* payload */ }
}
```

### 1.4 Định dạng response lỗi (thống nhất)

```jsonc
{
  "success": false,
  "message": "Thông báo lỗi tiếng Việt theo BA",
  "errors": [                           // chỉ có khi lỗi validation
    { "field": "ten_dang_nhap", "message": "Tên đăng nhập là bắt buộc" }
  ]
}
```

### 1.5 Quy tắc bảo mật

- **Mọi response KHÔNG BAO GIỜ chứa trường `mat_khau`.**
- JWT lưu trong cookie `token` với flag `httpOnly`, `secure` (production), `sameSite: 'strict'`.
- Mật khẩu hash bằng `bcrypt` với salt round ≥ 10.

### 1.6 Nhật ký hệ thống

- Endpoint nhật ký **chỉ có GET** (chỉ đọc, không tạo/sửa/xóa qua API).
- Mọi thao tác **thay đổi dữ liệu** (tạo, sửa, xóa tài khoản, bật/tắt bảo trì, sao lưu, phục hồi) và **đăng nhập / đăng xuất** đều tự động ghi vào bảng `nhat_ky_he_thong` ở tầng service.
- Ghi nhật ký **kể cả khi thao tác thất bại** (vd: sao lưu thất bại vẫn ghi log).
- Mỗi bản ghi nhật ký lưu: `hanh_dong`, `noi_dung`, `dia_chi_ip`, `ma_tai_khoan`, `ten_dang_nhap_luc_do`.

### 1.7 Phân trang

Các endpoint danh sách hỗ trợ query parameters:

| Param     | Kiểu     | Mặc định | Mô tả                               |
| --------- | -------- | -------- | ------------------------------------ |
| `trang`   | `number` | `1`      | Số trang (bắt đầu 1)                |
| `so_dong` | `number` | `20`     | Số dòng mỗi trang (tối đa 100)      |

Response phân trang bọc trong:

```jsonc
{
  "success": true,
  "data": {
    "ds": [ /* mảng items */ ],
    "phan_trang": {
      "trang": 1,
      "so_dong": 20,
      "tong_dong": 150,
      "tong_trang": 8
    }
  }
}
```

### 1.8 Mã trạng thái HTTP

| Mã  | Ý nghĩa                              |
| --- | ------------------------------------- |
| 200 | Thành công                            |
| 201 | Tạo mới thành công                    |
| 400 | Dữ liệu không hợp lệ (validation)    |
| 401 | Chưa đăng nhập / token hết hạn        |
| 403 | Không có quyền                         |
| 404 | Không tìm thấy tài nguyên             |
| 409 | Xung đột (vd: tên đăng nhập trùng)    |
| 500 | Lỗi server                            |
| 503 | Hệ thống đang bảo trì                 |

---

## 2. Module Auth (Đăng nhập / Đăng xuất / Quên & đặt lại mật khẩu)

### 2.1 Đăng nhập

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `POST` |
| **Path** | `/api/v1/auth/dang-nhap` |
| **Quyền** | Công khai (không cần authenticate) |

**Request body — Zod schema:**

```ts
const dangNhapSchema = z.object({
  ten_dang_nhap: z.string().min(1, "Tên đăng nhập là bắt buộc"),
  mat_khau:      z.string().min(1, "Mật khẩu là bắt buộc"),
});
```

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Đăng nhập thành công",
  "data": {
    "ma_tai_khoan": "TK001",
    "ten_dang_nhap": "admin",
    "ho_ten": "Quản trị hệ thống",
    "email": "admin@kho.local",
    "ma_vai_tro": "QUAN_TRI",
    "ten_vai_tro": "Quản trị viên"
  }
}
// + Set-Cookie: token=<JWT>; HttpOnly; Path=/; SameSite=Strict
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | *(lỗi validation từ zod)* | Thiếu trường bắt buộc |
| 401 | `Tên đăng nhập hoặc mật khẩu không đúng` | Sai username hoặc password |
| 401 | `Tài khoản đã bị khóa` | `trang_thai = 'KHOA'` |
| 503 | `Hệ thống đang trong chế độ bảo trì` | `CHE_DO_BAO_TRI = 'true'` và user không phải QUAN_TRI |

---

### 2.2 Đăng xuất

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `POST` |
| **Path** | `/api/v1/auth/dang-xuat` |
| **Quyền** | `authenticate` |

**Request body:** Không có.

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Đăng xuất thành công"
}
// + Set-Cookie: token=; HttpOnly; Path=/; Max-Age=0
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Thiếu / sai token |

---

### 2.3 Quên mật khẩu

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `POST` |
| **Path** | `/api/v1/auth/quen-mat-khau` |
| **Quyền** | Công khai |

**Request body — Zod schema:**

```ts
const quenMatKhauSchema = z.object({
  email: z.string().email("Email không hợp lệ"),
});
```

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Nếu email tồn tại trong hệ thống, hướng dẫn đặt lại mật khẩu đã được gửi"
}
```

> **Lưu ý bảo mật:** Luôn trả cùng một message dù email có tồn tại hay không, tránh lộ thông tin tài khoản.

**Logic phía server:**
- Tìm tài khoản theo `email`.
- Nếu tồn tại: tạo token ngẫu nhiên, hash lưu vào `token_dat_lai_mat_khau` với `het_han = NOW() + 30 phút`, gửi email (hoặc log ra console trong dev).
- Nếu không tồn tại: vẫn trả `200` với cùng message.

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | *(lỗi validation từ zod)* | Email không hợp lệ |

---

### 2.4 Đặt lại mật khẩu

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `POST` |
| **Path** | `/api/v1/auth/dat-lai-mat-khau` |
| **Quyền** | Công khai |

**Request body — Zod schema:**

```ts
const datLaiMatKhauSchema = z.object({
  token:        z.string().min(1, "Token là bắt buộc"),
  mat_khau_moi: z.string().min(6, "Mật khẩu phải có ít nhất 6 ký tự"),
});
```

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Đặt lại mật khẩu thành công"
}
```

**Logic phía server:**
- Hash token gửi lên, so khớp với `token_hash` trong `token_dat_lai_mat_khau`.
- Kiểm tra `het_han > NOW()` và `da_su_dung = false`.
- Nếu hợp lệ: hash mật khẩu mới bằng bcrypt, cập nhật `tai_khoan.mat_khau`, đánh dấu `da_su_dung = true`.

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | *(lỗi validation từ zod)* | Thiếu trường / mật khẩu quá ngắn |
| 400 | `Token không hợp lệ hoặc đã hết hạn` | Token sai, hết hạn, hoặc đã sử dụng |

---

## 3. Module Users — Quản lý tài khoản (US-01 → US-05)

### 3.1 US-01 · Xem danh sách tài khoản

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `GET` |
| **Path** | `/api/v1/admin/tai-khoan` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Query parameters (tùy chọn):**

| Param        | Kiểu     | Mô tả                                           |
| ------------ | -------- | ------------------------------------------------ |
| `trang`      | `number` | Trang hiện tại                                   |
| `so_dong`    | `number` | Số dòng mỗi trang                                |
| `tim_kiem`   | `string` | Tìm theo `ten_dang_nhap` hoặc `ho_ten` (ILIKE)  |
| `trang_thai` | `string` | Lọc: `HOAT_DONG` hoặc `KHOA`                    |
| `ma_vai_tro` | `string` | Lọc theo vai trò                                 |

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "data": {
    "ds": [
      {
        "ma_tai_khoan": "TK001",
        "ten_dang_nhap": "admin",
        "ho_ten": "Quản trị hệ thống",
        "email": "admin@kho.local",
        "so_dien_thoai": "0900000001",
        "trang_thai": "HOAT_DONG",
        "ma_vai_tro": "QUAN_TRI",
        "ten_vai_tro": "Quản trị viên"
      }
      // ... (KHÔNG có trường mat_khau)
    ],
    "phan_trang": {
      "trang": 1,
      "so_dong": 20,
      "tong_dong": 7,
      "tong_trang": 1
    }
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |

---

### 3.2 Xem chi tiết tài khoản (hỗ trợ cho form cập nhật)

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `GET` |
| **Path** | `/api/v1/admin/tai-khoan/:maTaiKhoan` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "data": {
    "ma_tai_khoan": "TK003",
    "ten_dang_nhap": "nv.kho01",
    "ho_ten": "Nguyễn Văn An",
    "email": "an.nv@kho.local",
    "so_dien_thoai": "0900000003",
    "trang_thai": "HOAT_DONG",
    "ma_vai_tro": "NHAN_VIEN_KHO",
    "ten_vai_tro": "Nhân viên kho"
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 404 | `Không tìm thấy tài khoản` | `maTaiKhoan` không tồn tại |

---

### 3.3 Danh sách vai trò (hỗ trợ dropdown form)

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `GET` |
| **Path** | `/api/v1/admin/vai-tro` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "data": [
    { "ma_vai_tro": "QUAN_TRI",         "ten_vai_tro": "Quản trị viên" },
    { "ma_vai_tro": "NHAN_VIEN_KHO",    "ten_vai_tro": "Nhân viên kho" },
    { "ma_vai_tro": "BO_PHAN_MUA_HANG", "ten_vai_tro": "Bộ phận mua hàng" },
    { "ma_vai_tro": "BAN_GIAM_DOC",     "ten_vai_tro": "Ban giám đốc" },
    { "ma_vai_tro": "XUONG_SAN_XUAT",   "ten_vai_tro": "Xưởng sản xuất" }
  ]
}
```

---

### 3.4 US-02 · Thêm tài khoản

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `POST` |
| **Path** | `/api/v1/admin/tai-khoan` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body — Zod schema:**

```ts
const themTaiKhoanSchema = z.object({
  ten_dang_nhap: z.string()
    .min(3, "Tên đăng nhập phải có ít nhất 3 ký tự")
    .max(100, "Tên đăng nhập tối đa 100 ký tự")
    .regex(/^[a-zA-Z0-9._]+$/, "Tên đăng nhập chỉ chứa chữ, số, dấu chấm và gạch dưới"),
  mat_khau: z.string()
    .min(6, "Mật khẩu phải có ít nhất 6 ký tự"),
  ho_ten: z.string()
    .min(1, "Họ tên là bắt buộc")
    .max(150, "Họ tên tối đa 150 ký tự"),
  email: z.string()
    .email("Email không hợp lệ")
    .max(150)
    .optional()
    .or(z.literal("")),
  so_dien_thoai: z.string()
    .max(20, "Số điện thoại tối đa 20 ký tự")
    .optional()
    .or(z.literal("")),
  ma_vai_tro: z.string()
    .min(1, "Vai trò là bắt buộc"),
});
```

**Response thành công — `201`:**

```jsonc
{
  "success": true,
  "message": "Thêm tài khoản thành công",
  "data": {
    "ma_tai_khoan": "TK008",
    "ten_dang_nhap": "nv.moi",
    "ho_ten": "Người Mới",
    "email": "moi@kho.local",
    "so_dien_thoai": "0900000008",
    "trang_thai": "HOAT_DONG",
    "ma_vai_tro": "NHAN_VIEN_KHO",
    "ten_vai_tro": "Nhân viên kho"
  }
}
```

> `ma_tai_khoan` do server tự sinh (format `TKxxx`, auto-increment).

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | *(lỗi validation từ zod)* | Dữ liệu không hợp lệ hoặc thiếu |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 409 | `Tên đăng nhập đã tồn tại` | `ten_dang_nhap` trùng với tài khoản khác |

---

### 3.5 US-03 · Cập nhật tài khoản

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `PUT` |
| **Path** | `/api/v1/admin/tai-khoan/:maTaiKhoan` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body — Zod schema:**

```ts
const capNhatTaiKhoanSchema = z.object({
  ho_ten: z.string()
    .min(1, "Họ tên là bắt buộc")
    .max(150, "Họ tên tối đa 150 ký tự"),
  email: z.string()
    .email("Email không hợp lệ")
    .max(150)
    .optional()
    .or(z.literal("")),
  so_dien_thoai: z.string()
    .max(20, "Số điện thoại tối đa 20 ký tự")
    .optional()
    .or(z.literal("")),
  ma_vai_tro: z.string()
    .min(1, "Vai trò là bắt buộc"),
  mat_khau: z.string()
    .min(6, "Mật khẩu phải có ít nhất 6 ký tự")
    .optional()
    .or(z.literal("")),
});
```

> **Lưu ý:** `ten_dang_nhap` **không được phép cập nhật** (không có trong schema).
> Trường `mat_khau` là tùy chọn — nếu gửi chuỗi rỗng hoặc không gửi thì giữ nguyên mật khẩu cũ.

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Cập nhật tài khoản thành công",
  "data": {
    "ma_tai_khoan": "TK003",
    "ten_dang_nhap": "nv.kho01",
    "ho_ten": "Nguyễn Văn An (sửa)",
    "email": "an.nv@kho.local",
    "so_dien_thoai": "0900000003",
    "trang_thai": "HOAT_DONG",
    "ma_vai_tro": "NHAN_VIEN_KHO",
    "ten_vai_tro": "Nhân viên kho"
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | *(lỗi validation từ zod)* | Dữ liệu không hợp lệ |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 404 | `Không tìm thấy tài khoản` | `maTaiKhoan` không tồn tại |

---

### 3.6 US-04 · Xóa tài khoản

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `DELETE` |
| **Path** | `/api/v1/admin/tai-khoan/:maTaiKhoan` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body:** Không có.

**Logic nghiệp vụ:**
1. Kiểm tra tài khoản tồn tại.
2. Không cho phép xóa chính mình (tài khoản đang đăng nhập).
3. Kiểm tra xem tài khoản có dữ liệu liên quan trong `nhat_ky_he_thong` hoặc `ban_sao_luu` không.
   - **Nếu có:** trả lỗi `409` và đề nghị khóa thay vì xóa.
   - **Nếu không có:** xóa tài khoản khỏi CSDL.

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Xóa tài khoản thành công"
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | `Không thể xóa tài khoản của chính mình` | `maTaiKhoan` = tài khoản đang đăng nhập |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 404 | `Không tìm thấy tài khoản` | `maTaiKhoan` không tồn tại |
| 409 | `Không thể xóa tài khoản vì đang có dữ liệu liên quan. Bạn có muốn khóa tài khoản này không?` | Có nhật ký hoặc bản sao lưu tham chiếu |
| 500 | `Xóa tài khoản thất bại` | Lỗi CSDL |

---

### 3.7 US-05 · Khóa tài khoản

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `PATCH` |
| **Path** | `/api/v1/admin/tai-khoan/:maTaiKhoan/khoa` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body:** Không có.

**Logic:** Đặt `trang_thai = 'KHOA'`. Không cho phép khóa chính mình.

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Khóa tài khoản thành công",
  "data": {
    "ma_tai_khoan": "TK003",
    "trang_thai": "KHOA"
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | `Không thể khóa tài khoản của chính mình` | `maTaiKhoan` = tài khoản đang đăng nhập |
| 400 | `Tài khoản đã ở trạng thái khóa` | `trang_thai` đã là `KHOA` |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 404 | `Không tìm thấy tài khoản` | `maTaiKhoan` không tồn tại |

---

### 3.8 US-05 · Mở khóa tài khoản

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `PATCH` |
| **Path** | `/api/v1/admin/tai-khoan/:maTaiKhoan/mo-khoa` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body:** Không có.

**Logic:** Đặt `trang_thai = 'HOAT_DONG'`.

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Mở khóa tài khoản thành công",
  "data": {
    "ma_tai_khoan": "TK004",
    "trang_thai": "HOAT_DONG"
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | `Tài khoản đang hoạt động, không cần mở khóa` | `trang_thai` đã là `HOAT_DONG` |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 404 | `Không tìm thấy tài khoản` | `maTaiKhoan` không tồn tại |

---

## 4. Module Maintenance — Bảo trì hệ thống (US-06)

### 4.1 Xem trạng thái bảo trì

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `GET` |
| **Path** | `/api/v1/admin/bao-tri/trang-thai` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "data": {
    "che_do_bao_tri": false,
    "nguong_dung_luong_toi_thieu_mb": 1024
  }
}
```

---

### 4.2 Bật / Tắt chế độ bảo trì

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `PATCH` |
| **Path** | `/api/v1/admin/bao-tri/che-do` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body — Zod schema:**

```ts
const cheDoSchema = z.object({
  bat: z.boolean({ required_error: "Trường bật/tắt là bắt buộc" }),
});
```

**Logic:**
- Cập nhật `cau_hinh_he_thong` SET `gia_tri` WHERE `khoa = 'CHE_DO_BAO_TRI'`.
- Khi `bat = true`: middleware `maintenanceGuard` sẽ trả `503` cho mọi user non-admin ở tất cả API (trừ auth).
- Ghi nhật ký hành động `BAT_BAO_TRI` hoặc `TAT_BAO_TRI`.

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Bật chế độ bảo trì thành công",   // hoặc "Tắt chế độ bảo trì thành công"
  "data": {
    "che_do_bao_tri": true
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 400 | *(lỗi validation)* | Thiếu hoặc sai kiểu trường `bat` |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |

---

### 4.3 Danh sách bản sao lưu

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `GET` |
| **Path** | `/api/v1/admin/bao-tri/sao-luu` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Query parameters:** `trang`, `so_dong` (phân trang).

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "data": {
    "ds": [
      {
        "ma_ban_sao": "BS001",
        "thoi_gian_tao": "2026-11-14T10:00:00.000Z",
        "duong_dan_file": "/backup/kho_20261114.dump",
        "dung_luong_bytes": 52428800,
        "checksum": "a3f1c9e0b7d2...",
        "trang_thai": "HOP_LE",
        "ma_tai_khoan": "TK001",
        "ten_dang_nhap": "admin"
      }
    ],
    "phan_trang": { "trang": 1, "so_dong": 20, "tong_dong": 2, "tong_trang": 1 }
  }
}
```

---

### 4.4 Tạo bản sao lưu

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `POST` |
| **Path** | `/api/v1/admin/bao-tri/sao-luu` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body:** Không có (server tự quyết định tên file, đường dẫn).

**Logic:**
1. Kiểm tra dung lượng đĩa (nếu dưới ngưỡng `NGUONG_DUNG_LUONG_TOI_THIEU_MB` → trả lỗi).
2. Thực hiện `pg_dump` hoặc tương đương.
3. Lưu metadata vào `ban_sao_luu` (tính checksum, dung_luong_bytes).
4. Ghi nhật ký `SAO_LUU` (cả khi thất bại).

**Response thành công — `201`:**

```jsonc
{
  "success": true,
  "message": "Sao lưu thành công",
  "data": {
    "ma_ban_sao": "BS003",
    "thoi_gian_tao": "2026-11-17T08:30:00.000Z",
    "duong_dan_file": "/backup/kho_20261117.dump",
    "dung_luong_bytes": 54321000,
    "checksum": "b4e2d1f0c8e3...",
    "trang_thai": "HOP_LE"
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 500 | `Sao lưu thất bại` | Lỗi hệ thống / đĩa / pg_dump |

---

### 4.5 Phục hồi dữ liệu

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `POST` |
| **Path** | `/api/v1/admin/bao-tri/phuc-hoi/:maBanSao` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Request body:** Không có.

**Logic:**
1. Tìm bản sao lưu theo `maBanSao`.
2. Kiểm tra `trang_thai = 'HOP_LE'` và file tồn tại trên đĩa.
3. Thực hiện `pg_restore` hoặc tương đương.
4. Ghi nhật ký `PHUC_HOI` (cả khi thất bại).

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "message": "Phục hồi thành công",
  "data": {
    "ma_ban_sao": "BS001",
    "thoi_gian_phuc_hoi": "2026-11-17T09:00:00.000Z"
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |
| 404 | `Không tìm thấy bản sao lưu` | `maBanSao` không tồn tại |
| 500 | `Không thể phục hồi dữ liệu` | Bản sao lỗi, file không tồn tại, hoặc lỗi pg_restore |

---

## 5. Module Audit — Nhật ký hệ thống (US-07)

> **Quy tắc: Module này CHỈ CÓ endpoint GET. Không có POST/PUT/DELETE.**

### 5.1 Xem nhật ký hệ thống

| Thuộc tính | Giá trị |
| --- | --- |
| **Method** | `GET` |
| **Path** | `/api/v1/admin/nhat-ky` |
| **Quyền** | `authenticate` → `requireAdmin` |

**Query parameters (tùy chọn):**

| Param          | Kiểu                 | Mô tả                   |
| -------------- | --------------------- | ------------------------ |
| `trang`        | `number`              | Trang hiện tại           |
| `so_dong`      | `number`              | Số dòng mỗi trang       |
| `tu_ngay`      | `string` (ISO 8601)   | Lọc từ ngày              |
| `den_ngay`     | `string` (ISO 8601)   | Lọc đến ngày             |
| `hanh_dong`    | `string`              | Lọc theo loại hành động  |
| `ma_tai_khoan` | `string`              | Lọc theo người thực hiện |

**Response thành công — `200`:**

```jsonc
{
  "success": true,
  "data": {
    "ds": [
      {
        "ma_nhat_ky": "NK004",
        "thoi_gian": "2026-11-16T10:00:00.000Z",
        "hanh_dong": "THEM_TAI_KHOAN",
        "noi_dung": "Tạo tài khoản nv.daxoa.thu",
        "dia_chi_ip": "192.168.1.21",
        "ma_tai_khoan": "TK001",
        "ten_dang_nhap_luc_do": "admin"
      }
    ],
    "phan_trang": {
      "trang": 1,
      "so_dong": 20,
      "tong_dong": 4,
      "tong_trang": 1
    }
  }
}
```

**Các mã lỗi:**

| HTTP | `message` | Điều kiện |
| --- | --- | --- |
| 401 | `Phiên đăng nhập không hợp lệ hoặc đã hết hạn` | Chưa đăng nhập |
| 403 | `Bạn không có quyền thực hiện chức năng này` | Không phải QUAN_TRI |

---

## 6. Bảng tổng hợp endpoint

| #  | Method   | Path                                           | Quyền        | US    |
| -- | -------- | ---------------------------------------------- | ------------ | ----- |
| 1  | `POST`   | `/api/v1/auth/dang-nhap`                       | Công khai    | Auth  |
| 2  | `POST`   | `/api/v1/auth/dang-xuat`                       | authenticate | Auth  |
| 3  | `POST`   | `/api/v1/auth/quen-mat-khau`                   | Công khai    | Auth  |
| 4  | `POST`   | `/api/v1/auth/dat-lai-mat-khau`                | Công khai    | Auth  |
| 5  | `GET`    | `/api/v1/admin/tai-khoan`                      | requireAdmin | US-01 |
| 6  | `GET`    | `/api/v1/admin/tai-khoan/:maTaiKhoan`          | requireAdmin | US-01 |
| 7  | `GET`    | `/api/v1/admin/vai-tro`                        | requireAdmin | US-02 |
| 8  | `POST`   | `/api/v1/admin/tai-khoan`                      | requireAdmin | US-02 |
| 9  | `PUT`    | `/api/v1/admin/tai-khoan/:maTaiKhoan`          | requireAdmin | US-03 |
| 10 | `DELETE` | `/api/v1/admin/tai-khoan/:maTaiKhoan`          | requireAdmin | US-04 |
| 11 | `PATCH`  | `/api/v1/admin/tai-khoan/:maTaiKhoan/khoa`     | requireAdmin | US-05 |
| 12 | `PATCH`  | `/api/v1/admin/tai-khoan/:maTaiKhoan/mo-khoa`  | requireAdmin | US-05 |
| 13 | `GET`    | `/api/v1/admin/bao-tri/trang-thai`             | requireAdmin | US-06 |
| 14 | `PATCH`  | `/api/v1/admin/bao-tri/che-do`                 | requireAdmin | US-06 |
| 15 | `GET`    | `/api/v1/admin/bao-tri/sao-luu`                | requireAdmin | US-06 |
| 16 | `POST`   | `/api/v1/admin/bao-tri/sao-luu`                | requireAdmin | US-06 |
| 17 | `POST`   | `/api/v1/admin/bao-tri/phuc-hoi/:maBanSao`     | requireAdmin | US-06 |
| 18 | `GET`    | `/api/v1/admin/nhat-ky`                        | requireAdmin | US-07 |

**Tổng: 18 endpoint** (4 auth + 8 users + 5 maintenance + 1 audit)

---

## 7. Danh sách hành động nhật ký (`hanh_dong`)

| Mã hành động          | Mô tả                   | Ghi khi                                |
| --------------------- | ------------------------ | -------------------------------------- |
| `DANG_NHAP`           | Đăng nhập thành công     | Login thành công                       |
| `DANG_NHAP_THAT_BAI`  | Đăng nhập thất bại       | Sai mật khẩu / tài khoản bị khóa      |
| `DANG_XUAT`           | Đăng xuất                | Logout                                 |
| `THEM_TAI_KHOAN`      | Thêm tài khoản mới       | POST tai-khoan                         |
| `CAP_NHAT_TAI_KHOAN`  | Cập nhật tài khoản        | PUT tai-khoan                          |
| `XOA_TAI_KHOAN`       | Xóa tài khoản             | DELETE tai-khoan                       |
| `KHOA_TAI_KHOAN`      | Khóa tài khoản            | PATCH khoa                             |
| `MO_KHOA_TAI_KHOAN`   | Mở khóa tài khoản         | PATCH mo-khoa                          |
| `BAT_BAO_TRI`         | Bật chế độ bảo trì        | PATCH che-do (bat=true)                |
| `TAT_BAO_TRI`         | Tắt chế độ bảo trì        | PATCH che-do (bat=false)               |
| `SAO_LUU`             | Sao lưu dữ liệu           | POST sao-luu                           |
| `SAO_LUU_THAT_BAI`    | Sao lưu thất bại          | POST sao-luu gặp lỗi                  |
| `PHUC_HOI`            | Phục hồi dữ liệu          | POST phuc-hoi                          |
| `PHUC_HOI_THAT_BAI`   | Phục hồi thất bại         | POST phuc-hoi gặp lỗi                 |
| `DAT_LAI_MAT_KHAU`    | Đặt lại mật khẩu          | Đặt lại mật khẩu thành công           |

---

## 8. Middleware `maintenanceGuard` — Chi tiết

```
Mọi request (trừ /api/v1/auth/*)
  → Đọc cau_hinh_he_thong WHERE khoa = 'CHE_DO_BAO_TRI'
  → Nếu gia_tri = 'true':
       Nếu user CHƯA đăng nhập HOẶC ma_vai_tro ≠ 'QUAN_TRI':
         → 503 { "success": false, "message": "Hệ thống đang trong chế độ bảo trì" }
       Ngược lại: cho qua (admin vẫn truy cập được)
  → Nếu gia_tri = 'false': cho qua
```

---

## 9. Câu hỏi mở (cần PO / trưởng nhóm xác nhận)

| #   | Câu hỏi | Ảnh hưởng | Giả định hiện tại |
| --- | ------- | --------- | ----------------- |
| Q1  | Email gửi link đặt lại mật khẩu dùng dịch vụ nào? (SMTP, SendGrid, chỉ log console trong dev?) | Endpoint `quen-mat-khau` | Dev: log ra console. Production: chờ PO chốt. |
| Q2  | Thời gian hết hạn token đặt lại mật khẩu là bao lâu? | `token_dat_lai_mat_khau.het_han` | 30 phút |
| Q3  | JWT `expiresIn` là bao lâu? Có cần refresh token không? | Cookie `token` | `expiresIn: '8h'`, không refresh token |
| Q4  | Sao lưu dùng `pg_dump` trực tiếp hay qua thư viện? File lưu ở đâu? | Endpoint `sao-luu` | Dùng `child_process.exec('pg_dump ...')`, lưu tại `./backups/` |
| Q5  | Phục hồi (`pg_restore`) có cần bật bảo trì trước không? | Endpoint `phuc-hoi` | Không bắt buộc nhưng khuyến nghị |
| Q6  | Format `ma_tai_khoan` tự sinh: giữ `TKxxx` hay chuyển sang UUID? | Toàn bộ module Users | Giữ `TKxxx` (auto-increment, lấy max + 1) |
| Q7  | Có cần endpoint admin tự đổi mật khẩu (không qua quên mật khẩu) không? | Thêm endpoint | Chưa có, cần PO xác nhận |
| Q8  | Cột `ma_nguoi_thuc_hien` trong status.md ("Chưa làm, chờ trưởng nhóm DB") — đây là cột ở bảng nào? Có ảnh hưởng tới contract không? | Schema DB | Chờ trưởng nhóm DB, không block API contract |
| Q9  | Khi đăng nhập lúc hệ thống bảo trì, user non-admin bị chặn ở login luôn hay chỉ bị chặn sau khi login? | Middleware flow | Chặn tại login luôn (trả 503) cho non-admin, admin vẫn đăng nhập bình thường |
| Q10 | Có giới hạn số lần đăng nhập sai (rate limiting / lockout) không? | Endpoint `dang-nhap` | Chưa có, cần PO xác nhận |
