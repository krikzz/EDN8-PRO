using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace crc_check
{
    class Program
    {

        static UInt32[] crc_table = new UInt32[0x10000];
        static string[] name_table = new string[0x10000];
        static int crc_ctr = 0;
        static void Main(string[] args)
        {

            try
            {
                Console.WriteLine("scan...");
                scan("D:/_romtest/mapout");
                //scan("D:/ROM/_my-game-set/nes/NES-No-Intro-2016");
                Console.WriteLine("records: " + crc_ctr);
                check();

            }
            catch(Exception x)
            {
                Console.WriteLine("error: "+x.Message); 
            }

        }

        static void check()
        {

            int ctr = 0;
            for (int i = 0; i < crc_ctr - 1; i++)
            {
                for (int u = i + 1; u < crc_ctr; u++)
                {
                    if (crc_table[i] == crc_table[u])
                    {
                        if (ctr++ % 2 == 0)
                        {
                            Console.ForegroundColor = ConsoleColor.Gray;
                        }
                        else
                        {
                            Console.ForegroundColor = ConsoleColor.Green;
                        }
                        Console.Write(" " + name_table[i]);
                        Console.CursorLeft = 40;
                        Console.WriteLine("  " + name_table[u]);
                    }
                }


            }


            Console.WriteLine("total matches: " + ctr);


            Console.WriteLine("");


        }

        static void scan(string path)
        {
            string[] dirs = Directory.GetDirectories(path);

            for (int i = 0; i < dirs.Length; i++)
            {
                scan(dirs[i]);
            }


            string[] files = Directory.GetFiles(path);
            byte[] buff = new byte[0x20000];

            for (int i = 0; i < files.Length; i++)
            {
                if (!files[i].ToLower().EndsWith(".nes")) continue;
                FileStream f =  File.OpenRead(files[i]);


                int len = (int)Math.Min(f.Length - 16, buff.Length);

                f.Position = 16;
                f.Read(buff, 0, len);
                f.Close();

                name_table[crc_ctr] = Path.GetFileName(files[i]);
                crc_table[crc_ctr++] = CRC32.calc(0, buff, 0, len);
            }
        }
    }
}
