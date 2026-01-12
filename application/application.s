# ==============================
# Đoạn code này sử dụng khi cả 3 bit SW[14:12] đều được xử lý tắt HEX trong chương trình
# ENABLE = 0  -> clear LED (không hiển thị)
# ENABLE = 1  -> DEC -> HEX0..3,  HEX -> HEX4..7
# Map:
#   SW_BASE   = 0x10010000
#   HEX_LO    = 0x10002000
#   HEX_HI    = 0x10003000
# ==============================

_start:
  # --- Chuẩn bị địa chỉ  ---
    lui     s11, 0x10010       # s11 = 0x10010000 (SW base)
    lui     t4, 0x10002       # t4 = 0x10002000 (HEX_LO)
    lui     t5, 0x10003       # t5 = 0x10003000 (HEX_HI)
    lui     s9, 0x10000       # s9 = 0x10000000  (LEDR base)


main_loop:
   lw      s8, 0(s11)         # s8 = giá trị SW 32-bit

# ----- LEDR = SW[14:0] (luôn hiển thị, không phụ thuộc enable) -----

    addi    s10, s8, 0       # Dùng s10 
    slli    s10, s10, 17     # Giữ 15 bit thấp
    srli    s10, s10, 17
    sw      s10, 0(s9)       # LEDR <= SW[14:0]

    # --- Lấy ENABLE = SW[12] ---
    srli    t6, s8, 12
    andi    t6, t6, 1         # t6 = SW[12] (0/1)

    beq     t6, x0, disabled  # nếu enable == 0 -> clear LED

    # --- Có enable: lấy giá trị 12-bit n = SW[11:0] ---
   addi    t1, s8, 0      
   slli    t1, t1, 20     # Dịch trái 20 bit (xóa 20 bit cao)
   srli    t1, t1, 20     # Dịch phải 20 bit (đưa 12 bit thấp về đúng vị trí). không sài andi t1, s8, 0xFFF vì venus không simulation đc

    # ----- Khởi tạo thanh ghi mã 7-seg cho 8 LED -----

    addi    s0, x0, 0xFF
    addi    s1, x0, 0xFF
    addi    s2, x0, 0xFF
    addi    s3, x0, 0xFF
    addi    s4, x0, 0xFF
    addi    s5, x0, 0xFF
    addi    s6, x0, 0xFF
    addi    s7, x0, 0xFF


    # =================== PHẦN DEC (HEX0..HEX3) ===================
    addi    t2, t1, 0         # t2 = n 
    beq     t2, x0, dec_is_zero

    addi    t3, x0, 4         # t3 = 4 => chữ số tối đa
    addi    a3, x0, 0         

dec_loop:
    beq     t2, x0, done_dec  # hết số -> dừng
    beq     a3, t3, done_dec  

    # -- Chia 10 bằng trừ lặp  --
    addi    a0, t2, 0
    addi    a1, x0, 0
    addi    a2, x0, 10
div10_dec:
    bltu    a0, a2, enddiv_dec
    addi    a0, a0, -10
    addi    a1, a1, 1
    jal     x0, div10_dec
enddiv_dec:

    # -- Map remainder (0..9)  --
    jal     ra, map_hex_digit

    # -- Gán vào s0..s3 theo thứ tự HEX0..HEX3  --
    addi    a4, x0, 0       
    beq     a3, a4, st_dec0
    addi    a4, x0, 1
    beq     a3, a4, st_dec1
    addi    a4, x0, 2
    beq     a3, a4, st_dec2
    addi    a4, x0, 3
    beq     a3, a4, st_dec3
    jal     x0, after_store_dec


st_dec0: 
    addi s0, a0, 0
    jal x0, after_store_dec
st_dec1: 
    addi s1, a0, 0 
    jal x0, after_store_dec
st_dec2: 
    addi s2, a0, 0
    jal x0, after_store_dec
st_dec3: 
    addi s3, a0, 0 
    jal x0,  after_store_dec

after_store_dec:
    addi    a3, a3, 1         
    addi    t2, a1, 0         # n = quotient  ( n/10 )
    jal     x0, dec_loop

dec_is_zero:
    addi    s0, x0, 0xC0      # mã 7-seg của '0'
    addi    a3, x0, 1         

done_dec:
    # =================== PHẦN HEX (HEX4..HEX7) ===================
    andi    a0, t1, 0xF
    jal     ra, map_hex_digit
    addi    s4, a0, 0

    srli    t6, t1, 4
    andi    a0, t6, 0xF
    jal     ra, map_hex_digit
    addi    s5, a0, 0

    srli    t6, t1, 8
    andi    a0, t6, 0xF
    jal     ra, map_hex_digit
    addi    s6, a0, 0

    srli    t6, t1, 12
    andi    a0, t6, 0xF
    jal     ra, map_hex_digit
    addi    s7, a0, 0

    # =================== PACK & GHI ===================
pack_and_write:
    # word_lo = (HEX3<<24)|(HEX2<<16)|(HEX1<<8)|HEX0
    slli    t1, s3, 24
    slli    t2, s2, 16
    or      t1, t1, t2
    slli    t2, s1, 8
    or      t1, t1, t2
    or      t1, t1, s0

    # word_hi = (HEX7<<24)|(HEX6<<16)|(HEX5<<8)|HEX4
    slli    t2, s7, 24
    slli    t3, s6, 16
    or      t2, t2, t3
    slli    t3, s5, 8
    or      t2, t2, t3
    or      t2, t2, s4

  #==============================
  # Bỏ 2 lệnh này vì có sel SW[14] và SW [13] thay vào
    # sw      t1, 0(t4)
    # sw      t2, 0(t5)
#==============================

# Logic kiểm tra SW[14] và SW[13]
    # --- Kiểm tra en_hex (SW[14]) ---
    srli    t6, s8, 14        	# Lấy bit SW[14]
    andi    t6, t6, 1
    bne     t6, x0, write_hex	# Nếu en_hex == 1, bỏ qua
    li    t2, 0xFFFFFFFF          	# Nếu EN_HEX == 0, xóa word_hi (HEX4-7)
write_hex:
    # --- Kiểm tra en_dec (SW[13]) ---
    srli    t6, s8, 13        	# Lấy bit SW[13]
    andi    t6, t6, 1
    bne     t6, x0, write_dec	# Nếu en_dec == 1, bỏ qua
    li    t1, 0xFFFFFFFF         	# Nếu en_dec == 0, xóa word_lo (HEX0-3)
write_dec:
    # Ghi ra LED
    sw      t1, 0(t4)
    sw      t2, 0(t5)

    jal     x0, main_loop

# ===== Trạng thái disable: xoá LED rồi lặp lại =====
disabled:
    li      t1, 0xFFFFFFFF
    sw      t1, 0(t4)
    sw      t1, 0(t5)
    jal     x0, main_loop

map_hex_digit:
    addi    t0, x0, 0
    beq     a0, t0, md0
    addi    t0, x0, 1
    beq     a0, t0, md1
    addi    t0, x0, 2
    beq     a0, t0, md2
    addi    t0, x0, 3
    beq     a0, t0, md3
    addi    t0, x0, 4
    beq     a0, t0, md4
    addi    t0, x0, 5
    beq     a0, t0, md5
    addi    t0, x0, 6
    beq     a0, t0, md6
    addi    t0, x0, 7
    beq     a0, t0, md7
    addi    t0, x0, 8
    beq     a0, t0, md8
    addi    t0, x0, 9
    beq     a0, t0, md9
    addi    t0, x0, 10
    beq     a0, t0, mdA
    addi    t0, x0, 11
    beq     a0, t0, mdB
    addi    t0, x0, 12
    beq     a0, t0, mdC
    addi    t0, x0, 13
    beq     a0, t0, mdD
    addi    t0, x0, 14
    beq     a0, t0, mdE
    addi    t0, x0, 15
    beq     a0, t0, mdF

    addi    a0, x0, 0x00       
    jalr    x0, ra, 0

md0: 
    addi a0, x0, 0xC0
    jalr x0, ra, 0
md1: 
    addi a0, x0, 0xF9
    jalr x0, ra, 0
md2: 
    addi a0, x0, 0xA4
    jalr x0, ra, 0
md3: 
    addi a0, x0, 0xB0
    jalr x0, ra, 0
md4: 
    addi a0, x0, 0x99
    jalr x0, ra, 0
md5: 
    addi a0, x0, 0x92
    jalr x0, ra, 0
md6: 
    addi a0, x0, 0x82
    jalr x0, ra, 0
md7: 
    addi a0, x0, 0xF8
    jalr x0, ra, 0
md8: 
    addi a0, x0, 0x80
    jalr x0, ra, 0
md9: 
    addi a0, x0, 0x90
    jalr x0, ra, 0
mdA: 
    addi a0, x0, 0x88
    jalr x0, ra, 0
mdB: 
    addi a0, x0, 0x83
    jalr x0, ra, 0
mdC: 
    addi a0, x0, 0xC6
    jalr x0, ra, 0
mdD: 
    addi a0, x0, 0xA1
    jalr x0, ra, 0
mdE: 
    addi a0, x0, 0x86
    jalr x0, ra, 0
mdF: 
    addi a0, x0, 0x8E
    jalr x0, ra, 0

