# Đặc tả Nghiệp vụ (BA) — Phân hệ Quản trị hệ thống

> Dự án: Quản Lý Kho (WMS) — PTUD  
> Tài liệu nguồn: `ThucHanh/TH Tuan2/QuanLyTaiKhoan_BaoTriHeThong.docx`  
> Người lập: Business Analyst (BA)  
> Ngày cập nhật: 2026-11-17  

---

## 1. Tổng quan phân hệ Quản trị hệ thống
Phân hệ Quản trị hệ thống cung cấp các chức năng cho **Quản trị viên (Admin)** nhằm:
1. Quản lý danh sách tài khoản người dùng và phân quyền vai trò.
2. Kiểm soát đăng nhập và an toàn tài khoản (khóa, mở khóa, quên/đặt lại mật khẩu).
3. Thực hiện công tác bảo trì hệ thống: bật/tắt chế độ bảo trì, kiểm tra dung lượng ổ đĩa, sao lưu và phục hồi dữ liệu.
4. Giám sát các hoạt động của toàn bộ người dùng thông qua nhật ký hệ thống (Audit log).

---

## 2. Danh sách Use Cases / User Stories

| Mã UC / US | Tên chức năng | Actor chính | Mô tả tóm tắt |
|---|---|---|---|
| **UC-01 / US-01** | Xem danh sách tài khoản | Quản trị viên | Xem danh sách, tìm kiếm, lọc theo vai trò và trạng thái. |
| **UC-02 / US-02** | Thêm tài khoản người dùng | Quản trị viên | Tạo mới tài khoản nhân sự với thông tin và vai trò tương ứng. |
| **UC-03 / US-03** | Cập nhật tài khoản người dùng | Quản trị viên | Cập nhật họ tên, email, SĐT, vai trò, mật khẩu mới (tùy chọn). |
| **UC-04 / US-04** | Xóa tài khoản người dùng | Quản trị viên | Xóa tài khoản chưa phát sinh dữ liệu liên quan. |
| **UC-05 / US-05** | Khóa / Mở khóa tài khoản | Quản trị viên | Vô hiệu hóa hoặc kích hoạt lại tài khoản người dùng. |
| **UC-06 / US-06** | Bảo trì hệ thống | Quản trị viên | Sao lưu dữ liệu, Phục hồi dữ liệu, Bật/tắt chế độ bảo trì, Kiểm tra tài nguyên. |
| **UC-07 / US-07** | Xem nhật ký hệ thống | Quản trị viên | Tra cứu vết kiểm toán các thao tác trong hệ thống (chỉ đọc). |
| **UC-AUTH** | Xác thực & Quên mật khẩu | Người dùng / Admin | Đăng nhập, đăng xuất, yêu cầu token và đặt lại mật khẩu. |

---

## 3. Đặc tả chi tiết Use Cases

### 3.1 UC-02 / US-02: Thêm tài khoản người dùng
* **Tiền điều kiện:** Quản trị viên đã đăng nhập thành công vào hệ thống.
* **Hậu điều kiện:** Tài khoản được tạo và lưu thành công vào CSDL với trạng thái mặc định `HOAT_DONG`.
* **Basic flow:**
  1. Quản trị viên chọn chức năng *Quản lý tài khoản*.
  2. Hệ thống hiển thị danh sách tài khoản.
  3. Quản trị viên chọn *Thêm tài khoản*.
  4. Hệ thống hiển thị biểu mẫu thêm tài khoản.
  5. Quản trị viên nhập thông tin: tên đăng nhập, mật khẩu, họ tên, email, số điện thoại, vai trò.
  6. Quản trị viên chọn *Lưu*.
  7. Hệ thống kiểm tra tính hợp lệ của thông tin.
  8. Hệ thống lưu tài khoản vào CSDL.
  9. Hệ thống thông báo: `"Thêm tài khoản thành công"`.
  10. Hệ thống hiển thị danh sách tài khoản đã được cập nhật.
* **Alternative flow:**
  - *7.1 Tên đăng nhập đã tồn tại:* Hệ thống phát hiện tên đăng nhập đã có trong CSDL -> Thông báo `"Tên đăng nhập đã tồn tại"` -> Quản trị viên nhập lại tên đăng nhập khác (quay lại bước 5).
  - *7.2 Dữ liệu không hợp lệ:* Hệ thống phát hiện thông tin không hợp lệ hoặc thiếu thông tin bắt buộc -> Thông báo lỗi tương ứng (Validation error) -> Quản trị viên chỉnh sửa thông tin (quay lại bước 5).
* **Exception flow:**
  - *6.1 Hủy thêm tài khoản:* Quản trị viên chọn *Hủy* -> Hệ thống đóng form và quay lại danh sách tài khoản.

---

### 3.2 UC-03 / US-03: Cập nhật tài khoản người dùng
* **Tiền điều kiện:** Quản trị viên đã đăng nhập thành công. Tài khoản cần cập nhật tồn tại trong hệ thống.
* **Hậu điều kiện:** Thông tin tài khoản được cập nhật vào CSDL.
* **Basic flow:**
  1. Quản trị viên chọn chức năng *Quản lý tài khoản*.
  2. Hệ thống hiển thị danh sách tài khoản.
  3. Quản trị viên chọn *Cập nhật* tại dòng tài khoản tương ứng.
  4. Hệ thống hiển thị thông tin hiện tại của tài khoản (tên đăng nhập ở chế độ chỉ đọc).
  5. Quản trị viên chỉnh sửa thông tin (họ tên, email, số điện thoại, vai trò, mật khẩu mới nếu muốn đổi).
  6. Quản trị viên chọn *Lưu*.
  7. Hệ thống kiểm tra tính hợp lệ của thông tin.
  8. Hệ thống cập nhật tài khoản vào CSDL.
  9. Hệ thống thông báo: `"Cập nhật tài khoản thành công"`.
  10. Hệ thống hiển thị danh sách tài khoản đã được cập nhật.
* **Alternative flow:**
  - *7.1 Dữ liệu không hợp lệ:* Hệ thống phát hiện thông tin thiếu/sai định dạng -> Báo lỗi tương ứng -> Quản trị viên chỉnh sửa (quay lại bước 5).
* **Exception flow:**
  - *6.1 Hủy cập nhật:* Quản trị viên chọn *Hủy* -> Hệ thống hủy thao tác và quay lại danh sách.

---

### 3.3 UC-04 / US-04 & UC-05 / US-05: Xóa tài khoản & Khóa tài khoản
* **Tiền điều kiện:** Quản trị viên đã đăng nhập thành công. Tài khoản cần xóa/khóa tồn tại trong hệ thống.
* **Hậu điều kiện:** Tài khoản bị xóa khỏi CSDL (nếu chưa có dữ liệu liên quan) hoặc chuyển sang trạng thái `KHOA`.
* **Basic flow (Xóa tài khoản):**
  1. Quản trị viên chọn chức năng *Quản lý tài khoản*.
  2. Hệ thống hiển thị danh sách tài khoản.
  3. Quản trị viên chọn tài khoản muốn xóa.
  4. Quản trị viên chọn *Xóa*.
  5. Hệ thống hiển thị hộp thoại xác nhận xóa: `"Bạn có chắc chắn muốn xóa tài khoản này?"`.
  6. Quản trị viên chọn *Xác nhận*.
  7. Hệ thống kiểm tra ràng buộc tài khoản:
     - Không cho phép tự xóa tài khoản đang đăng nhập.
     - Kiểm tra dữ liệu liên quan trong hệ thống (nhật ký, bản sao lưu, chứng từ kho).
  8. Hệ thống xóa tài khoản khỏi CSDL.
  9. Hệ thống thông báo: `"Xóa tài khoản thành công"`.
  10. Hệ thống làm mới danh sách tài khoản.
* **Alternative flow:**
  - *7.1 Tài khoản đang có dữ liệu liên quan:* Hệ thống phát hiện tài khoản đang được tham chiếu bởi dữ liệu khác -> Hệ thống không thực hiện xóa -> Thông báo: `"Không thể xóa tài khoản vì đang có dữ liệu liên quan. Bạn có muốn khóa tài khoản này không?"` -> Quản trị viên có thể chọn xác nhận Khóa tài khoản (`KHOA`) để vô hiệu hóa thay vì xóa cứng.
* **Exception flow:**
  - *6.1 Hủy xóa:* Quản trị viên chọn *Hủy* -> Hệ thống không thực hiện xóa và đóng hộp thoại.
  - *8.1 Lỗi CSDL:* Hệ thống gặp sự cố CSDL khi xóa -> Báo `"Xóa tài khoản thất bại"`, dữ liệu tài khoản giữ nguyên.

---

### 3.4 UC-06 / US-06: Bảo trì hệ thống
* **Tiền điều kiện:** Quản trị viên đã đăng nhập và có quyền quản trị (`QUAN_TRI`).
* **Hậu điều kiện:** Hoạt động bảo trì được thực hiện thành công. Kết quả bảo trì được ghi nhận vào nhật ký hệ thống.
* **Basic flow:**
  1. Quản trị viên chọn chức năng *Bảo trì hệ thống*.
  2. Hệ thống hiển thị các chức năng bảo trì: Bật/Tắt bảo trì, Danh sách bản sao lưu, Sao lưu dữ liệu, Phục hồi dữ liệu.
  3. Quản trị viên chọn hoạt động cần thực hiện.
  4. Hệ thống hiển thị thông tin và yêu cầu xác nhận thao tác.
  5. Quản trị viên xác nhận thực hiện.
  6. Hệ thống kiểm tra điều kiện thực hiện.
  7. Hệ thống tiến hành hoạt động bảo trì.
  8. Hệ thống ghi nhận kết quả vào nhật ký hệ thống.
  9. Hệ thống thông báo bảo trì thành công.
  10. Quản trị viên kiểm tra kết quả bảo trì.
* **Alternative flows:**
  - *7.1 Sao lưu dữ liệu:*
    - Quản trị viên chọn *Sao lưu dữ liệu*.
    - Hệ thống kiểm tra dung lượng trống (ngưỡng tối thiểu cấu hình 1024 MB).
    - Hệ thống tiến hành `pg_dump`, tạo file sao lưu và tính SHA-256 checksum.
    - Hệ thống thông báo: `"Sao lưu thành công"`.
  - *7.2 Phục hồi dữ liệu:*
    - Quản trị viên chọn *Phục hồi dữ liệu* từ một bản sao lưu trong danh sách (`trang_thai = 'HOP_LE'`).
    - Hệ thống cảnh báo rủi ro ghi đè dữ liệu và yêu cầu xác thực mật khẩu Quản trị viên.
    - Hệ thống tự động chuyển sang chế độ bảo trì (`CHE_DO_BAO_TRI = true`).
    - Hệ thống tiến hành phục hồi dữ liệu (`pg_restore`).
    - Hệ thống thông báo: `"Phục hồi thành công"`, ghi nhật ký và tắt chế độ bảo trì.
  - *7.3 Kiểm tra trạng thái hệ thống:*
    - Hiển thị cờ bảo trì, dung lượng lưu trữ tối thiểu, số lượng bản sao lưu và tình trạng CSDL.
* **Exception flows:**
  - *6.1 Không đủ quyền thực hiện:* Nếu không phải vai trò `QUAN_TRI` -> Hệ thống từ chối và báo `"Bạn không có quyền thực hiện chức năng này."`
  - *7B.1 Sao lưu thất bại:* Phát hiện lỗi (thiếu dung lượng đĩa hoặc lỗi lệnh dump) -> Dừng sao lưu, ghi nhật ký lỗi, thông báo: `"Sao lưu thất bại"`.
  - *7B.2 Phục hồi dữ liệu thất bại:* Phát hiện bản sao lưu lỗi hoặc lỗi restore -> Dừng phục hồi, giữ nguyên CSDL hiện tại, ghi nhật ký lỗi, thông báo: `"Không thể phục hồi dữ liệu"`.

---

### 3.5 UC-07 / US-07: Xem nhật ký hệ thống
* **Tiền điều kiện:** Quản trị viên đã đăng nhập với vai trò `QUAN_TRI`.
* **Quy tắc bất biến:** Module này **chỉ đọc (Read-only / GET)**, không cung cấp API tạo, sửa, xóa nhật ký.
* **Mô tả:**
  - Hệ thống tự động ghi nhật ký cho tất cả các thao tác nhạy cảm: `DANG_NHAP`, `DANG_NHAP_THAT_BAI`, `DANG_XUAT`, `THEM_TAI_KHOAN`, `CAP_NHAT_TAI_KHOAN`, `XOA_TAI_KHOAN`, `KHOA_TAI_KHOAN`, `MO_KHOA_TAI_KHOAN`, `BAT_BAO_TRI`, `TAT_BAO_TRI`, `SAO_LUU`, `SAO_LUU_THAT_BAI`, `PHUC_HOI`, `PHUC_HOI_THAT_BAI`, `DAT_LAI_MAT_KHAU`.
  - Quản trị viên có thể tìm kiếm, lọc theo khoảng thời gian (`tu_ngay`, `den_ngay`), theo mã hành động (`hanh_dong`), hoặc theo người thực hiện (`ma_tai_khoan`).

