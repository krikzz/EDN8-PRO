using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace mapscan
{
    class Program
    {

        static byte[] maprout;
        static StreamWriter t;

        static void Main(string[] args)
        {

            try
            {

                Directory.CreateDirectory("d:/mapsort");
                t = File.CreateText("d:/maplog.txt");
                Console.WriteLine("scan...");
                maprout = File.ReadAllBytes("E:/projects/EDN8-PRO/mappers/MAPROUT.BIN");
                //scan("D:/_romtest/mapout");
                //scan("D:/ROM/_my-game-set/nes/NES-No-Intro-2016");
                //scan("D:/_romtest/nes-set-xxx");
                scan("D:/_romtest/mapsort-gs");
                

                t.WriteLine("Supported: ");
                for (int i = 0; i < 256; i++)
                {
                    if (map_ctr[i] == 0 || maprout[i] == 255) continue;
                    t.Write("map[" + i + "] ");
                    t.Write(map_ctr[i]);
                    t.WriteLine();
                }
                t.WriteLine("");
                t.WriteLine("Not Supported: ");
                for (int i = 0; i < 256; i++)
                {
                    if (map_ctr[i] == 0 || maprout[i] != 255) continue;
                    t.Write("map[" + i + "] ");
                    t.Write(map_ctr[i]);
                    t.WriteLine();
                }
                t.WriteLine("");

                t.WriteLine("Total    : " + game_ctr);
                t.WriteLine("Supported: " + sup_ctr);
                t.WriteLine("Not Supp : " + (game_ctr - sup_ctr));

                Console.WriteLine("Total    : " + game_ctr);
                Console.WriteLine("Supported: " + sup_ctr);
                Console.WriteLine("Not Supp : " + (game_ctr - sup_ctr));

                t.Close();
            }
            catch (Exception x)
            {
                Console.WriteLine("error: " + x.Message);
            }

        }

        static int[] map_ctr = new int[256];
        static int game_ctr;
        static int sup_ctr;
        static void scan(string path)
        {
            string[] dirs = Directory.GetDirectories(path);

            for (int i = 0; i < dirs.Length; i++)
            {
                scan(dirs[i]);
            }

            string[] files = Directory.GetFiles(path);
            byte[] buff = new byte[16];

            for (int i = 0; i < files.Length; i++)
            {
                if (!files[i].ToLower().EndsWith(".nes")) continue;

                FileStream f = File.OpenRead(files[i]);
                if (f.Length < 16)
                {
                    f.Close();
                    continue;
                }

                f.Read(buff, 0, buff.Length);
                f.Close();

                if (buff[0] != 'N' || buff[1] != 'E' || buff[2] != 'S') continue;


                int mapper = ((buff[6] >> 4) | (buff[7] & 0xf0));

                map_ctr[mapper]++;

               

                game_ctr++;
                if (maprout[mapper] != 0xff) sup_ctr++;


                if ((buff[7] & 0x0C) == 8)
                {
                    mapper += (buff[8] & 0x0f) << 8;
                    Console.WriteLine("INES 2.0: " + files[i] + ", mapper: " + mapper);
                }

                /*
                string pathx = "d:/mapsort/" + mapper;
                Directory.CreateDirectory(pathx);
                string file_name = pathx + "/" + Path.GetFileName(files[i]);
                if (File.Exists(file_name))
                {

                    file_name = file_name.Substring(0, file_name.Length - 4);
                    file_name += "x.nes";
                    Console.WriteLine("file copy: " + file_name);
                }
                File.Copy(files[i], file_name);*/

            }
        }
    }
}
