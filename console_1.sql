create schema wms

-- 1. Trạng thái danh mục dùng chung (TaiKhoan, ThanhPham, Kho, NguyenLieu)
CREATE TYPE enum_trang_thai_danh_muc AS ENUM (
    'DANG_HOAT_DONG',
    'NGUNG_HOAT_DONG',
    'DANG_KIEM_KE' -- Dùng khi khóa kho để kiểm kê (batDauKiemKe)
    );

-- 2. Trạng thái Đơn hàng khách hàng (DonHangKhachHang)
CREATE TYPE enum_trang_thai_don_hang_kh AS ENUM (
    'MOI_TAO',
    'DANG_SAN_XUAT',
    'DA_GIAO_HANG',
    'DA_HUY'
    );

-- 3. Trạng thái Kế hoạch (KeHoachSanXuat, KeHoachMua)
CREATE TYPE enum_trang_thai_ke_hoach AS ENUM (
    'CHO_DUYET',
    'DA_DUYET',
    'TU_CHOI',
    'DANG_THUC_HIEN',
    'DA_HOAN_THANH'
    );

-- 4. Trạng thái Lệnh sản xuất (LenhSanXuat)
CREATE TYPE enum_trang_thai_lenh_sx AS ENUM (
    'MOI_LAP',
    'DANG_THUC_HIEN',
    'DA_HOAN_THANH',
    'DA_HUY'
    );

-- 5. Trạng thái Đơn đặt hàng nhà cung cấp (DonDatHang)
CREATE TYPE enum_trang_thai_don_dat_hang AS ENUM (
    'DA_DAT',
    'GIAO_MOT_PHAN',
    'DA_GIAO_DU',
    'DA_HUY'
    );

-- 6. Trạng thái Phiếu giao nguyên liệu (PhieuGiaoNguyenLieu)
CREATE TYPE enum_trang_thai_phieu_giao AS ENUM (
    'CHO_TIEP_NHAN',
    'CHO_KIEM_DINH',
    'DA_KIEM_DINH',
    'DA_NHAP_KHO'
    );

-- 7. Trạng thái Lô nguyên liệu (LoNguyenLieu)
CREATE TYPE enum_trang_thai_lo AS ENUM (
    'CHO_KIEM_DINH',
    'DAT_CHAT_LUONG',
    'KHONG_DAT',
    'HET_HAN',
    'DA_TIEU_HUY',
    'HET_TON'
    );

-- 8. Kết quả kiểm tra chất lượng (PhieuKiemTraChatLuong, PhieuKiemTraThanhPham)
CREATE TYPE enum_ket_qua_kiem_tra AS ENUM (
    'DAT',
    'DAT_MOT_PHAN',
    'KHONG_DAT'
    );

-- 9. Trạng thái Phiếu yêu cầu nhập/xuất kho (PhieuYeuCauNhapKho, PhieuYeuCauXuatKho)
CREATE TYPE enum_trang_thai_yeu_cau AS ENUM (
    'CHO_KIEM_DINH',
    'CHO_DUYET',
    'CHO_DUYET_CAP_CAO', -- Khi vượt ngưỡng hao hụt cấu hình (guiYeuCau)
    'DA_DUYET',
    'TU_CHOI',
    'DA_XU_LY'
    );

-- 10. Trạng thái Chứng từ Nhập / Xuất / Tiêu hủy chính thức
-- (PhieuNhapKho, PhieuXuatKho, PhieuNhapKhoThanhPham, PhieuXuatThanhPham, PhieuTieuHuy)
CREATE TYPE enum_trang_thai_chung_tu AS ENUM (
    'NHAP',
    'CHO_XAC_NHAN',
    'DA_XAC_NHAN',
    'DA_HUY'
    );

-- 11. Trạng thái Phiếu kiểm kê (PhieuKiemKe)
CREATE TYPE enum_trang_thai_kiem_ke AS ENUM (
    'DANG_KIEM_DEM',
    'CHO_DUYET',
    'YEU_CAU_KIEM_KE_LAI',
    'DA_PHE_DUYET',
    'DA_HUY'
    );

-- 12. Trạng thái Biên bản xử lý chênh lệch (BienBanXuLyChenhLech)
CREATE TYPE enum_trang_thai_bien_ban AS ENUM (
    'CHO_GIAI_TRINH',
    'CHO_DUYET',
    'DA_DUYET'
    );
-- 1. TaiKhoan
CREATE TABLE tai_khoan (
                           ma_tai_khoan VARCHAR(50) PRIMARY KEY,
                           ten_dang_nhap VARCHAR(100) NOT NULL UNIQUE,
                           mat_khau VARCHAR(255) NOT NULL,
                           ho_ten VARCHAR(150) NOT NULL,
                           email VARCHAR(150),
                           so_dien_thoai VARCHAR(20),
                           trang_thai enum_trang_thai_danh_muc NOT NULL DEFAULT 'DANG_HOAT_DONG',
                           ma_vai_tro VARCHAR(50)
);

-- 2. VaiTro
CREATE TABLE vai_tro (
                         ma_vai_tro VARCHAR(50) PRIMARY KEY,
                         ten_vai_tro VARCHAR(100) NOT NULL,
                         mo_ta TEXT
);

-- 3. NhatKyHeThong
CREATE TABLE nhat_ky_he_thong (
                                  ma_nhat_ky VARCHAR(50) PRIMARY KEY,
                                  thoi_gian TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  hanh_dong VARCHAR(150) NOT NULL,
                                  noi_dung TEXT,
                                  dia_chi_ip VARCHAR(45),
                                  ma_tai_khoan VARCHAR(50) REFERENCES tai_khoan(ma_tai_khoan)
);

-- 4. DonHangKhachHang
CREATE TABLE don_hang_khach_hang (
                                     ma_don_hang VARCHAR(50) PRIMARY KEY,
                                     ngay_dat DATE NOT NULL DEFAULT CURRENT_DATE,
                                     mo_ta TEXT,
                                     trang_thai enum_trang_thai_don_hang_kh NOT NULL DEFAULT 'MOI_TAO'
);

-- 5. KeHoachSanXuat
CREATE TABLE ke_hoach_san_xuat (
                                   ma_ke_hoach VARCHAR(50) PRIMARY KEY,
                                   ngay_lap DATE NOT NULL DEFAULT CURRENT_DATE,
                                   ngay_bat_dau DATE NOT NULL,
                                   ngay_ket_thuc DATE NOT NULL,
                                   trang_thai enum_trang_thai_ke_hoach NOT NULL DEFAULT 'CHO_DUYET',
                                   ma_don_hang VARCHAR(50) REFERENCES don_hang_khach_hang(ma_don_hang),
                                   CHECK (ngay_ket_thuc >= ngay_bat_dau)
);

-- 6. LenhSanXuat
CREATE TABLE lenh_san_xuat (
                               ma_lenh VARCHAR(50) PRIMARY KEY,
                               ngay_lap DATE NOT NULL DEFAULT CURRENT_DATE,
                               ngay_bat_dau DATE NOT NULL,
                               ngay_ket_thuc DATE NOT NULL,
                               so_luong_can_san_xuat INTEGER NOT NULL CHECK (so_luong_can_san_xuat > 0),
                               trang_thai enum_trang_thai_lenh_sx NOT NULL DEFAULT 'MOI_LAP',
                               ma_ke_hoach VARCHAR(50) REFERENCES ke_hoach_san_xuat(ma_ke_hoach),
                               ma_thanh_pham VARCHAR(50),
                               CHECK (ngay_ket_thuc >= ngay_bat_dau)
);

-- 7. KeHoachMua
CREATE TABLE ke_hoach_mua (
                              ma_ke_hoach_mua VARCHAR(50) PRIMARY KEY,
                              ngay_lap DATE NOT NULL DEFAULT CURRENT_DATE,
                              tong_so_luong INTEGER NOT NULL DEFAULT 0 CHECK (tong_so_luong >= 0),
                              trang_thai enum_trang_thai_ke_hoach NOT NULL DEFAULT 'CHO_DUYET',
                              ma_ke_hoach VARCHAR(50) REFERENCES ke_hoach_san_xuat(ma_ke_hoach)
);

-- 8. NhaCungCap
CREATE TABLE nha_cung_cap (
                              ma_nha_cung_cap VARCHAR(50) PRIMARY KEY,
                              ten_nha_cung_cap VARCHAR(200) NOT NULL,
                              dia_chi_ncc TEXT,
                              so_dien_thoai VARCHAR(20),
                              email VARCHAR(150)
);

-- 9. NguyenLieu
CREATE TABLE nguyen_lieu (
                             ma_nguyen_lieu VARCHAR(50) PRIMARY KEY,
                             ten_nguyen_lieu VARCHAR(200) NOT NULL,
                             don_vi_tinh VARCHAR(50) NOT NULL,
                             mo_ta TEXT,
                             muc_ton_toi_thieu INTEGER NOT NULL DEFAULT 0 CHECK (muc_ton_toi_thieu >= 0),
                             trang_thai enum_trang_thai_danh_muc NOT NULL DEFAULT 'DANG_HOAT_DONG' -- Phục vụ ngừng hoạt động khi xóa đã có dữ liệu
);

-- 10. LoNguyenLieu
CREATE TABLE lo_nguyen_lieu (
                                ma_lo VARCHAR(50) PRIMARY KEY,
                                ngay_san_xuat DATE NOT NULL,
                                han_su_dung DATE NOT NULL,
                                so_luong INTEGER NOT NULL CHECK (so_luong >= 0),
                                trang_thai enum_trang_thai_lo NOT NULL DEFAULT 'CHO_KIEM_DINH',
                                ma_nguyen_lieu VARCHAR(50) NOT NULL REFERENCES nguyen_lieu(ma_nguyen_lieu),
                                ma_phieu_giao VARCHAR(50),
                                CHECK (han_su_dung >= ngay_san_xuat)
);

-- 11. PhieuGiaoNguyenLieu
CREATE TABLE phieu_giao_nguyen_lieu (
                                        ma_phieu_giao VARCHAR(50) PRIMARY KEY,
                                        ngay_giao DATE NOT NULL DEFAULT CURRENT_DATE,
                                        trang_thai enum_trang_thai_phieu_giao NOT NULL DEFAULT 'CHO_TIEP_NHAN',
                                        ma_don_hang VARCHAR(50)
);

-- 12. PhieuKiemTraChatLuong
CREATE TABLE phieu_kiem_tra_chat_luong (
                                           ma_phieu_kiem_tra VARCHAR(50) PRIMARY KEY,
                                           ngay_kiem_tra DATE NOT NULL DEFAULT CURRENT_DATE,
                                           ket_qua enum_ket_qua_kiem_tra NOT NULL,
                                           ghi_chu TEXT,
                                           ma_phieu_giao VARCHAR(50) REFERENCES phieu_giao_nguyen_lieu(ma_phieu_giao)
);

-- 13. ChiTietKiemTraChatLuong
CREATE TABLE chi_tiet_kiem_tra_chat_luong (
                                              ma_chi_tiet VARCHAR(50) PRIMARY KEY,
                                              so_luong_dat INTEGER NOT NULL CHECK (so_luong_dat >= 0),
                                              so_luong_khong_dat INTEGER NOT NULL CHECK (so_luong_khong_dat >= 0),
                                              ghi_chu TEXT,
                                              ma_phieu_kiem_tra VARCHAR(50) NOT NULL REFERENCES phieu_kiem_tra_chat_luong(ma_phieu_kiem_tra) ON DELETE CASCADE,
                                              ma_lo VARCHAR(50) NOT NULL REFERENCES lo_nguyen_lieu(ma_lo)
);

-- 14. PhieuYeuCauNhapKho
CREATE TABLE phieu_yeu_cau_nhap_kho (
                                        ma_phieu_yeu_cau VARCHAR(50) PRIMARY KEY,
                                        ngay_yeu_cau DATE NOT NULL DEFAULT CURRENT_DATE,
                                        ly_do_nhap TEXT,
                                        trang_thai enum_trang_thai_yeu_cau NOT NULL DEFAULT 'CHO_DUYET',
                                        ma_lenh VARCHAR(50) REFERENCES lenh_san_xuat(ma_lenh),
                                        ma_phieu_giao VARCHAR(50) REFERENCES phieu_giao_nguyen_lieu(ma_phieu_giao)
);

-- 15. ChiTietYeuCauNhap
CREATE TABLE chi_tiet_yeu_cau_nhap (
                                       ma_chi_tiet VARCHAR(50) PRIMARY KEY,
                                       so_luong_yeu_cau INTEGER NOT NULL CHECK (so_luong_yeu_cau > 0),
                                       ma_phieu_yeu_cau VARCHAR(50) NOT NULL REFERENCES phieu_yeu_cau_nhap_kho(ma_phieu_yeu_cau) ON DELETE CASCADE,
                                       ma_nguyen_lieu VARCHAR(50) REFERENCES nguyen_lieu(ma_nguyen_lieu),
                                       ma_thanh_pham VARCHAR(50)
);

-- 16. PhieuNhapKho
CREATE TABLE phieu_nhap_kho (
                                ma_phieu_nhap VARCHAR(50) PRIMARY KEY,
                                ngay_nhap DATE NOT NULL DEFAULT CURRENT_DATE,
                                ly_do_nhap TEXT,
                                trang_thai enum_trang_thai_chung_tu NOT NULL DEFAULT 'CHO_XAC_NHAN',
                                ma_phieu_yeu_cau VARCHAR(50) REFERENCES phieu_yeu_cau_nhap_kho(ma_phieu_yeu_cau),
                                ma_phieu_kiem_tra VARCHAR(50) REFERENCES phieu_kiem_tra_chat_luong(ma_phieu_kiem_tra),
                                ma_kho VARCHAR(50)
);

-- 17. ChiTietPhieuNhap
CREATE TABLE chi_tiet_phieu_nhap (
                                     ma_chi_tiet VARCHAR(50) PRIMARY KEY,
                                     so_luong_nhap INTEGER NOT NULL CHECK (so_luong_nhap > 0),
                                     don_gia INTEGER NOT NULL CHECK (don_gia >= 0),
                                     ma_phieu_nhap VARCHAR(50) NOT NULL REFERENCES phieu_nhap_kho(ma_phieu_nhap) ON DELETE CASCADE,
                                     ma_lo VARCHAR(50) NOT NULL REFERENCES lo_nguyen_lieu(ma_lo)
);

-- 18. PhieuYeuCauXuatKho
CREATE TABLE phieu_yeu_cau_xuat_kho (
                                        ma_phieu_yeu_cau VARCHAR(50) PRIMARY KEY,
                                        ngay_yeu_cau DATE NOT NULL DEFAULT CURRENT_DATE,
                                        ly_do_xuat TEXT NOT NULL,
                                        trang_thai enum_trang_thai_yeu_cau NOT NULL DEFAULT 'CHO_DUYET',
                                        ma_lenh VARCHAR(50) REFERENCES lenh_san_xuat(ma_lenh)
);

-- 19. ChiTietYeuCauXuat
CREATE TABLE chi_tiet_yeu_cau_xuat (
                                       ma_chi_tiet VARCHAR(50) PRIMARY KEY,
                                       so_luong_yeu_cau INTEGER NOT NULL CHECK (so_luong_yeu_cau > 0),
                                       ma_phieu_yeu_cau VARCHAR(50) NOT NULL REFERENCES phieu_yeu_cau_xuat_kho(ma_phieu_yeu_cau) ON DELETE CASCADE,
                                       ma_nguyen_lieu VARCHAR(50) NOT NULL REFERENCES nguyen_lieu(ma_nguyen_lieu)
);

-- 20. PhieuXuatKho
CREATE TABLE phieu_xuat_kho (
                                ma_phieu_xuat VARCHAR(50) PRIMARY KEY,
                                ngay_xuat DATE NOT NULL DEFAULT CURRENT_DATE,
                                ly_do_xuat TEXT,
                                trang_thai enum_trang_thai_chung_tu NOT NULL DEFAULT 'CHO_XAC_NHAN',
                                ma_phieu_yeu_cau VARCHAR(50) NOT NULL REFERENCES phieu_yeu_cau_xuat_kho(ma_phieu_yeu_cau),
                                ma_kho VARCHAR(50)
);

-- 21. ChiTietPhieuXuat
CREATE TABLE chi_tiet_phieu_xuat (
                                     ma_chi_tiet VARCHAR(50) PRIMARY KEY,
                                     so_luong_xuat INTEGER NOT NULL CHECK (so_luong_xuat > 0),
                                     ma_phieu_xuat VARCHAR(50) NOT NULL REFERENCES phieu_xuat_kho(ma_phieu_xuat) ON DELETE CASCADE,
                                     ma_lo VARCHAR(50) NOT NULL REFERENCES lo_nguyen_lieu(ma_lo)
);

-- 22. ThanhPham
CREATE TABLE thanh_pham (
                            ma_thanh_pham VARCHAR(50) PRIMARY KEY,
                            ten_thanh_pham VARCHAR(200) NOT NULL,
                            don_vi_tinh VARCHAR(50) NOT NULL,
                            so_luong INTEGER NOT NULL DEFAULT 0 CHECK (so_luong >= 0),
                            trang_thai enum_trang_thai_danh_muc NOT NULL DEFAULT 'DANG_HOAT_DONG'
);

-- 23. PhieuKiemTraThanhPham
CREATE TABLE phieu_kiem_tra_thanh_pham (
                                           ma_phieu_kiem_tra VARCHAR(50) PRIMARY KEY,
                                           ngay_kiem_tra DATE NOT NULL DEFAULT CURRENT_DATE,
                                           ket_qua enum_ket_qua_kiem_tra NOT NULL,
                                           ghi_chu TEXT,
                                           ma_phieu_yeu_cau VARCHAR(50) REFERENCES phieu_yeu_cau_nhap_kho(ma_phieu_yeu_cau)
);

-- 24. PhieuNhapKhoThanhPham
CREATE TABLE phieu_nhap_kho_thanh_pham (
                                           ma_phieu_nhap VARCHAR(50) PRIMARY KEY,
                                           ngay_nhap DATE NOT NULL DEFAULT CURRENT_DATE,
                                           trang_thai enum_trang_thai_chung_tu NOT NULL DEFAULT 'CHO_XAC_NHAN',
                                           ma_phieu_yeu_cau VARCHAR(50) REFERENCES phieu_yeu_cau_nhap_kho(ma_phieu_yeu_cau),
                                           ma_phieu_kiem_tra VARCHAR(50) REFERENCES phieu_kiem_tra_thanh_pham(ma_phieu_kiem_tra),
                                           ma_thanh_pham VARCHAR(50) REFERENCES thanh_pham(ma_thanh_pham)
);

-- 25. PhieuXuatThanhPham
CREATE TABLE phieu_xuat_thanh_pham (
                                       ma_phieu_xuat VARCHAR(50) PRIMARY KEY,
                                       ngay_xuat DATE NOT NULL DEFAULT CURRENT_DATE,
                                       trang_thai_phieu_xuat enum_trang_thai_chung_tu NOT NULL DEFAULT 'CHO_XAC_NHAN',
                                       ma_don_hang VARCHAR(50) REFERENCES don_hang_khach_hang(ma_don_hang),
                                       ma_thanh_pham VARCHAR(50) REFERENCES thanh_pham(ma_thanh_pham)
);

-- 26. PhieuKiemKe
CREATE TABLE phieu_kiem_ke (
                               ma_phieu_kiem_ke VARCHAR(50) PRIMARY KEY,
                               ngay_kiem_ke DATE NOT NULL DEFAULT CURRENT_DATE,
                               nguoi_kiem_ke VARCHAR(100) NOT NULL,
                               trang_thai_phieu_kiem_ke enum_trang_thai_kiem_ke NOT NULL DEFAULT 'DANG_KIEM_DEM',
                               ma_kho VARCHAR(50)
);

-- 27. ChiTietKiemKe
CREATE TABLE chi_tiet_kiem_ke (
                                  ma_chi_tiet_kiem_ke VARCHAR(50) PRIMARY KEY,
                                  so_luong_he_thong INTEGER NOT NULL CHECK (so_luong_he_thong >= 0),
                                  so_luong_thuc_te INTEGER NOT NULL CHECK (so_luong_thuc_te >= 0),
                                  so_luong_chenh_lech INTEGER GENERATED ALWAYS AS (so_luong_thuc_te - so_luong_he_thong) STORED,
                                  ma_phieu_kiem_ke VARCHAR(50) NOT NULL REFERENCES phieu_kiem_ke(ma_phieu_kiem_ke) ON DELETE CASCADE,
                                  ma_lo VARCHAR(50) NOT NULL REFERENCES lo_nguyen_lieu(ma_lo)
);

-- 28. BienBanXuLyChenhLech
CREATE TABLE bien_ban_xu_ly_chenh_lech (
                                           ma_bien_ban VARCHAR(50) PRIMARY KEY,
                                           ngay_lap DATE NOT NULL DEFAULT CURRENT_DATE,
                                           nguyen_nhan TEXT NOT NULL,
                                           bien_phap_xu_ly TEXT NOT NULL,
                                           trang_thai enum_trang_thai_bien_ban NOT NULL DEFAULT 'CHO_DUYET',
                                           ma_phieu_kiem_ke VARCHAR(50) NOT NULL UNIQUE REFERENCES phieu_kiem_ke(ma_phieu_kiem_ke)
);

-- 29. PhieuTieuHuy
CREATE TABLE phieu_tieu_huy (
                                ma_phieu_tieu_huy VARCHAR(50) PRIMARY KEY,
                                ngay_tieu_huy DATE NOT NULL DEFAULT CURRENT_DATE,
                                ly_do TEXT NOT NULL,
                                trang_thai enum_trang_thai_chung_tu NOT NULL DEFAULT 'CHO_XAC_NHAN',
                                ma_kho VARCHAR(50)
);

-- 30. ChiTietTieuHuy
CREATE TABLE chi_tiet_tieu_huy (
                                   ma_chi_tiet VARCHAR(50) PRIMARY KEY,
                                   so_luong_tieu_huy INTEGER NOT NULL CHECK (so_luong_tieu_huy > 0),
                                   ghi_chu TEXT,
                                   ma_phieu_tieu_huy VARCHAR(50) NOT NULL REFERENCES phieu_tieu_huy(ma_phieu_tieu_huy) ON DELETE CASCADE,
                                   ma_lo VARCHAR(50) NOT NULL REFERENCES lo_nguyen_lieu(ma_lo)
);

-- 31. DonDatHang
CREATE TABLE don_dat_hang (
                              ma_don_hang VARCHAR(50) PRIMARY KEY,
                              ngay_dat DATE NOT NULL DEFAULT CURRENT_DATE,
                              trang_thai enum_trang_thai_don_dat_hang NOT NULL DEFAULT 'DA_DAT',
                              ma_ke_hoach_mua VARCHAR(50) REFERENCES ke_hoach_mua(ma_ke_hoach_mua),
                              ma_nha_cung_cap VARCHAR(50) NOT NULL REFERENCES nha_cung_cap(ma_nha_cung_cap)
);

-- 32. ChiTietDonDatHang
CREATE TABLE chi_tiet_don_dat_hang (
                                       ma_don_hang VARCHAR(50) NOT NULL REFERENCES don_dat_hang(ma_don_hang) ON DELETE CASCADE,
                                       ma_nguyen_lieu VARCHAR(50) NOT NULL REFERENCES nguyen_lieu(ma_nguyen_lieu),
                                       so_luong_dat INTEGER NOT NULL CHECK (so_luong_dat > 0),
                                       so_luong_con_thieu INTEGER NOT NULL DEFAULT 0 CHECK (so_luong_con_thieu >= 0),
                                       PRIMARY KEY (ma_don_hang, ma_nguyen_lieu)
);

-- 33. ChiTietKeHoachMua
CREATE TABLE chi_tiet_ke_hoach_mua (
                                       ma_ke_hoach_mua VARCHAR(50) NOT NULL REFERENCES ke_hoach_mua(ma_ke_hoach_mua) ON DELETE CASCADE,
                                       ma_nguyen_lieu VARCHAR(50) NOT NULL REFERENCES nguyen_lieu(ma_nguyen_lieu),
                                       so_luong_du_kien_mua INTEGER NOT NULL CHECK (so_luong_du_kien_mua > 0),
                                       PRIMARY KEY (ma_ke_hoach_mua, ma_nguyen_lieu)
);

-- 34. Kho
CREATE TABLE kho (
                     ma_kho VARCHAR(50) PRIMARY KEY,
                     ten_kho VARCHAR(150) NOT NULL,
                     loai_kho VARCHAR(50) NOT NULL,
                     vi_tri TEXT,
                     nguoi_phu_trach VARCHAR(100),
                     suc_chua INTEGER NOT NULL CHECK (suc_chua > 0),
                     mo_ta TEXT,
                     trang_thai enum_trang_thai_danh_muc NOT NULL DEFAULT 'DANG_HOAT_DONG'
);

-- 35. TonKho
CREATE TABLE ton_kho (
                         ma_kho VARCHAR(50) NOT NULL REFERENCES kho(ma_kho),
                         ma_lo VARCHAR(50) NOT NULL REFERENCES lo_nguyen_lieu(ma_lo),
                         vi_tri VARCHAR(100) NOT NULL,
                         so_luong_ton INTEGER NOT NULL DEFAULT 0 CHECK (so_luong_ton >= 0),
                         PRIMARY KEY (ma_kho, ma_lo, vi_tri)
);

-- =========================================================================
-- RÀNG BUỘC KHÓA NGOẠI BỔ SUNG
-- =========================================================================
ALTER TABLE tai_khoan ADD FOREIGN KEY (ma_vai_tro) REFERENCES vai_tro(ma_vai_tro);
ALTER TABLE lenh_san_xuat ADD FOREIGN KEY (ma_thanh_pham) REFERENCES thanh_pham(ma_thanh_pham);
ALTER TABLE lo_nguyen_lieu ADD FOREIGN KEY (ma_phieu_giao) REFERENCES phieu_giao_nguyen_lieu(ma_phieu_giao);
ALTER TABLE phieu_giao_nguyen_lieu ADD FOREIGN KEY (ma_don_hang) REFERENCES don_dat_hang(ma_don_hang);
ALTER TABLE chi_tiet_yeu_cau_nhap ADD FOREIGN KEY (ma_thanh_pham) REFERENCES thanh_pham(ma_thanh_pham);
ALTER TABLE phieu_nhap_kho ADD FOREIGN KEY (ma_kho) REFERENCES kho(ma_kho);
ALTER TABLE phieu_xuat_kho ADD FOREIGN KEY (ma_kho) REFERENCES kho(ma_kho);
ALTER TABLE phieu_kiem_ke ADD FOREIGN KEY (ma_kho) REFERENCES kho(ma_kho);
ALTER TABLE phieu_tieu_huy ADD FOREIGN KEY (ma_kho) REFERENCES kho(ma_kho);