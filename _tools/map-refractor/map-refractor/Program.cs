using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace map_refractor
{
    class Program
    {
        static void Main(string[] args)
        {


            try
            {

                //loadDir("D:/old-mappers/new");
                //loadDir("E:/projects/EDN8-PRO/mappers");
                //loadDir("E:/projects/everdrive-FC/mappers");
                //loadDir("E:\\projects\\EDN8-PRO\\mappers");
                //loadDir("C:\\Users\\igor\\Desktop\\nes");
                loadDir("E:\\projects\\MEGA-ED-PRO\\edapp\\nes\\mapper\\nes_core\\mappers");
            }
            catch (Exception x)
            {
                Console.WriteLine("ERROR: " + x.Message);
            }
        }


        static void loadDir(string path)
        {

            //Console.WriteLine("scan dir: " + path);

            string[] dirs = Directory.GetDirectories(path);

            for (int i = 0; i < dirs.Length; i++)
            {
                loadDir(dirs[i]);
            }

            string[] files = Directory.GetFiles(path, "*.sv");

            for (int i = 0; i < files.Length; i++)
            {
                loadFile(files[i]);
            }

        

        }


        static void loadFile(string path)
        {

            string[] targets =
            {
                "SSTBus ", "SSTBus_nes ",
                "MapIn ", "MapIn_nes ",
                "MapOut ", "MapOut_nes ",
                "SysCfg ", "CartCfg ",
                "CpuBus ", "CpuBus_nes ",
                "MemCtrl ", "MemCtrl_nes ",
            };
            /*
            string[] targets =
            {
                              
                "negedge m2", "negedge cpu.m2",
                "ss_act", "sst.act",
                "assign ss_rdat", "assign mao.sst_di",
                "ss_we", "sst.we_reg",
                "ss_addr", "sst.addr",
                "cpu_addr", "cpu.addr",
                "ppu_addr", "ppu.addr",
                "(map_rst)", "(mai.map_rst)",
                "cfg_map_idx", "cfg.map_idx",
                "cpu_rw", "cpu.rw",
                "cfg_chr_ram", "cfg.chr_ram",
                //"map_sub", "cfg.map_sub",
                //"map_idx", "cfg.map_idx",
                "!cpu_ce", "cpu.addr[15]",
            };*/


            if (!path.EndsWith(".sv") && !path.EndsWith(".v")) return;

            string code = File.ReadAllText(path);

            for (int i = 0; i < targets.Length; i += 2)
            {
                if (!code.Contains(targets[i])) continue;

                code = code.Replace(targets[i], targets[i + 1]);
                Console.WriteLine("refract: " + path + ": " + targets[i]);
            }

            File.WriteAllText(path, code);

            //Console.WriteLine("scan file: " + path);
        }

    }
}
