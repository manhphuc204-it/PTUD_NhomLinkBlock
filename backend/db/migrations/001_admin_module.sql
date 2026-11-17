SET search_path TO wms, public;
BEGIN;

-- 1. Enum trạng thái tài khoản
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_trang_thai_tai_khoan') THEN
    CREATE TYPE wms.enum_trang_thai_tai_khoan AS ENUM ('HOAT_DONG', 'KHOA');
  END IF;
END $$;

-- 2. Chuyển cột trạng thái sang enum mới (chỉ khi còn dùng enum cũ)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'wms' AND table_name = 'tai_khoan'
               AND column_name = 'trang_thai' AND udt_name = 'enum_trang_thai_danh_muc') THEN
    ALTER TABLE wms.tai_khoan ALTER COLUMN trang_thai DROP DEFAULT;
    ALTER TABLE wms.tai_khoan ALTER COLUMN trang_thai TYPE wms.enum_trang_thai_tai_khoan
      USING (CASE WHEN trang_thai::text = 'DANG_HOAT_DONG' THEN 'HOAT_DONG' ELSE 'KHOA' END)::wms.enum_trang_thai_tai_khoan;
  END IF;
END $$;
ALTER TABLE wms.tai_khoan ALTER COLUMN trang_thai SET DEFAULT 'HOAT_DONG';

-- 3. Vai trò bắt buộc
ALTER TABLE wms.tai_khoan ALTER COLUMN ma_vai_tro SET NOT NULL;

-- 4. Nhật ký: bỏ FK cũ chặn xóa, thêm FK SET NULL
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT conname FROM pg_constraint
           WHERE conrelid = 'wms.nhat_ky_he_thong'::regclass
             AND contype = 'f' AND confrelid = 'wms.tai_khoan'::regclass LOOP
    EXECUTE format('ALTER TABLE wms.nhat_ky_he_thong DROP CONSTRAINT %I', r.conname);
  END LOOP;
END $$;
ALTER TABLE wms.nhat_ky_he_thong DROP CONSTRAINT IF EXISTS fk_nhat_ky_tai_khoan;
ALTER TABLE wms.nhat_ky_he_thong ADD CONSTRAINT fk_nhat_ky_tai_khoan
  FOREIGN KEY (ma_tai_khoan) REFERENCES wms.tai_khoan(ma_tai_khoan) ON DELETE SET NULL;

-- 5. Nhật ký: cột tên đăng nhập tại thời điểm thao tác, kiểu thời gian, index
ALTER TABLE wms.nhat_ky_he_thong ADD COLUMN IF NOT EXISTS ten_dang_nhap_luc_do VARCHAR(100);
ALTER TABLE wms.nhat_ky_he_thong ALTER COLUMN thoi_gian TYPE TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_nhat_ky_thoi_gian ON wms.nhat_ky_he_thong(thoi_gian);
CREATE INDEX IF NOT EXISTS idx_nhat_ky_tai_khoan ON wms.nhat_ky_he_thong(ma_tai_khoan);

-- 6. Cấu hình hệ thống (cờ bảo trì, ngưỡng dung lượng)
CREATE TABLE IF NOT EXISTS wms.cau_hinh_he_thong (
    khoa VARCHAR(100) PRIMARY KEY,
    gia_tri TEXT NOT NULL,
    cap_nhat_luc TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO wms.cau_hinh_he_thong (khoa, gia_tri) VALUES
    ('CHE_DO_BAO_TRI', 'false'),
    ('NGUONG_DUNG_LUONG_TOI_THIEU_MB', '1024')
ON CONFLICT (khoa) DO NOTHING;

-- 7. Bản sao lưu
CREATE TABLE IF NOT EXISTS wms.ban_sao_luu (
    ma_ban_sao VARCHAR(50) PRIMARY KEY,
    thoi_gian_tao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    duong_dan_file TEXT NOT NULL,
    dung_luong_bytes BIGINT NOT NULL CHECK (dung_luong_bytes >= 0),
    checksum VARCHAR(128),
    trang_thai VARCHAR(20) NOT NULL CHECK (trang_thai IN ('HOP_LE', 'LOI')),
    ma_tai_khoan VARCHAR(50) REFERENCES wms.tai_khoan(ma_tai_khoan) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_ban_sao_thoi_gian ON wms.ban_sao_luu(thoi_gian_tao);

-- 8. Token quên mật khẩu
CREATE TABLE IF NOT EXISTS wms.token_dat_lai_mat_khau (
    ma_token VARCHAR(50) PRIMARY KEY,
    token_hash VARCHAR(128) NOT NULL,
    het_han TIMESTAMPTZ NOT NULL,
    da_su_dung BOOLEAN NOT NULL DEFAULT FALSE,
    ma_tai_khoan VARCHAR(50) NOT NULL REFERENCES wms.tai_khoan(ma_tai_khoan) ON DELETE CASCADE
);

COMMIT;