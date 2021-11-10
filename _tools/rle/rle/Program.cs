using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace rle
{
    class Program
    {
        static void Main(string[] args)
        {

            //compress("E:/projects/EDN8-PRO/mappers/255/output_files/top.rbf");
            compress("E:/projects/EDN8-PRO/mappers/XXX/output_files/top.rbf");

        }

        static void compress(string path)
        {

            byte[] data = File.ReadAllBytes(path);
            Console.WriteLine("data size: " + data.Length);

            int bsize = 0;
            int dst_ptr = 0;

            for (int i = 0; i < data.Length; i += bsize & 127)
            {

                bsize = 0;
                while (bsize < 127 && i + bsize < data.Length && data[i] == data[i + bsize]) bsize++;

                if(bsize == 1)
                {
                    bsize = 0;
                    while (bsize < 127 && i + bsize + 1 < data.Length && data[i + bsize] != data[i + bsize + 1]) bsize++;
                    //Console.WriteLine("off: " + i);
                    //Console.WriteLine("siz: " + bsize);
                    //Console.ReadLine();
                    dst_ptr += 1 + bsize;
                }
                else
                {
                    dst_ptr += 2;
                }

                
            }


            Console.WriteLine("rle size: " + dst_ptr);
        }


      

       
    }
}
