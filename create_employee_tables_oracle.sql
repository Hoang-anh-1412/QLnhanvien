-- =====================================================
-- ORACLE SQL SCRIPT - TẠO CÁC BẢNG QUẢN LÝ NHÂN VIÊN
-- Chuyển đổi từ SQL Server sang Oracle
-- =====================================================

-- Thiết lập encoding cho Oracle (Japanese)
ALTER SESSION SET NLS_LANGUAGE = 'JAPANESE';
ALTER SESSION SET NLS_TERRITORY = 'JAPAN';

-- =====================================================
-- XÓA CÁC BẢNG CŨ (NẾU CÓ)
-- =====================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE T_年休詳細 CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE T_資格 CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE T_資格手当 CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE T_溶接免許 CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE T_社員マスタ CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE T_部署名 CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE T_統括部門 CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


-- =====================================================
-- TẠO CÁC SEQUENCE CHO AUTO-INCREMENT
-- =====================================================

-- Sequence cho T_統括部門
CREATE SEQUENCE SEQ_統括部門_ID
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho T_資格手当
CREATE SEQUENCE SEQ_資格手当_ID
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho T_資格
CREATE SEQUENCE SEQ_資格_ID
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence cho T_年休詳細
CREATE SEQUENCE SEQ_年休詳細_ID
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;


-- Sequence cho T_溶接免許
CREATE SEQUENCE SEQ_溶接免許_ID
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- =====================================================
-- BẢNG 1: T_統括部門 (Master Đơn Vị Quản Lý Cấp Cao)
-- =====================================================
CREATE TABLE T_統括部門 (
    部門ID NUMBER(10) PRIMARY KEY,              -- ID_Don_Vi_Quan_Ly (Khóa chính)
    統括部門 VARCHAR2(100 CHAR),                -- Ten_Don_Vi_Quan_Ly
    フィールド1 VARCHAR2(50 CHAR)               -- Truong_1 (Cột dữ liệu không rõ mục đích)
);

COMMENT ON TABLE T_統括部門 IS 'Controlling Division Master Table';
COMMENT ON COLUMN T_統括部門.部門ID IS 'Division ID (Primary Key)';
COMMENT ON COLUMN T_統括部門.統括部門 IS 'Division Name';
COMMENT ON COLUMN T_統括部門.フィールド1 IS 'Field 1 (Additional data field)';

-- =====================================================
-- BẢNG 2: T_部署名 (Master Bộ Phận/Phòng Ban)
-- =====================================================
CREATE TABLE T_部署名 (
    部署ID VARCHAR2(50 CHAR) PRIMARY KEY,       -- ID_Bo_Phan (Khóa chính)
    部門ID NUMBER(10),                          -- ID_Don_Vi_Quan_Ly (Khóa ngoại tới T_統括部門)
    部署名 VARCHAR2(100 CHAR),                  -- Ten_Bo_Phan_Phong_Ban
    CONSTRAINT FK_部署_部門 FOREIGN KEY (部門ID) REFERENCES T_統括部門(部門ID)
);

COMMENT ON TABLE T_部署名 IS 'Department Master Table';
COMMENT ON COLUMN T_部署名.部署ID IS 'Department ID (Primary Key)';
COMMENT ON COLUMN T_部署名.部門ID IS 'Division ID (Foreign Key to T_統括部門)';
COMMENT ON COLUMN T_部署名.部署名 IS 'Department Name';

-- =====================================================
-- BẢNG 3: T_資格手当 (Master Phụ Cấp Chứng Chỉ)
-- =====================================================
CREATE TABLE T_資格手当 (
    資格ID NUMBER(10) PRIMARY KEY,              -- ID_Loai_Chung_Chi (Khóa chính)
    名称 VARCHAR2(100 CHAR),                    -- Ten_Chung_Chi (Tiêu chuẩn)
    等級 VARCHAR2(50 CHAR),                     -- Cap_Do_Loai (Tiêu chuẩn)
    種類 VARCHAR2(50 CHAR),                     -- Loai_Hinh (Tiêu chuẩn)
    金額 NUMBER(10, 2),                         -- Muc_Phu_Cap_Tien_Thuong
    備考 VARCHAR2(255 CHAR)                     -- Ghi_Chu
);

COMMENT ON TABLE T_資格手当 IS 'Qualification Allowance Master Table';
COMMENT ON COLUMN T_資格手当.資格ID IS 'Qualification ID (Primary Key)';
COMMENT ON COLUMN T_資格手当.名称 IS 'Qualification Name';
COMMENT ON COLUMN T_資格手当.等級 IS 'Grade Level';
COMMENT ON COLUMN T_資格手当.種類 IS 'Type';
COMMENT ON COLUMN T_資格手当.金額 IS 'Allowance Amount';
COMMENT ON COLUMN T_資格手当.備考 IS 'Remarks';


-- =====================================================
-- BẢNG 4: T_社員マスタ (Master Nhân Viên) - BẢNG CHÍNH
-- =====================================================
CREATE TABLE T_社員マスタ (
    社員コード VARCHAR2(50 CHAR) PRIMARY KEY,   -- Ma_Nhan_Vien (Khóa chính)
    部門名 VARCHAR2(100 CHAR),                  -- Ten_Don_Vi_Bo_Phan_Tong_The
    部署名 VARCHAR2(100 CHAR),                  -- Ten_Bo_Phan_Phong_Ban
    氏名 VARCHAR2(100 CHAR),                    -- Ho_Ten
    かな氏名 VARCHAR2(100 CHAR),                -- Ten_Dem_Phien_Am
    性別 VARCHAR2(10 CHAR),                     -- Gioi_Tinh
    生年月日 DATE,                              -- Ngay_Sinh
    入社年月日 DATE,                            -- Ngay_Vao_Lam
    入社基準日 DATE,                            -- Ngay_Chuan_Tinh_Tham_Nien
    退職年月日 DATE,                            -- Ngay_Nghi_Viec
    郵便番号1 VARCHAR2(20 CHAR),                -- Ma_Buu_Dien_1
    住所1 VARCHAR2(255 CHAR),                   -- Dia_Chi_1
    ビル名1 VARCHAR2(255 CHAR),                 -- Ten_Toa_Nha_1
    TEL1 VARCHAR2(50 CHAR),                     -- Dien_Thoai_1
    TEL携帯用 VARCHAR2(50 CHAR),                -- Dien_Thoai_Di_Dong
    郵便番号2 VARCHAR2(20 CHAR),                -- Ma_Buu_Dien_2
    住所2 VARCHAR2(255 CHAR),                   -- Dia_Chi_2
    TEL2 VARCHAR2(50 CHAR),                     -- Dien_Thoai_2
    ビル名2 VARCHAR2(255 CHAR),                 -- Ten_Toa_Nha_2
    結婚記念日 DATE,                            -- Ngay_Ky_Niem_Ket_Hon
    入社基準年 NUMBER(4),                       -- Nam_Chuan_Tinh_Tham_Nien
    今年度付与 NUMBER(5, 2),                    -- So_ngay_phep_duoc_cap_nam_nay
    前年度繰越 NUMBER(5, 2),                    -- So_ngay_phep_nam_truoc_chuyen_sang
    年休合計 NUMBER(5, 2),                      -- Tong_ngay_nghi_phep
    取得日数 NUMBER(5, 2),                      -- So_ngay_phep_da_su_dung
    残日数 NUMBER(5, 2),                        -- So_ngay_phep_con_lai
    夏休み1 DATE,                               -- Ngay_nghi_he_1
    夏休み5 DATE,                               -- Ngay_nghi_he_5
    備考 VARCHAR2(255 CHAR)                     -- Ghi_Chu
);

COMMENT ON TABLE T_社員マスタ IS 'Employee Master Table - MAIN TABLE';
COMMENT ON COLUMN T_社員マスタ.社員コード IS 'Employee Code (Primary Key)';
COMMENT ON COLUMN T_社員マスタ.部門名 IS 'Division Name';
COMMENT ON COLUMN T_社員マスタ.部署名 IS 'Department Name';
COMMENT ON COLUMN T_社員マスタ.氏名 IS 'Full Name';
COMMENT ON COLUMN T_社員マスタ.かな氏名 IS 'Name in Katakana';
COMMENT ON COLUMN T_社員マスタ.性別 IS 'Gender';
COMMENT ON COLUMN T_社員マスタ.生年月日 IS 'Date of Birth';
COMMENT ON COLUMN T_社員マスタ.入社年月日 IS 'Hire Date';
COMMENT ON COLUMN T_社員マスタ.入社基準日 IS 'Seniority Calculation Base Date';
COMMENT ON COLUMN T_社員マスタ.退職年月日 IS 'Resignation Date';
COMMENT ON COLUMN T_社員マスタ.郵便番号1 IS 'Postal Code 1';
COMMENT ON COLUMN T_社員マスタ.住所1 IS 'Address 1';
COMMENT ON COLUMN T_社員マスタ.ビル名1 IS 'Building Name 1';
COMMENT ON COLUMN T_社員マスタ.TEL1 IS 'Phone Number 1';
COMMENT ON COLUMN T_社員マスタ.TEL携帯用 IS 'Mobile Phone';
COMMENT ON COLUMN T_社員マスタ.郵便番号2 IS 'Postal Code 2';
COMMENT ON COLUMN T_社員マスタ.住所2 IS 'Address 2';
COMMENT ON COLUMN T_社員マスタ.TEL2 IS 'Phone Number 2';
COMMENT ON COLUMN T_社員マスタ.ビル名2 IS 'Building Name 2';
COMMENT ON COLUMN T_社員マスタ.結婚記念日 IS 'Wedding Anniversary';
COMMENT ON COLUMN T_社員マスタ.入社基準年 IS 'Seniority Calculation Base Year';
COMMENT ON COLUMN T_社員マスタ.今年度付与 IS 'Annual Leave Granted This Year';
COMMENT ON COLUMN T_社員マスタ.前年度繰越 IS 'Annual Leave Carried Over from Previous Year';
COMMENT ON COLUMN T_社員マスタ.年休合計 IS 'Total Annual Leave Days';
COMMENT ON COLUMN T_社員マスタ.取得日数 IS 'Annual Leave Days Used';
COMMENT ON COLUMN T_社員マスタ.残日数 IS 'Remaining Annual Leave Days';
COMMENT ON COLUMN T_社員マスタ.夏休み1 IS 'Summer Vacation 1';
COMMENT ON COLUMN T_社員マスタ.夏休み5 IS 'Summer Vacation 5';
COMMENT ON COLUMN T_社員マスタ.備考 IS 'Remarks';

-- =====================================================
-- BẢNG 5: T_資格 (Chứng Chỉ/Bằng Cấp Nhân Viên)
-- =====================================================
CREATE TABLE T_資格 (
    ID NUMBER(10) PRIMARY KEY,                  -- ID_Chung_Chi_Ban_ghi (Khóa chính)
    社員コード VARCHAR2(50 CHAR),               -- Ma_Nhan_Vien (Khóa ngoại tới T_社員マスタ)
    名称 VARCHAR2(100 CHAR),                    -- Ten_Chung_Chi
    等級 VARCHAR2(50 CHAR),                     -- Cap_Do_Loai
    種類 VARCHAR2(50 CHAR),                     -- Loai_Hinh
    金額 NUMBER(10, 2),                         -- So_Tien_Phu_Cap_Ghi_tai_thoi_diem_cap
    チェック NUMBER(1),                         -- Kiem_Tra_Trang_thai (Boolean: 0/1)
    番号 VARCHAR2(100 CHAR),                    -- So_Chung_Chi
    取得日 DATE,                                -- Ngay_Dat_Duoc_Cap
    資格ID NUMBER(10),                          -- ID_Loai_Chung_Chi (Khóa ngoại tới T_資格手当)
    CONSTRAINT FK_資格_社員 FOREIGN KEY (社員コード) REFERENCES T_社員マスタ(社員コード),
    CONSTRAINT FK_資格_手当 FOREIGN KEY (資格ID) REFERENCES T_資格手当(資格ID)
);

COMMENT ON TABLE T_資格 IS 'Employee Qualification Table';
COMMENT ON COLUMN T_資格.ID IS 'Qualification Record ID (Primary Key)';
COMMENT ON COLUMN T_資格.社員コード IS 'Employee Code (Foreign Key to T_社員マスタ)';
COMMENT ON COLUMN T_資格.名称 IS 'Qualification Name';
COMMENT ON COLUMN T_資格.等級 IS 'Grade Level';
COMMENT ON COLUMN T_資格.種類 IS 'Type';
COMMENT ON COLUMN T_資格.金額 IS 'Allowance Amount at Time of Grant';
COMMENT ON COLUMN T_資格.チェック IS 'Check Status (Boolean: 0/1)';
COMMENT ON COLUMN T_資格.番号 IS 'Certificate Number';
COMMENT ON COLUMN T_資格.取得日 IS 'Acquisition Date';
COMMENT ON COLUMN T_資格.資格ID IS 'Qualification Type ID (Foreign Key to T_資格手当)';

-- =====================================================
-- BẢNG 6: T_年休詳細 (Chi Tiết Ngày Nghỉ Phép Năm)
-- =====================================================
CREATE TABLE T_年休詳細 (
    ID NUMBER(10) PRIMARY KEY,                  -- ID_Chi_Tiet_Nghi_Phep (Khóa chính)
    社員コード VARCHAR2(50 CHAR),               -- Ma_Nhan_Vien (Khóa ngoại tới T_社員マスタ)
    取得日 DATE,                                -- Ngay_Da_Nghi
    日数 NUMBER(5, 2),                          -- So_Ngay_Nghi (0.5, 1.0,...)
    カウント NUMBER(10),                        -- Dem_So_lan_ghi_nhan
    CONSTRAINT FK_年休_社員 FOREIGN KEY (社員コード) REFERENCES T_社員マスタ(社員コード)
);

COMMENT ON TABLE T_年休詳細 IS 'Annual Leave Detail Table';
COMMENT ON COLUMN T_年休詳細.ID IS 'Leave Detail ID (Primary Key)';
COMMENT ON COLUMN T_年休詳細.社員コード IS 'Employee Code (Foreign Key to T_社員マスタ)';
COMMENT ON COLUMN T_年休詳細.取得日 IS 'Leave Date';
COMMENT ON COLUMN T_年休詳細.日数 IS 'Leave Days (0.5, 1.0,...)';
COMMENT ON COLUMN T_年休詳細.カウント IS 'Count Number';



-- =====================================================
-- BẢNG 7: T_溶接免許 (Chứng Chỉ Hàn/Cơ Khí)
-- =====================================================
CREATE TABLE T_溶接免許 (
    ID NUMBER(10) PRIMARY KEY,                  -- ID_Chung_Chi_Han (Khóa chính)
    有効年月日 DATE,                            -- Ngay_Het_Han
    継続年月日 DATE,                            -- Ngay_Gia_Han
    登録年月日 DATE,                            -- Ngay_Dang_Ky_Cap
    証明書番号 VARCHAR2(100 CHAR),              -- So_Chung_Thu
    氏名 VARCHAR2(100 CHAR),                    -- Ho_Ten_Nhan_Vien
    合格資格 VARCHAR2(100 CHAR),                -- Chung_Chi_Dat_Duoc
    級区分 VARCHAR2(50 CHAR),                   -- Cap_Bac
    証明書 VARCHAR2(100 CHAR),                  -- Loai_Chung_Thu
    不要 NUMBER(1),                             -- Khong_Can_Khong_Yeu_Cau (Cờ Boolean)
    チェック NUMBER(1)                          -- Kiem_Tra_Trang_thai (Cờ Boolean)
);

COMMENT ON TABLE T_溶接免許 IS 'Welding License Table';
COMMENT ON COLUMN T_溶接免許.ID IS 'Welding License ID (Primary Key)';
COMMENT ON COLUMN T_溶接免許.有効年月日 IS 'Expiration Date';
COMMENT ON COLUMN T_溶接免許.継続年月日 IS 'Renewal Date';
COMMENT ON COLUMN T_溶接免許.登録年月日 IS 'Registration Date';
COMMENT ON COLUMN T_溶接免許.証明書番号 IS 'Certificate Number';
COMMENT ON COLUMN T_溶接免許.氏名 IS 'Employee Name';
COMMENT ON COLUMN T_溶接免許.合格資格 IS 'Qualification Obtained';
COMMENT ON COLUMN T_溶接免許.級区分 IS 'Grade Classification';
COMMENT ON COLUMN T_溶接免許.証明書 IS 'Certificate Type';
COMMENT ON COLUMN T_溶接免許.不要 IS 'Not Required (Boolean Flag)';
COMMENT ON COLUMN T_溶接免許.チェック IS 'Check Status (Boolean Flag)';

-- =====================================================
-- TẠO CÁC TRIGGER CHO AUTO-INCREMENT
-- =====================================================

-- Trigger cho T_統括部門
CREATE OR REPLACE TRIGGER TRG_統括部門_ID
    BEFORE INSERT ON T_統括部門
    FOR EACH ROW
BEGIN
    IF :NEW.部門ID IS NULL THEN
        :NEW.部門ID := SEQ_統括部門_ID.NEXTVAL;
    END IF;
END;
/

-- Trigger cho T_資格手当
CREATE OR REPLACE TRIGGER TRG_資格手当_ID
    BEFORE INSERT ON T_資格手当
    FOR EACH ROW
BEGIN
    IF :NEW.資格ID IS NULL THEN
        :NEW.資格ID := SEQ_資格手当_ID.NEXTVAL;
    END IF;
END;
/

-- Trigger cho T_資格
CREATE OR REPLACE TRIGGER TRG_資格_ID
    BEFORE INSERT ON T_資格
    FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
        :NEW.ID := SEQ_資格_ID.NEXTVAL;
    END IF;
END;
/

-- Trigger cho T_年休詳細
CREATE OR REPLACE TRIGGER TRG_年休詳細_ID
    BEFORE INSERT ON T_年休詳細
    FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
        :NEW.ID := SEQ_年休詳細_ID.NEXTVAL;
    END IF;
END;
/


-- Trigger cho T_溶接免許
CREATE OR REPLACE TRIGGER TRG_溶接免許_ID
    BEFORE INSERT ON T_溶接免許
    FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
        :NEW.ID := SEQ_溶接免許_ID.NEXTVAL;
    END IF;
END;
/

-- =====================================================
-- TẠO CÁC INDEX ĐỂ TỐI ƯU HIỆU SUẤT
-- =====================================================

-- Index cho các khóa ngoại
CREATE INDEX IDX_部署名_部門ID ON T_部署名(部門ID);
CREATE INDEX IDX_資格_社員コード ON T_資格(社員コード);
CREATE INDEX IDX_資格_資格ID ON T_資格(資格ID);
CREATE INDEX IDX_年休詳細_社員コード ON T_年休詳細(社員コード);

-- Index cho các trường thường được tìm kiếm
CREATE INDEX IDX_社員マスタ_氏名 ON T_社員マスタ(氏名);
CREATE INDEX IDX_社員マスタ_部署名 ON T_社員マスタ(部署名);
CREATE INDEX IDX_社員マスタ_入社年月日 ON T_社員マスタ(入社年月日);

-- =====================================================
-- THÔNG BÁO HOÀN THÀNH
-- =====================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('HOÀN THÀNH TẠO CÁC BẢNG QUẢN LÝ NHÂN VIÊN');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
    DBMS_OUTPUT.PUT_LINE('Đã tạo thành công:');
    DBMS_OUTPUT.PUT_LINE('- 7 bảng chính (đã loại bỏ các bảng đồng phục)');
    DBMS_OUTPUT.PUT_LINE('- 5 sequence cho auto-increment');
    DBMS_OUTPUT.PUT_LINE('- 5 trigger cho auto-increment');
    DBMS_OUTPUT.PUT_LINE('- 7 index để tối ưu hiệu suất');
    DBMS_OUTPUT.PUT_LINE('- Tất cả foreign key constraints');
    DBMS_OUTPUT.PUT_LINE('- Comments cho tất cả bảng và cột');
    DBMS_OUTPUT.PUT_LINE('=====================================================');
END;
/

COMMIT;
