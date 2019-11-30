using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace edlink_n8
{
    class Usbio
    {

        Edio edio;
        const char cmd_test = 't';
        const char cmd_reboot = 'r';
        const char cmd_halt = 'h';
        const char cmd_sel_game = 'n';
        const char cmd_run_game = 's';
        

        public Usbio(Edio edio)
        {
            this.edio = edio;
        }


        public void loadGame(NesRom rom, string map_path)
        {

            int resp;
   
            byte[] id_bin = rom.getRomID();
            byte[] prg = rom.PrgData;
            byte[] chr = rom.ChrData;

            cmd(cmd_sel_game);
            txString("USB:" + Path.GetFileName(rom.Name));
            resp = edio.rx8();//system ready to receive id
            edio.fifoWR(id_bin, 0, id_bin.Length);
            resp = edio.rx8();
            if (resp != 0)
            {
                throw new Exception("Game select error 0x: " + resp.ToString("X2"));
            }
            byte map_idx = edio.rx8();
            if (map_idx != rom.Mapper)
            {
                Console.WriteLine("map reloc: " + map_idx);
            }
            if (map_path == null)
            {
                map_path = getTestMapper(map_idx);
            }

            cmd(cmd_run_game);
            edio.rx8();//exec

            edio.memWR(rom.PrgAddr, prg, 0, prg.Length);
            edio.memWR(rom.ChrAddr, chr, 0, chr.Length);

            if (map_path == null)
            {
                mapLoadSDC(rom.Mapper, null);
            }
            else
            {
                Console.WriteLine("ext mapper: " + map_path);
                edio.fpgInit(File.ReadAllBytes(map_path), null);
            }
            
        }

        public void loadOS(NesRom rom, string map_path)
        {
            if (map_path == null)
            {
                map_path = getTestMapper(255);
            }

            byte[] prg = rom.PrgData;
            byte[] chr = rom.ChrData;
            MapConfig cfg = new MapConfig();
            cfg.map_idx = 0xff;
            cfg.Ctrl = MapConfig.ctrl_unlock;
            
            cmd(cmd_reboot);
            edio.rx8();//exec
   
            edio.memWR(rom.PrgAddr, prg, 0, prg.Length);
            edio.memWR(rom.ChrAddr, chr, 0, chr.Length);

            edio.getStatus();

            if (map_path == null)
            {
                mapLoadSDC(255, cfg);
            }
            else
            {
                byte[] map = File.ReadAllBytes(map_path);
                edio.fpgInit(map, cfg);
            }

        }

        void copyFolder(string src, string dst)
        {
            if (!src.EndsWith("/")) src += "/";
            if (!dst.EndsWith("/")) dst += "/";

            string[] dirs = Directory.GetDirectories(src);

            for (int i = 0;i < dirs.Length; i++)
            {
                copyFolder(dirs[i], dst + Path.GetFileName(dirs[i]));
            }


            string[] files = Directory.GetFiles(src);


            for (int i = 0; i < files.Length; i++)
            {
                copyFile(files[i], dst + Path.GetFileName(files[i]));
            }
        }

        public void copyFile(string src, string dst)
        {
            byte[] src_data;
            src = src.Trim();
            dst = dst.Trim();

            if (File.GetAttributes(src).HasFlag(FileAttributes.Directory))
            {
                copyFolder(src, dst);
                return;
            }

            if (dst.EndsWith("/") || dst.EndsWith("\\"))
            {
                dst += Path.GetFileName(src);
            }

            Console.WriteLine("copy file: " + src + " to " + dst);

            if (src.ToLower().StartsWith("sd:"))
            {
                src = src.Substring(3);
                src_data = new byte[edio.fileInfo(src).size];

                edio.fileOpen(src, Edio.FAT_READ);
                edio.fileRead(src_data, 0, src_data.Length);
                edio.fileClose();
            }
            else
            {
                src_data = File.ReadAllBytes(src);
            }


            if (dst.ToLower().StartsWith("sd:"))
            {
                dst = dst.Substring(3);
                edio.fileOpen(dst, Edio.FAT_OPEN_ALWAYS | Edio.FAT_WRITE);
                edio.fileWrite(src_data, 0, src_data.Length);
                edio.fileClose();
            }
            else
            {
                File.WriteAllBytes(dst, src_data);
            }
        }

        public void makeDir(string path)
        {
            path = path.Trim();

            if (path.ToLower().StartsWith("sd:") == false)
            {
                throw new Exception("incorrect dir path: " + path);
            }
            Console.WriteLine("make dir: " + path);
            path = path.Substring(3);
            edio.dirMake(path);
        }

        void cmd(char cmd)
        {
            byte[] buff = new byte[2];
            buff[0] = (byte)'*';
            buff[1] = (byte)cmd;
            edio.fifoWR(buff, 0, buff.Length);
        }

        void txString(string str)
        {
            byte[] bytes = Encoding.ASCII.GetBytes(str);
            UInt16 str_len = (UInt16)bytes.Length;
            edio.fifoWR(BitConverter.GetBytes(str_len), 0, 2);
            edio.fifoWR(bytes, 0, bytes.Length);
        }

        void halt()
        {
            MapConfig cfg = new MapConfig();
            cfg.map_idx = 0xff;
            edio.setConfig(cfg);
            cmd('h');
            if (edio.rx8() != 0) throw new Exception("Unexpected response at USB halt");
        }

        void haltExit()
        {
            MapConfig cfg = new MapConfig();
            cfg.map_idx = 0xff;
            cfg.Ctrl = MapConfig.ctrl_unlock;
            edio.setConfig(cfg);
        }

        void mapLoadSDC(int map_id, MapConfig cfg)
        {
            string map_path = "EDN8/MAPS/";
            int map_pkg;
            byte[] map_rout = new byte[256];


            edio.fileOpen("EDN8/MAPROUT.BIN", Edio.FAT_READ);
            edio.fileRead(map_rout, 0, map_rout.Length);
            edio.fileClose();

            map_pkg = map_rout[map_id];
            if (map_pkg == 0xff && map_id != 0xff) throw new Exception("Unsupported mapper: " + map_id);

            if (map_pkg < 100) map_path += "0";
            if (map_pkg < 10) map_path += "0";
            map_path += map_pkg + ".RBF";

            Console.WriteLine("int mapper: " + map_path);
            edio.fpgInit(map_path, cfg);
        }

        static string getTestMapper(byte mapper)
        {
            string home = "E:/projects/EDN8-PRO/mappers/";

            try
            {
                home = File.ReadAllText("testpath.txt");
            }
            catch (Exception) { };

            try
            {
                string map_path = home;

                byte[] maprout = File.ReadAllBytes(home + "MAPROUT.BIN");

                int pack = maprout[mapper];
                if (pack == 255 && mapper != 255) throw new Exception("Mapper is not supported");

                if (pack < 100) map_path += "0";
                if (pack < 10) map_path += "0";
                map_path += pack + "/output_files/top.rbf";

                return map_path;

            }
            catch (Exception)
            {
                return null;
            }
        }


    }
}
