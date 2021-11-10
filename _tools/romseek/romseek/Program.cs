using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Threading;
using System.Data;

namespace romseek
{

    class RomInfo
    {
        public int mapper;
        public UInt32 crc32;
        public string filename;
        public byte[] buff;
    }

    class Program
    {
        static void Main(string[] args)
        {

            try
            {
                DateTime t = DateTime.Now;
                seek("D:/_romtest", 0xffff, 0x29356FB0);
                //seek("D:\\_romtest\\nes-20\\nes-20.idx", 0xffff, 0x6C039D11);

                t = new DateTime(DateTime.Now.Ticks - t.Ticks);
                Console.WriteLine("time: " + t.Second);

            }
            catch (Exception x)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("");
                Console.WriteLine("ERROR: " + x.Message);
                Console.ResetColor();
            }
        }




        static void seek(string path, int mapper, UInt32 crc32)
        {

            string[] dirs = Directory.GetDirectories(path);

            for(int i = 0;i < dirs.Length; i++)
            {
                seek(dirs[i], mapper, crc32);
            }

            string[] files = Directory.GetFiles(path);

            for (int i = 0; i < files.Length; i++)
            {

                byte[] buff = File.ReadAllBytes(files[i]);

                RomInfo inf = new RomInfo();
                inf.crc32 = crc32;
                inf.mapper = mapper;
                inf.filename = files[i];
                inf.buff = buff;

                //romCheck(inf);
                new Thread(romCheck).Start(inf);

            }

        }

        static void romCheck(Object args)
        {

            RomInfo inf = (RomInfo)args;

            if (inf.buff.Length < 128) return;

            int map = inf.buff[7] | inf.buff[6] >> 4;

            if (map == inf.mapper)
            {
                Console.WriteLine(inf.filename);
            }

            if (inf.crc32 != 0 )
            {
                UInt32 crc = CRC32.calc(0, inf.buff, 16, inf.buff.Length - 16);
                if (crc == inf.crc32)
                {
                    Console.WriteLine(inf.filename);
                }
            }
        }

      
    }
}
