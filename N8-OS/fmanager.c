

#include "main.h"

typedef struct {
    u16 selector;
    u16 sel_stack_ptr;
    u16 sel_stack[MAX_SEL_STACK];
    u8 path[MAX_PATH_SIZE + 1];
    u16 dir_size;
    u8 load_dir;
    u8 skip_init;
    u8 is_file;
} FmState;

typedef struct {
    u8 rec_name[MAX_STR_LEN * 2 + 1];
    u8 is_dir;
} FmRecord;

typedef struct {
    FmRecord recs[MAX_ROWS];
    u16 cur_page;
    u16 items;
} FmPage;

typedef struct {
    u16 load;
    u16 draw;
    u16 repaint;
} FmTime;


u8 app_fmanager();
FmState *fm;
FmPage *fm_page;

u8 fmanager(u8 *path) {

    u8 resp;
    u8 bank = REG_APP_BANK;

    REG_APP_BANK = APP_FMG;
    resp = app_fmanager(path);
    REG_APP_BANK = bank;
    return resp;
}

void fmInitMemory() {

    fm = malloc(sizeof (FmState));
    fm_page = malloc(sizeof (FmPage));
}

void fmForceUpdate() {
    fm->load_dir = 1; 
}


#pragma codeseg ("BNK08")



u8 fmRepaint();
u8 fmGetPath(u8 *buff);
u8 fmOpen();
u8 fmDirClose();
u8 fmPathAppend(u8 *str);
void fmPathRemove();
u8 fmLoadPage();
void fmPrintHeader();
void fmPrintFutter();
u8 fmLoadDir();

FmTime t;
 
u8 app_fmanager() {

    u8 resp;
    u8 joy;


    if (!fm->skip_init) {

        mem_set(fm, 0, sizeof (FmState));
        fm->skip_init = 1;
    }

    fm->load_dir = 1;


    while (1) {

        if (fm->is_file) {
            fmPathRemove();
            fm->is_file = 0;
        }

        if (fm->load_dir) {
            resp = fmLoadDir();
            if (resp)return resp;
            fm->load_dir = 0;
        }


        resp = fmRepaint();
        if (resp)return resp; 

        joy = sysJoyWait();


        if (joy == JOY_D) {
            if (fm->dir_size == 0)continue;
            fm->selector++;

            if (fm->selector % MAX_ROWS == 0) {
                fm->selector -= MAX_ROWS;
            }

            if (fm->selector >= fm->dir_size) {
                fm->selector = fm->selector / MAX_ROWS * MAX_ROWS;
            }
        }

        if (joy == JOY_U) {
            if (fm->dir_size == 0)continue;
            if (fm->selector % MAX_ROWS == 0) {
                fm->selector += MAX_ROWS - 1;
                if (fm->selector >= fm->dir_size) {
                    fm->selector = fm->dir_size - 1;
                }
            } else {
                fm->selector--;
            }
        }

        if (joy == JOY_R) {
            if (fm->dir_size == 0)continue;
            fm->selector += MAX_ROWS;
            if (fm->selector >= fm->dir_size) {
                fm->selector = fm->dir_size - 1;
            }
        }

        if (joy == JOY_L) {
            if (fm->dir_size == 0)continue;
            if (fm->selector < MAX_ROWS) {
                fm->selector = 0;
                continue;
            }
            fm->selector -= MAX_ROWS;
        }

        if (joy == JOY_A) {
            if (fm->dir_size == 0)continue;
            resp = fmGetPath(0);
            if (resp)return resp;
            resp = fmOpen();
            if (resp)return resp;
            continue;
        }

        if (joy == JOY_B) {
            resp = fmDirClose();
            if (resp)return resp;
            continue;
        }

        if (joy == JOY_STA) {

            return edStartGame(0);

        }

        if (joy == JOY_SEL) {
            u8 sort = registry->options.sort_files;
            resp = mainMenu();
            if (resp)return resp;
            if (sort != registry->options.sort_files)fm->load_dir = 1;
        }
    }

    return 0;
}

u8 fmLoadPage() {

    u8 i;
    u8 resp;
    u16 items = MAX_ROWS;
    u16 page = fm->selector / MAX_ROWS * MAX_ROWS;
    FileInfo inf;


    if (page == fm_page->cur_page)return 0;


    if (page + items > fm->dir_size) {
        items = fm->dir_size - page;
    }

    bi_cmd_dir_get_recs(page, items, MAX_STR_LEN * 2);

    for (i = 0; i < items; i++) {

        inf.file_name = fm_page->recs[i].rec_name;
        resp = bi_rx_next_rec(&inf);
        if (resp)return resp;

        fm_page->recs[i].is_dir = inf.is_dir; // & AT_DIR;

    }


    fm_page->cur_page = page;
    fm_page->items = items;
    return 0;
}

void fmPrintHeader() {

    u16 tot_page = 1;

    gSetPal(PAL_G2);

    gFillRect(' ', 0, G_BORDER_Y, G_SCREEN_W, 1);
    gSetXY(G_BORDER_X, G_BORDER_Y);

    tot_page = fm->dir_size / MAX_ROWS;
    if (fm->dir_size % MAX_ROWS != 0)tot_page++;
    if (tot_page == 0)tot_page = 1;
    gAppendString("page: ");
    gAppendNum(fm_page->cur_page / MAX_ROWS + 1);
    gAppendString(" of ");
    gAppendNum(tot_page);

}

void fmPrintFutter() {

    u8 *name = fm_page->recs[fm->selector % MAX_ROWS].rec_name;
    //u8 y = G_SCREEN_H - G_BORDER_Y - INF_ROWS;


    gSetPal(PAL_G2);
    gDrawFooter(name, INF_ROWS, G_LEFT);
    /*
  gFillRect(' ', 0, y, G_SCREEN_W, INF_ROWS);
  gSetXY(G_BORDER_X, y);
  gAppendString_ML(name, MAX_STR_LEN);
  if (str_lenght(name) <= MAX_STR_LEN)return;
  gConsPrint("");
  gAppendString_ML(&name[MAX_STR_LEN], MAX_STR_LEN);*/
}

u8 fmRepaint() {

    u8 i;
    u8 resp;

    t.load = bi_get_ticks();
    resp = fmLoadPage();
    if (resp)return resp;
    t.load = bi_get_ticks() - t.load;

    t.draw = bi_get_ticks();
    gCleanScreen();

    gSetXY(G_BORDER_X, G_BORDER_Y + 2);
    //gSetX(G_BORDER_X);
    for (i = 0; i < fm_page->items; i++) {


        if (fm_page->cur_page + i == fm->selector) {
            gSetPal(PAL_G2);
        } else if (fm_page->recs[i].is_dir) {
            gSetPal(PAL_B3);
        } else {
            gSetPal(PAL_B1);
        }


        gAppendString_ML(fm_page->recs[i].rec_name, MAX_STR_LEN);
        gConsPrint("");

    }

    fmPrintFutter();
    fmPrintHeader();
    t.draw = bi_get_ticks() - t.draw;

    /*
    gAppendString("    time:");
    gAppendNum(t.load);*/

    t.repaint = bi_get_ticks();
    gRepaint();
    t.repaint = bi_get_ticks() - t.repaint;

    return 0;
}

u8 fmGetPath(u8 *buff) {

    u8 resp;
    FileInfo inf;
    //u8 *name;

    if (buff == 0) {
        buff = malloc(MAX_NAME_SIZE + 2);
        resp = fmGetPath(buff);
        free(MAX_NAME_SIZE + 2);
        return resp;
    }


    inf.file_name = buff;

    bi_cmd_dir_get_recs(fm->selector, 1, MAX_NAME_SIZE + 1);
    resp = bi_rx_next_rec(&inf);
    if (resp)return resp;

    if (str_lenght(inf.file_name) > MAX_NAME_SIZE)return ERR_NAME_SIZE;

    resp = fmPathAppend(inf.file_name);
    if (resp)return resp;

    if (inf.is_dir) {
        fm->is_file = 0;
    } else {
        fm->is_file = 1;
    }

    return 0;
}

u8 fmOpen() {

    u8 resp;
    //open file
    if (fm->is_file) {
        resp = fileMenu(fm->path);
        if (resp)return resp;
        return 0;
    }

    //open dir
    fm->sel_stack[fm->sel_stack_ptr++] = fm->selector;
    fm->selector = 0;
    fm->load_dir = 1;
    return 0; //bi_cmd_dir_load(fm->path, registery->options.sort_files);
}

u8 fmDirClose() {

    if (fm->sel_stack_ptr == 0)return 0;

    fmPathRemove();
    fm->selector = fm->sel_stack[--fm->sel_stack_ptr];
    fm->load_dir = 1;
    return 0; //bi_cmd_dir_load(fm->path, registery->options.sort_files);
}

u8 fmPathAppend(u8 *str) {

    u16 len;

    len = str_lenght(str);
    len += str_lenght(fm->path);
    if (len > MAX_PATH_SIZE)return ERR_PATH_SIZE;

    str_append(fm->path, "/");
    str_append(fm->path, str);

    return 0;
}

void fmPathRemove() {

    static u16 lat_slash = 0;
    static u16 i;

    for (i = 0; fm->path[i] != 0; i++) {
        if (fm->path[i] == '/')lat_slash = i;
    }

    fm->path[lat_slash] = 0;

}

u8 fmLoadDir() {

    u8 resp;

    fm_page->cur_page = 0xffff; //force page update
    resp = bi_cmd_dir_load(fm->path, registry->options.sort_files);
    if (resp)return resp;

    bi_cmd_dir_get_size(&fm->dir_size);
    fm->selector = min(fm->selector, fm->dir_size - 1);
    if (fm->dir_size == 0)fm->selector = 0;

    return 0;
}