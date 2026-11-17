SET search_path TO wms, public;
BEGIN;

INSERT INTO wms.vai_tro (ma_vai_tro, ten_vai_tro, mo_ta) VALUES
    ('QUAN_TRI',         'Quản trị viên',    'Quản lý tài khoản và bảo trì hệ thống'),
    ('NHAN_VIEN_KHO',    'Nhân viên kho',    'Lập phiếu nhập, xuất kho'),
    ('BO_PHAN_MUA_HANG', 'Bộ phận mua hàng', 'Lập kế hoạch và đặt mua nguyên liệu'),
    ('BAN_GIAM_DOC',     'Ban giám đốc',     'Phê duyệt yêu cầu và xem báo cáo'),
    ('XUONG_SAN_XUAT',   'Xưởng sản xuất',   'Lập phiếu yêu cầu nguyên liệu, thành phẩm')
ON CONFLICT (ma_vai_tro) DO NOTHING;

INSERT INTO wms.tai_khoan
    (ma_tai_khoan, ten_dang_nhap, mat_khau, ho_ten, email, so_dien_thoai, trang_thai, ma_vai_tro)
VALUES
    ('TK001', 'admin',        'REPLACE_WITH_BCRYPT_ADMIN_HASH', 'Quản trị hệ thống',    'admin@kho.local',    '0900000001', 'HOAT_DONG', 'QUAN_TRI'),
    ('TK002', 'phuc.admin',   'REPLACE_WITH_BCRYPT_ADMIN_HASH', 'Lê Bùi Mạnh Phúc',     'phuc@kho.local',     '0900000002', 'HOAT_DONG', 'QUAN_TRI'),
    ('TK003', 'nv.kho01',     'REPLACE_WITH_BCRYPT_USER_HASH',  'Nguyễn Văn An',        'an.nv@kho.local',    '0900000003', 'HOAT_DONG', 'NHAN_VIEN_KHO'),
    ('TK004', 'nv.kho02',     'REPLACE_WITH_BCRYPT_USER_HASH',  'Trần Thị Bình',        'binh.tt@kho.local',  '0900000004', 'KHOA',      'NHAN_VIEN_KHO'),
    ('TK005', 'nv.muahang01', 'REPLACE_WITH_BCRYPT_USER_HASH',  'Lê Hoàng Cường',       'cuong.lh@kho.local', '0900000005', 'HOAT_DONG', 'BO_PHAN_MUA_HANG'),
    ('TK006', 'nv.tamthoi',   'REPLACE_WITH_BCRYPT_USER_HASH',  'Phạm Tạm Thời',        'tamthoi@kho.local',  '0900000006', 'HOAT_DONG', 'NHAN_VIEN_KHO'),
    ('TK007', 'nv.daxoa.thu', 'REPLACE_WITH_BCRYPT_USER_HASH',  'Hoàng Đã Có Lịch Sử',  'lichsu.hd@kho.local','0900000007', 'HOAT_DONG', 'NHAN_VIEN_KHO')
ON CONFLICT (ma_tai_khoan) DO NOTHING;

INSERT INTO wms.nhat_ky_he_thong
    (ma_nhat_ky, thoi_gian, hanh_dong, noi_dung, dia_chi_ip, ma_tai_khoan, ten_dang_nhap_luc_do)
VALUES
    ('NK001', now() - interval '10 days', 'DANG_NHAP',     'Đăng nhập thành công',       '192.168.1.20', 'TK007', 'nv.daxoa.thu'),
    ('NK002', now() - interval '9 days',  'TAO_PHIEU_NHAP', 'Lập phiếu nhập kho PN-0001', '192.168.1.20', 'TK007', 'nv.daxoa.thu'),
    ('NK003', now() - interval '2 days',  'DANG_NHAP',     'Đăng nhập thành công',       '192.168.1.21', 'TK001', 'admin'),
    ('NK004', now() - interval '1 day',   'THEM_TAI_KHOAN','Tạo tài khoản nv.daxoa.thu', '192.168.1.21', 'TK001', 'admin')
ON CONFLICT (ma_nhat_ky) DO NOTHING;

INSERT INTO wms.ban_sao_luu
    (ma_ban_sao, thoi_gian_tao, duong_dan_file, dung_luong_bytes, checksum, trang_thai, ma_tai_khoan)
VALUES
    ('BS001', now() - interval '3 days', '/backup/kho_20261114.dump', 52428800,
     'a3f1c9e0b7d24f5e8c6a1b2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f', 'HOP_LE', 'TK001'),
    ('BS002', now() - interval '1 day', '/backup/kho_20261116.dump', 0,
     NULL, 'LOI', 'TK002')
ON CONFLICT (ma_ban_sao) DO NOTHING;

COMMIT;
