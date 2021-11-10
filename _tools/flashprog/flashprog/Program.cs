using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace flashprog
{
    class Program
    {

        static Edio edio;
        static void Main(string[] args)
        {

            Console.OutputEncoding = System.Text.Encoding.UTF8;

            try
            {
                prog(args);
                Console.WriteLine("ok");
            }
            catch (Exception x)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("");
                Console.WriteLine("ERROR: " + x.Message);
                Console.ResetColor();
            }

        }

        static void connect()
        {
            if (edio != null) return;
            edio = new Edio();
            Console.WriteLine("EverDrive found at " + edio.PortName);
            Console.WriteLine("EDIO status: " + edio.getStatus().ToString("X4"));
        }

        static void prog(string[] args)
        {

            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].Equals("-prog"))
                {
                    connect();
                    cmd_prog(args[i + 1], args[i + 2]);
                }

                if (args[i].Equals("-ufile"))
                {
                    cmd_updFIle(args[i + 1], args[i + 2]);
                }
            }
             
        }


        static void cmd_updFIle(string src, string dst)
        {
            byte[] data = getData(src);
            File.WriteAllBytes(dst, data);
        }
        static void cmd_prog(string addr_str, string path)
        {
            int addr = 0;

            if (addr_str.ToLower().Contains("0x"))
            {
                addr = Convert.ToInt32(addr_str, 16);
            }
            else
            {
                addr = Convert.ToInt32(addr_str);
            }

            byte []data = getData(path);

            Console.WriteLine("Prog BINdata to 0x{0:X6}", addr);
            edio.flaWR(addr, data, 0, data.Length);

            Console.WriteLine("Verify BIN...");
            byte[] buff_vf = new byte[data.Length];
            edio.flaRD(addr, buff_vf, 0, buff_vf.Length);

            for (int i = 0; i < buff_vf.Length; i++)
            {
                if (data[i] != buff_vf[i])
                {
                    throw new Exception("Verification error at " + i);
                }
            }
        }

        static byte[] getData(string path)
        {
            bool crypt = path.ToLower().EndsWith(".bin");
            byte[] data = File.ReadAllBytes(path);
            if (path.ToLower().EndsWith(".rbf")) swapBits(data);

            UInt32 crc = crc32(data);

            if (crypt)
            {
                data = Crypto.encrypt(data);
                Crypto.decrypt(data);
                crc = crc32(data);
                data = Crypto.encrypt(data);
            }

            byte[] buff = new byte[data.Length + 8];

            Console.WriteLine("File CRC: 0x{0:X8}", crc);

            buff[0] = (byte)(data.Length >> 0);
            buff[1] = (byte)(data.Length >> 8);
            buff[2] = (byte)(data.Length >> 16);
            buff[3] = (byte)(data.Length >> 24);

            buff[4] = (byte)(crc >> 0);
            buff[5] = (byte)(crc >> 8);
            buff[6] = (byte)(crc >> 16);
            buff[7] = (byte)(crc >> 24);

            Array.Copy(data, 0, buff, 8, data.Length);

            return buff;
        }
        
        static void cmd_progBIN(int addr, byte []data, bool crypt)
        {

            UInt32 crc = crc32(data);

            if (crypt)
            {
                data = Crypto.encrypt(data);
                Crypto.decrypt(data);
                crc = crc32(data);
                data = Crypto.encrypt(data);
            }
           
           
            byte[] buff = new byte[data.Length + 8];

            Console.WriteLine("File CRC: 0x{0:X8}", crc);

            buff[0] = (byte)(data.Length >> 0);
            buff[1] = (byte)(data.Length >> 8);
            buff[2] = (byte)(data.Length >> 16);
            buff[3] = (byte)(data.Length >> 24);

            buff[4] = (byte)(crc >> 0);
            buff[5] = (byte)(crc >> 8);
            buff[6] = (byte)(crc >> 16);
            buff[7] = (byte)(crc >> 24);

            Array.Copy(data, 0, buff, 8, data.Length);

            Console.WriteLine("Prog BIN... to 0x{0:X6}", addr);
            edio.flaWR(addr, buff, 0, buff.Length);

            Console.WriteLine("Verify BIN...");
            byte[] buff_vf = new byte[buff.Length];
            edio.flaRD(addr, buff_vf, 0, buff_vf.Length);

            for (int i = 0; i < buff_vf.Length; i++)
            {
                if (buff[i] != buff_vf[i])
                {
                    throw new Exception("Verification error at " + i);
                }
            }

        }

        static byte swapBits(byte val)
        {
            byte swp = 0;

            for (int i = 0; i < 8; i++)
            {
                swp <<= 1;
                swp |= (byte)(val & 1);
                val >>= 1;
            }

            return swp;
        }

        static void swapBits(byte []data)
        {

            for (int i = 0; i < data.Length; i++)
            {
                data[i] = swapBits(data[i]);
            }


        }

        static UInt32 crc32(byte[] source)
        {

            UInt32[] crc_table = new UInt32[256];
            UInt32 crc;

            for (UInt32 i = 0; i < 256; i++)
            {
                crc = i;
                for (UInt32 j = 0; j < 8; j++)
                    crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;

                crc_table[i] = crc;
            };

            crc = 0xFFFFFFFF;

            foreach (byte s in source)
            {
                crc = crc_table[(crc ^ s) & 0xFF] ^ (crc >> 8);
            }

            crc ^= 0xFFFFFFFF;

            return crc;
        }

    }
}
