using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace setcleaner
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                DateTime t = DateTime.Now;
                cleaner("D:/_romtest/mapsort-gs");

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


        static void cleaner(string path)
        {

            string[] bad = new string[] { "[b1]" };

            string[] dirs = Directory.GetDirectories(path);

            for (int i = 0; i < dirs.Length; i++)
            {
                cleaner(dirs[i]);
            }


            string[] fx = Directory.GetFiles(path);

            for (int i = 0; i < fx.Length; i++)
            {
                try
                {
                    if (fx[i].Contains("[b")) File.Delete(fx[i]);
                    if (fx[i].Contains("[o")) File.Delete(fx[i]);
                    if (fx[i].Contains("[a")) File.Delete(fx[i]);

                    if (fx[i].Contains("2]")) Console.WriteLine(fx[i]);
                }
                catch (Exception)
                {
                    Console.WriteLine("skipped: " + fx[i]);
                }
               
            }
        }
    }
}
