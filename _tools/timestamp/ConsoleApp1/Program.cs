using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace timestamp
{
    class Program
    {
        static void Main(string[] args)
        {

            try
            {
                timestamp(args);

            }
            catch (Exception x) {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("");
                Console.WriteLine("ERROR: " + x.Message);
                Console.ResetColor();
            }

        }

        static void timestamp(string []args)
        {
            string file = null;
            int addr = 0;

            for (int i = 1; i < args.Length; i++)
            {
                if (args[i - 1].ToLower().EndsWith("-f")) file = args[i];
                if (args[i - 1].ToLower().EndsWith("-a")) addr = Convert.ToInt32(args[i], 16);
            }

            byte []data = File.ReadAllBytes(file);

            if(addr + 4 > data.Length) throw new Exception("Out of file");
            if (file == null) throw new Exception("Input file is not specified");

            Console.WriteLine("Set time stamp at: 0x{0:X}", addr);

            DateTime d = DateTime.Now;


            UInt16 date;
            UInt16 time;

            date = (UInt16)(d.Day | (d.Month << 5) | (d.Year - 1980 << 9));
            time = (UInt16)((d.Second / 2 | (d.Hour << 11) | (d.Minute << 5)));

            data[addr + 0] = (byte)(date & 0xff);
            data[addr + 1] = (byte)(date >> 8);
            data[addr + 2] = (byte)(time & 0xff);
            data[addr + 3] = (byte)(time >> 8);

            File.WriteAllBytes(file, data);
        }
    }
}
