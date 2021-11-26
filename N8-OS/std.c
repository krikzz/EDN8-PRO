
#include "everdrive.h"

u8* str_get_ext_ptr(u8 *str);

u16 malloc_ptr;

void std_init() {
    malloc_ptr = MALLOC_BASE;
}

u8 *str_append(u8 *dst, u8 *src) {

    while (*dst != 0)dst++;
    while (*src != 0)*dst++ = *src++;
    *dst = 0;
    return dst;
}

u8 *str_append_num(u8 *dst, u32 num) {

    u16 i;
    u8 buff[11];
    u8 *str = (u8 *) & buff[10];

    *str = 0;
    if (num == 0)*--str = '0';
    for (i = 0; num != 0; i++) {
        *--str = num % 10 + '0';
        num /= 10;
    }

    return str_append(dst, str);

}

u8 *str_append_hex8(u8 *dst, u8 num) {

    u8 buff[3];
    buff[2] = 0;
    buff[0] = (num >> 4) + '0';
    buff[1] = (num & 15) + '0';

    if (buff[0] > '9')buff[0] += 7;
    if (buff[1] > '9')buff[1] += 7;

    return str_append(dst, buff);
}

u8 *str_append_hex16(u8 *dst, u16 num) {

    u8 *ptr = dst;
    ptr = str_append_hex8(ptr, num >> 8);
    return str_append_hex8(ptr, num & 0xff);
}

u8 *str_append_hex32(u8 *dst, u32 num) {

    u8 *ptr = dst;
    ptr = str_append_hex16(ptr, num >> 16);
    return str_append_hex16(ptr, num & 0xffff);
}

u8 *str_append_bin8(u8 *dst, u8 num) {

    u8 buff[9];
    u8 i;
    
    buff[8] = 0;
    for (i = 0; i < 8; i++) {
        buff[7-i] = (num & 1) + '0';
        num >>= 1;
    }

    return str_append(dst, buff);
}

u16 str_lenght(u8 *str) {

    u16 len = 0;
    while (*str++ != 0)len++;
    return len;
}

u8* str_get_ext_ptr(u8 *str) {

    u8 *ptr = 0;
    while (*str) {
        if (*str == '.')ptr = str;
        str++;
    }

    if (ptr == 0)return str;

    ptr++;
    return ptr;
}

u8 str_extension(u8 *target, u8 *str) {

    if (*target == '.')target++;
    str = str_get_ext_ptr(str);

    return str_cmp_ncase(target, str);
}

u8 str_extension_list(u8 **ext_list, u8 *name) {

    while (*ext_list != 0) {
        if (str_extension(*ext_list, name))return 1;
        ext_list++;
    }

    return 0;
}

u8 str_cmp_ncase(u8 *str1, u8 *str2) {

    u8 val1;
    u8 val2;
    u8 str_len = str_lenght(str1);
    if (str_len != str_lenght(str2))return 0;


    while (str_len--) {
        val1 = *str1++;
        val2 = *str2++;
        if (val1 >= 'A' && val1 <= 'Z')val1 |= 0x20;
        if (val2 >= 'A' && val2 <= 'Z')val2 |= 0x20;
        if (val1 != val2)return 0;
    }

    return 1;
}

u8 str_cmp_len(u8 *str1, u8 *str2, u8 len) {

    while (len--) {
        if (*str1 == 0 && *str2 == 0)return 1;
        if (*str1++ != *str2++)return 0;
    }

    return 1;
}

void str_copy(u8 *src, u8 *dst) {

    while (*src != 0)*dst++ = *src++;
    *dst = 0;
}

u8 *str_extract_fname(u8 *str) {

    u8 *name_ptr = str;
    while (*str != 0) {
        if (*str == '/')name_ptr = str + 1;
        str++;
    }

    return name_ptr;
}

u8 *str_extract_ext(u8 *str) {

    u8 *name_ptr = 0;
    while (*str != 0) {
        if (*str == '.')name_ptr = str + 1;
        str++;
    }
    if (name_ptr == 0)name_ptr = str;

    return name_ptr;
}


u8* str_append_date(u8 *dst, u16 date) {

    str_append_hex8(dst, decToBcd(date & 31));
    str_append(dst, ".");
    str_append_hex8(dst, decToBcd((date >> 5) & 15));
    str_append(dst, ".");
    return str_append_num(dst, (date >> 9) + 1980);
}

u8* str_append_time(u8 *dst, u16 time) {

    str_append_hex8(dst, decToBcd(time >> 11));
    str_append(dst, ":");
    str_append_hex8(dst, decToBcd((time >> 5) & 0x3F));
    str_append(dst, ":");
    return str_append_hex8(dst, decToBcd((time & 0x1F) * 2));
}

u16 str_last_index_of(u8 *str, u8 val) {

    u16 i;
    u16 idx = 0;
    for (i = 0; str[i] != 0; i++) {
        if (str[i] == val)idx = i;
    }

    return idx;
}

void mem_set(void *dst, u8 val, u16 len) {

    static u8 *ds;
    static u8 vl;
    static u16 ln;

    ds = dst;
    vl = val;
    ln = len;

    while (ln--)*ds++ = vl;
}

void mem_copy(void *src, void *dst, u16 len) {

    while (len--)*((u8 *) dst)++ = *((u8 *) src)++;
}

u8 mem_cmp(void *src, void *dst, u16 len) {

    while (len--) {
        if (*((u8 *) dst)++ != *((u8 *) src)++)return 0;
    }

    return 1;
}

u8 mem_tst(void *str, u8 val, u16 len) {

    while (len--) {
        if (*((u8 *) str)++ != val)return 0;
    }
    return 1;
}

void *malloc(u16 size) {

    void *ptr = (void *) malloc_ptr;
    malloc_ptr += size;

    if (malloc_ptr > MALLOC_BASE + MALLOC_SIZE) {
        printError(ERR_OUT_OF_MEMORY);
        for (;;);
    }

    return ptr;
}

void free(u16 size) {
    malloc_ptr -= size;
}

u16 crcFast(void *src, u16 len) {

    u8 *ptr8 = (u8 *) src;
    u8 crc1 = 0;
    u8 crc2 = 0;

    while (len--) {
        crc1 += *ptr8++;
        crc2 = (crc1 + crc2);
    }

    return (crc1 << 8) | crc2;
}

u32 max(u32 v1, u32 v2) {
    if (v1 > v2)return v1;
    return v2;
}

u32 min(u32 v1, u32 v2) {
    if (v1 < v2)return v1;
    return v2;
}

u32 inc_mod(u32 val, u32 mod) {

    val = val >= mod - 1 ? 0 : val + 1;

    return val;
}

u32 dec_mod(u32 val, u32 mod) {

    val = val == 0 ? mod - 1 : val - 1;

    return val;
}

u8 decToBcd(u8 val) {

    if (val > 99)val = 99;
    return (val / 10 << 4) | val % 10;
}

u8 bcdToDec(u8 val) {
    return (val >> 4) * 10 + (val & 15);
}

