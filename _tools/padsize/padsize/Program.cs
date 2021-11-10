using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace padsize
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;

            try
            {
                for(int i = 0;i < args.Length; i++)
                {
                    if (args[i].Equals("-pad")) cmd_pad(args[i + 1], args[i + 2]);
                }
                
            }
            catch (Exception x)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("");
                Console.WriteLine("ERROR: " + x.Message);
                Console.ResetColor();
            }
        }

        static void cmd_pad(string size_str, string path)
        {
            int size = 0;

            if (size_str.ToLower().Contains("0x"))
            {
                size = Convert.ToInt32(size_str, 16);
            }
            else
            {
                size = Convert.ToInt32(size_str);
            }

            byte[] data = File.ReadAllBytes(path);
            if (size < data.Length) return;

            byte[] buff = new byte[size];
            for (int i = 0; i < buff.Length; i++) buff[i] = 0xff;

            Array.Copy(data, 0, buff, 0, data.Length);

            File.WriteAllBytes(path, buff);

        }
    }
}
