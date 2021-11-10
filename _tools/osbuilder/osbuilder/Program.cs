using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace osbuilder
{
    class Program
    {
        static void Main(string[] args)
        {

            Console.OutputEncoding = System.Text.Encoding.UTF8;
            try
            {
                builder(args);
            }
            catch(Exception x)
            {
                
                Console.WriteLine("ERROR: " + x.Message);
            }


        }


        static void builder(string[] args)
        {

            byte[] os_data = new byte[0x20000 + 16384];
            byte[] ines = new byte[16];
            string os_path = null;
            int addr = 0;
            string cmd;
            string arg;

            for(int i = 0;i < args.Length; i++)
            {

                if (!args[i].Contains("=")) continue;
                int sep = args[i].IndexOf('=');
                cmd = args[i].Substring(0, sep);
                arg = args[i].Substring(sep+1);

                //Console.WriteLine("cmd: " + cmd);
                //Console.WriteLine("arg: " + arg);

                if (cmd.EndsWith("-os"))
                {
                    os_path = arg;
                    byte[]buff = File.ReadAllBytes(os_path);
                    int os_size = buff.Length - 16;
                    Array.Copy(buff, 0, ines, 0, 16);
                    Array.Copy(buff, 16, os_data, 0x20000- os_size+16384, os_size);
                }

                if (cmd.EndsWith("-addr"))
                {
                    addr = Convert.ToInt32(arg, 16);
                }

                if (cmd.EndsWith("-inc"))
                {
                    byte[] buff = File.ReadAllBytes(arg);
                    Array.Copy(buff, 0, os_data, addr, buff.Length);
                    addr += buff.Length;
                }
            }

            if(os_path != null)
            {
                byte[] buff = new byte[ines.Length + os_data.Length];
                Array.Copy(ines, 0, buff, 0, ines.Length);
                Array.Copy(os_data, 0, buff, ines.Length, os_data.Length);
                File.WriteAllBytes(os_path, buff);
            }

        }

        static void extractArg(string cmd)
        {

        }
    }
}
