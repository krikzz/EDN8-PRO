using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace flipbytes
{
    class Program
    {
        static void Main(string[] args)
        {

            try
            {

                if (args.Length < 1) throw new Exception("Input file is not specified");

                byte []data = File.ReadAllBytes(args[0]);
                byte[] buff = new byte[data.Length + 4];

                buff[3] = (byte)(data.Length >> 24);
                buff[2] = (byte)(data.Length >> 16);
                buff[1] = (byte)(data.Length >> 8);
                buff[0] = (byte)(data.Length);

                for (int i = 0; i < data.Length; i++)
                {
                    int tmp = data[i];
                    int swp = 0;
                    for (int u = 0; u < 8; u++)
                    {
                        swp >>= 1;
                        swp |= tmp & 0x80;
                        tmp <<= 1;
                    }
                    buff[i + 4] = (byte)swp;
                }

                

                if(args.Length > 1)
                {
                    File.WriteAllBytes(args[1], buff);
                }
                else
                {
                    File.WriteAllBytes(args[0] + ".flp", buff);
                }



            }
            catch(Exception x)
            {
                Console.WriteLine("ERROR: "+x.Message );
            }
        }
    }
}
