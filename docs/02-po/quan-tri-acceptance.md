# Tiêu Chuẩn Nghiệm Thu (Acceptance Criteria) — Phân hệ Quản trị hệ thống

> Dự án: Quản Lý Kho (WMS) — PTUD  
> Vai trò chịu trách nhiệm: Product Owner (PO)  
> Phiên bản: 1.0 (Đã chốt & xác nhận toàn bộ giả định)  
> Ngày cập nhật: 2026-11-17  
> Căn cứ pháp lý & kỹ thuật: `docs/01-ba/quan-tri-he-thong.md`, `docs/03-design/admin-api-contract.md`, `backend/db/migrations/001_admin_module.sql`  

---

## 1. Trạng thái xác nhận của PO (Decision Log)

| Mã | Hạng mục | Trạng thái trước | Quyết định sau khi xác nhận |
|---|---|---|---|
| **DEC-01** | Xóa cứng vs Khóa tài khoản (US-04, US-05) | Giả định | **ĐÃ XÁC NHẬN:** Chỉ xóa cứng khi tài khoản mới tạo và chưa phát sinh dữ liệu liên quan. Nếu đã có dữ liệu liên quan, hệ thống trả mã `409` chặn xóa cứng và hiển thị tùy chọn Khóa tài khoản (`KHOA`). Chặn Admin tự xóa/khóa tài khoản của chính mình. |
| **DEC-02** | Cơ chế Phục hồi & Chế độ bảo trì (US-06) | Giả định | **ĐÃ XÁC NHẬN:** Thao tác Phục hồi (`pg_restore`) bắt buộc xác thực mật khẩu Admin, tự động bật `CHE_DO_BAO_TRI = 'true'` để ngắt phiên non-admin, chỉ cho phép phục hồi file có `trang_thai = 'HOP_LE'` và đúng checksum. Phục hồi xong tự trả cờ bảo trì về `false`. |
| **DEC-03** | Ngưỡng kiểm tra dung lượng Sao lưu (US-06) | Giả định | **ĐÃ XÁC NHẬN:** Kiểm tra dung lượng trống của thư mục lưu trữ trước khi chạy `pg_dump`. Nếu dung lượng trống `< 1024 MB`, hủy thao tác và thông báo lỗi. Cung cấp API tải bản sao lưu hợp lệ. |
| **DEC-04** | Thời hạn Token đặt lại mật khẩu (Auth) | Giả định | **ĐÃ XÁC NHẬN:** Token có hiệu lực **15 phút**, chỉ dùng **1 lần** (`da_su_dung = true`). Trong môi trường dev cục bộ, cho phép in link reset ra console nếu chưa cấu hình SMTP. |
| **DEC-05** | Sự phụ thuộc cột `ma_nguoi_thuc_hien` | Giả định | **ĐÃ XÁC NHẬN:** Phân hệ Quản trị triển khai độc lập theo schema `001_admin_module.sql`. Kiểm thử ràng buộc xóa tài khoản bằng dữ liệu seed hiện hữu (`TK001` - `TK007`, `BS001`, `BS002`). |
| **DEC-06** | Phân quyền truy cập API Quản trị | Giả định | **ĐÃ XÁC NHẬN:** Tất cả các endpoint `/api/v1/admin/*` yêu cầu bắt buộc vai trò `QUAN_TRI`. Tài khoản vai trò khác nhận `403 Forbidden` với đúng câu thông báo BA: `"Bạn không có quyền thực hiện chức năng này."` |

---

## 2. Tiêu chuẩn nghiệm thu chi tiết (Acceptance Criteria)

### Module Auth — Xác thực & Phân quyền

#### AC-AUTH-01: Đăng nhập hệ thống
* **Given:** Người dùng chưa đăng nhập, ở trang đăng nhập `/login`.
* **When:** Nhập `ten_dang_nhap` và `mat_khau`, bấm Đăng nhập.
* **Then (Thành công):**
  - Trả mã HTTP `200` kèm thông tin tài khoản (không bao giờ chứa `mat_khau`).
  - Set-Cookie `token` chứa JWT với cờ `httpOnly`, `sameSite: strict`.
  - Ghi bản ghi vào `nhat_ky_he_thong` với hành động `DANG_NHAP`.
  - Điều hướng Quản trị viên vào trang quản trị `/admin/dashboard`, nhân viên khác vào phân hệ nghiệp vụ tương ứng.
* **Then (Thất bại):**
  - Sai tài khoản/mật khẩu: Trả `401` với thông báo `"Tên đăng nhập hoặc mật khẩu không đúng"`. Ghi log `DANG_NHAP_THAT_BAI`.
  - Tài khoản có `trang_thai = 'KHOA'`: Trả `401` với thông báo `"Tài khoản đã bị khóa"`.
  - Hệ thống đang bật `CHE_DO_BAO_TRI = 'true'`: Người dùng không có vai trò `QUAN_TRI` bị từ chối ngay tại đăng nhập với HTTP `503` và thông báo `"Hệ thống đang trong chế độ bảo trì"`.

#### AC-AUTH-02: Đăng xuất hệ thống
* **Given:** Người dùng đang đăng nhập có JWT hợp lệ.
* **When:** Gửi request `POST /api/v1/auth/dang-xuat`.
* **Then:** Hệ thống xóa cookie `token` (Max-Age=0), ghi nhật ký `DANG_XUAT`, trả HTTP `200` với thông báo `"Đăng xuất thành công"`.

#### AC-AUTH-03: Quên và Đặt lại mật khẩu
* **Given:** Người dùng quên mật khẩu, gửi email tại `POST /api/v1/auth/quen-mat-khau`.
* **Then:** Hệ thống luôn trả HTTP `200` với thông báo `"Nếu email tồn tại trong hệ thống, hướng dẫn đặt lại mật khẩu đã được gửi"`. Nếu email tồn tại, sinh token ngẫu nhiên, hash lưu vào `token_dat_lai_mat_khau` với thời hạn 15 phút.
* **When:** Người dùng dùng token đặt mật khẩu mới tại `POST /api/v1/auth/dat-lai-mat-khau`.
* **Then:** Hệ thống kiểm tra token: nếu hợp lệ và chưa hết hạn, hash mật khẩu mới bằng bcrypt, cập nhật CSDL, đổi `da_su_dung = true`, ghi nhật ký `DAT_LAI_MAT_KHAU` và trả `200` `"Đặt lại mật khẩu thành công"`. Nếu token sai hoặc quá 15 phút, trả `400` `"Token không hợp lệ hoặc đã hết hạn"`.

---

### Module Users — Quản lý tài khoản (US-01 đến US-05)

#### AC01.1: Xem danh sách tài khoản (US-01)
* **Given:** Quản trị viên (`QUAN_TRI`) đã đăng nhập.
* **When:** Gửi `GET /api/v1/admin/tai-khoan`.
* **Then:** Trả danh sách tài khoản theo trang (mặc định 20 dòng), hiển thị đầy đủ `ma_tai_khoan`, `ten_dang_nhap`, `ho_ten`, `email`, `so_dien_thoai`, `trang_thai`, `ten_vai_tro`. Không chứa trường `mat_khau`.

#### AC01.2: Tìm kiếm và Lọc tài khoản (US-01)
* **Given:** Quản trị viên ở màn hình danh sách tài khoản.
* **When:** Nhập từ khóa tìm kiếm (`tim_kiem`) hoặc chọn lọc theo `trang_thai` (`HOAT_DONG`, `KHOA`) hoặc theo `ma_vai_tro`.
* **Then:** Hệ thống trả danh sách tài khoản thỏa mãn tất cả điều kiện lọc kết hợp, kèm thông tin phân trang chính xác (`tong_dong`, `tong_trang`).

#### AC02.1: Thêm tài khoản thành công (US-02)
* **Given:** Quản trị viên mở biểu mẫu thêm tài khoản.
* **When:** Nhập đầy đủ và hợp lệ: `ten_dang_nhap`, `mat_khau` (≥ 6 ký tự), `ho_ten`, `email`, `so_dien_thoai`, `ma_vai_tro`, bấm Lưu.
* **Then:** Hệ thống mã hóa mật khẩu bằng bcrypt, sinh mã tài khoản (dạng `TKxxx`), lưu vào CSDL với trạng thái mặc định `HOAT_DONG`. Ghi nhật ký `THEM_TAI_KHOAN`. Trả HTTP `201` với thông báo đúng câu BA: `"Thêm tài khoản thành công"`.

#### AC02.2: Chặn thêm tài khoản khi trùng tên đăng nhập (US-02)
* **Given:** Tên đăng nhập `admin` hoặc tên đã tồn tại trong CSDL.
* **When:** Quản trị viên gửi form thêm tài khoản với tên đăng nhập này.
* **Then:** Trả HTTP `409 Conflict` với thông báo đúng câu BA: `"Tên đăng nhập đã tồn tại"`. Dữ liệu CSDL không bị thay đổi.

#### AC02.4: Xác thực quyền quản trị khi xem/thao tác tài khoản (US-01, US-02)
* **Given:** Người dùng đăng nhập với vai trò khác `QUAN_TRI` (như `NHAN_VIEN_KHO`, `TK003`).
* **When:** Cố gắng truy cập các endpoint `/api/v1/admin/tai-khoan` (GET, POST, PUT, DELETE).
* **Then:** Hệ thống chặn ngay tại middleware `requireAdmin`, trả HTTP `403 Forbidden` với thông báo đúng câu BA: `"Bạn không có quyền thực hiện chức năng này."`

#### AC02.5: Cập nhật thông tin tài khoản (US-03)
* **Given:** Quản trị viên chọn cập nhật tài khoản (ví dụ `TK003`).
* **When:** Gửi `PUT /api/v1/admin/tai-khoan/:maTaiKhoan` với thông tin cập nhật: `ho_ten`, `email`, `so_dien_thoai`, `ma_vai_tro`.
* **Then:** 
  - Hệ thống cập nhật thông tin trong CSDL.
  - Trường `ten_dang_nhap` không bị thay đổi.
  - Nếu trường `mat_khau` bỏ trống, giữ nguyên mật khẩu cũ của người dùng.
  - Ghi nhật ký `CAP_NHAT_TAI_KHOAN`.
  - Trả HTTP `200` với thông báo đúng câu BA: `"Cập nhật tài khoản thành công"`.

#### AC03.1: Xóa tài khoản thành công khi chưa có dữ liệu ràng buộc (US-04)
* **Given:** Tài khoản mới tạo, chưa từng phát sinh dữ liệu liên kết nào trong hệ thống (như `TK006`).
* **When:** Quản trị viên gửi `DELETE /api/v1/admin/tai-khoan/TK006`.
* **Then:** Hệ thống xóa bản ghi khỏi CSDL, ghi nhật ký `XOA_TAI_KHOAN`, trả HTTP `200` với thông báo: `"Xóa tài khoản thành công"`.

#### AC03.2: Chặn tự xóa chính tài khoản của mình (US-04)
* **Given:** Quản trị viên đang đăng nhập bằng tài khoản `TK001`.
* **When:** Quản trị viên yêu cầu xóa tài khoản `TK001`.
* **Then:** Hệ thống từ chối ngay lập tức, trả HTTP `400` với thông báo: `"Không thể xóa tài khoản của chính mình"`.

#### AC03.3: Chặn xóa tài khoản khi đã phát sinh dữ liệu liên quan (US-04 & US-05)
* **Given:** Tài khoản đã có dữ liệu liên quan (như `TK002` trong bản sao lưu `BS002`, hoặc `TK007` trong nhật ký hệ thống).
* **When:** Quản trị viên chọn xóa tài khoản đó.
* **Then:** 
  - Hệ thống từ chối xóa, không xóa dữ liệu trong CSDL.
  - Trả HTTP `409 Conflict` với thông báo đúng câu BA: `"Không thể xóa tài khoản vì đang có dữ liệu liên quan. Bạn có muốn khóa tài khoản này không?"`.
  - Trên giao diện Frontend hiển thị nút shortcut cho phép Quản trị viên xác nhận chuyển sang thao tác Khóa tài khoản (`PATCH .../khoa`).

#### AC03.4: Khóa và Mở khóa tài khoản (US-05)
* **Given:** Tài khoản đang ở trạng thái `HOAT_DONG`.
* **When:** Quản trị viên chọn Khóa tài khoản (`PATCH /api/v1/admin/tai-khoan/:maTaiKhoan/khoa`).
* **Then:** 
  - Cập nhật `trang_thai = 'KHOA'`. Ghi nhật ký `KHOA_TAI_KHOAN`.
  - Trả HTTP `200` với thông báo: `"Khóa tài khoản thành công"`.
  - Tài khoản này sẽ không thể đăng nhập vào hệ thống ở các lần tiếp theo.
* **When:** Quản trị viên chọn Mở khóa (`PATCH /api/v1/admin/tai-khoan/:maTaiKhoan/mo-khoa`).
* **Then:** Cập nhật `trang_thai = 'HOAT_DONG'`, ghi nhật ký `MO_KHOA_TAI_KHOAN`, trả HTTP `200` `"Mở khóa tài khoản thành công"`.

---

### Module Maintenance — Bảo trì hệ thống (US-06)

#### AC04.1: Bật / Tắt chế độ bảo trì (US-06)
* **Given:** Quản trị viên ở trang Quản lý bảo trì.
* **When:** Gửi `PATCH /api/v1/admin/bao-tri/che-do` với payload `{ "bat": true }`.
* **Then:** 
  - CSDL cập nhật `cau_hinh_he_thong` (`CHE_DO_BAO_TRI = 'true'`).
  - Ghi nhật ký `BAT_BAO_TRI`.
  - Middleware `maintenanceGuard` kích hoạt: Mọi user không mang vai trò `QUAN_TRI` khi truy cập bất kỳ chức năng nào đều nhận HTTP `503` `"Hệ thống đang trong chế độ bảo trì"`.
* **When:** Gửi `{ "bat": false }`: CSDL cập nhật `false`, ghi nhật ký `TAT_BAO_TRI`, hệ thống mở lại bình thường cho toàn bộ người dùng.

#### AC04.2: Tạo bản sao lưu thành công (US-06)
* **Given:** Dung lượng trống trên ổ đĩa ≥ 1024 MB.
* **When:** Quản trị viên chọn *Sao lưu dữ liệu* (`POST /api/v1/admin/bao-tri/sao-luu`).
* **Then:**
  - Hệ thống thực thi sao lưu CSDL (định dạng `.dump`), đặt tên file theo timestamp.
  - Tính mã SHA-256 Checksum và dung lượng thực tế.
  - Lưu bản ghi vào bảng `ban_sao_luu` với `trang_thai = 'HOP_LE'`, `ma_tai_khoan` của Admin thực hiện.
  - Ghi nhật ký hệ thống `SAO_LUU`.
  - Trả HTTP `201` với thông báo đúng câu BA: `"Sao lưu thành công"`.

#### AC04.3: Kiểm tra ngưỡng dung lượng đĩa trước khi sao lưu (US-06)
* **Given:** Dung lượng đĩa trống < 1024 MB (ngưỡng quy định trong cấu hình).
* **When:** Quản trị viên yêu cầu sao lưu dữ liệu.
* **Then:**
  - Hệ thống hủy tiến trình sao lưu trước khi thực hiện lệnh dump.
  - Ghi nhật ký lỗi `SAO_LUU_THAT_BAI`.
  - Trả HTTP `500` với thông báo: `"Sao lưu thất bại. Dung lượng lưu trữ không đủ ngưỡng tối thiểu (1024 MB)"`.

#### AC05.1: Danh sách bản sao lưu và Tải xuống (US-06)
* **Given:** Quản trị viên xem tab Danh sách sao lưu.
* **Then:** Hiển thị danh sách các bản sao lưu với mã, thời gian tạo, dung lượng, trạng thái (`HOP_LE` hoặc `LOI`), người tạo.
* **Action:** Cho phép Quản trị viên tải file sao lưu hợp lệ (`.dump`) về máy tính an toàn.

#### AC05.2: Phục hồi dữ liệu từ bản sao lưu (US-06)
* **Given:** Bản sao lưu có trạng thái `HOP_LE` (như `BS001`).
* **When:** Quản trị viên chọn *Phục hồi dữ liệu* và nhập đúng mật khẩu xác nhận của Admin.
* **Then:**
  - Hệ thống tự động chuyển `CHE_DO_BAO_TRI = 'true'`.
  - Kiểm tra file tồn tại và toàn vẹn checksum.
  - Thực thi phục hồi CSDL (`pg_restore`).
  - Ghi nhật ký `PHUC_HOI`.
  - Chuyển `CHE_DO_BAO_TRI = 'false'`.
  - Trả HTTP `200` với thông báo đúng câu BA: `"Phục hồi thành công"`.
* **Then (Thất bại):** Nếu bản sao lưu ở trạng thái `LOI` (như `BS002`) hoặc file bị hỏng/sai checksum: Hệ thống từ chối phục hồi, giữ nguyên CSDL hiện tại, ghi log `PHUC_HOI_THAT_BAI`, trả HTTP `500` `"Không thể phục hồi dữ liệu"`.

---

### Module Audit — Nhật ký hệ thống (US-07)

#### AC-AUDIT-01: Tra cứu và Lọc nhật ký hệ thống (US-07)
* **Given:** Quản trị viên truy cập màn hình Nhật ký hệ thống.
* **When:** Gửi `GET /api/v1/admin/nhat-ky` kèm tham số lọc (`tu_ngay`, `den_ngay`, `hanh_dong`, `ma_tai_khoan`, phân trang).
* **Then:**
  - Trả danh sách log đã sắp xếp theo thời gian mới nhất lên đầu (`thoi_gian DESC`).
  - Mỗi dòng hiển thị: thời gian, mã hành động, nội dung chi tiết, địa chỉ IP, tài khoản thực hiện, tên đăng nhập lúc đó (`ten_dang_nhap_luc_do`).
  - Đảm bảo endpoint chỉ hỗ trợ phương thức `GET`, không có endpoint tạo/sửa/xóa nhật ký.

---

### Module UI / Boundary — Giao diện Quản trị (AC-A2)

#### AC-A2: Dashboard tổng quan Quản trị hệ thống
* **Given:** Quản trị viên đăng nhập thành công vào trang `/admin/dashboard`.
* **Then:**
  - Hiển thị các thẻ chỉ số tổng quan (KPI cards): Tổng số tài khoản người dùng, số tài khoản đang hoạt động/bị khóa, trạng thái bảo trì hiện tại (`Đang bảo trì` / `Bình thường`), dung lượng bản sao lưu gần nhất.
  - Danh sách 5 hoạt động gần nhất trong hệ thống (trích xuất từ nhật ký).
  - Có thanh menu điều hướng nhanh đến: *Quản lý tài khoản*, *Bảo trì hệ thống*, *Nhật ký hệ thống*, và *Đăng xuất*.

