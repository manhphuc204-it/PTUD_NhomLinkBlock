# Trạng Thái Triển Khai Dự Án — Phân Hệ Quản Trị Hệ Thống

> Cập nhật lần cuối: 2026-11-17  
> Vai trò cập nhật: Product Owner (PO)  

---

## 1. Tiến độ kỹ thuật & Database

| Hạng mục | Trạng thái | Ghi chú |
|---|---|---|
| `001_admin_module.sql` (schema `wms`) | Đã hoàn thành | Chạy idempotently, đầy đủ bảng, enum và ràng buộc FK |
| `002_admin_seed.sql` | Đã hoàn thành | Chứa tài khoản `TK001` - `TK007`, bản sao lưu `BS001`, `BS002`, nhật ký mẫu |
| `Hash BCrypt` | Chưa thay | Cần chạy `gen-hash.js` cập nhật hash mật khẩu trước khi test đăng nhập |
| `token_dat_lai_mat_khau` | Đã hoàn thành | Cấu trúc đầy đủ (`token_hash`, `het_han`, `da_su_dung`, `ma_tai_khoan`) |
| `Cột ma_nguoi_thuc_hien` | Chưa làm (chờ trưởng nhóm DB) | **Quyết định PO:** Phân hệ Quản trị không bị block, tiếp tục chạy độc lập |
| `admin-api-contract.md` | Đã hoàn thành | Quy chuẩn 18 endpoint (4 auth, 8 user, 5 maintenance, 1 audit) |
| `quan-tri-he-thong.md` (BA) | Đã hoàn thành | Chuẩn hóa toàn bộ Use Case, flow và thông báo nghiệp vụ |
| `quan-tri-acceptance.md` (PO) | Đã hoàn thành & Xác nhận | Toàn bộ tiêu chuẩn nghiệm thu và quyết định của PO đã chốt |

---

## 2. Quyết định của PO (Đã được Stakeholder / User xác nhận)

| Mã quyết định | Nội dung quyết định | Chi tiết triển khai |
|---|---|---|
| **DEC-01** | **Chính sách Xóa tài khoản (US-04) & Khóa tài khoản (US-05)** | - Xóa cứng (`DELETE`) chỉ áp dụng khi tài khoản mới tạo và chưa có bất kỳ dữ liệu ràng buộc nào.<br>- Nếu tài khoản đã có dữ liệu liên quan (nhật ký, bản sao lưu, chứng từ kho): Trả lỗi HTTP `409 Conflict` kèm thông báo: *"Không thể xóa tài khoản vì đang có dữ liệu liên quan. Bạn có muốn khóa tài khoản này không?"*<br>- UI hiển thị nút chuyển nhanh sang Khóa tài khoản (`KHOA`).<br>- Chặn tuyệt đối Quản trị viên tự xóa hoặc tự khóa chính mình. |
| **DEC-02** | **Cơ chế Phục hồi CSDL & Bảo trì (US-06)** | - Bắt buộc Admin nhập lại mật khẩu tài khoản trước khi thực hiện Phục hồi dữ liệu.<br>- Khi bắt đầu phục hồi: hệ thống tự động bật `CHE_DO_BAO_TRI = 'true'` để ngắt mọi truy cập của non-admin.<br>- Chỉ phục hồi các bản sao có `trang_thai = 'HOP_LE'` và đúng mã checksum.<br>- Sau khi phục hồi xong, tự động trả `CHE_DO_BAO_TRI = 'false'` và ghi nhật ký hệ thống. |
| **DEC-03** | **Ngưỡng dung lượng Sao lưu (US-06)** | - Kiểm tra dung lượng đĩa trống trước khi chạy `pg_dump`: Yêu cầu tối thiểu `1024 MB`. Nếu không đủ, hủy thao tác và trả lỗi `500`.<br>- Cho phép Admin tải file `.dump` về máy cá nhân qua API an toàn. |
| **DEC-04** | **Quy chuẩn Token đặt lại mật khẩu (Auth)** | - Token có thời hạn sử dụng là **15 phút**, chỉ dùng **1 lần** duy nhất.<br>- Môi trường dev: Nếu chưa cấu hình SMTP trong `.env`, in link và token ra console server để phục vụ kiểm thử. |
| **DEC-05** | **Xử lý phụ thuộc cột `ma_nguoi_thuc_hien`** | - Quản trị hệ thống không chờ nhóm DB khác. Sử dụng dữ liệu seed sẵn có (`TK001` - `TK007`, `BS001`, `BS002`) để hoàn thiện kiểm thử tự động. |
| **DEC-06** | **Phân quyền truy cập Quản trị** | - Toàn bộ endpoint `/api/v1/admin/*` kiểm soát qua middleware `requireAdmin` (`ma_vai_tro === 'QUAN_TRI'`).<br>- Tài khoản vai trò khác nhận HTTP `403` với câu thông báo chuẩn: *"Bạn không có quyền thực hiện chức năng này."* |
