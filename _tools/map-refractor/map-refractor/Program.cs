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
                loadDir("C:\\Users\\igor\\Desktop\\mappers");
            }
            catch(Exception x)
            {
                Console.WriteLine("ERROR: "+x.Message); 
            }
        }


        static void loadDir(string path)
        {

            //Console.WriteLine("scan dir: " + path);

            string[] dirs = Directory.GetDirectories(path);

            for(int i = 0;i < dirs.Length; i++)
            {
                loadDir(dirs[i]);
            }

            string[] files = Directory.GetFiles(path, "*.v");

            for (int i = 0; i < files.Length; i++)
            {
                loadFile(files[i]);
            }

        }

        static void loadFile(string path)
        {
            /*
             string[] targets =
             {
                 "reg_idx", "ss_addr",
                 "ss_active", "ss_act",
                 "map_regs_we", "ss_we",
                 "ss_din", "ss_rdat",
                 "map_cfg[7]", "cfg_chr_ram",
                 "map_cfg[0]", "cfg_mir_v"
             };*/
            /*
            string[] targets =
            {
                "[22", "[22",
                "[21", "[21"
            };*/

            /*
            string[] targets =
            {
                "assign mask_off = 0;", "",
                "assign mask_off = 1;", "",
            };*/

            string[] targets =
            {
                "chr_xram", "chr_xram",
            };

            if (!path.EndsWith(".v")) return;

            string code = File.ReadAllText(path);

            for(int i = 0; i < targets.Length; i += 2)
            {
                if (!code.Contains(targets[i]))continue;

               // code = code.Replace(targets[i], targets[i + 1]);
                Console.WriteLine("refract: " + path + ": "+ targets[i]);
            }

            //File.WriteAllText(path, code);

            //Console.WriteLine("scan file: " + path);
        }

    }
}
