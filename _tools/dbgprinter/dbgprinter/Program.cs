using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO.Ports;
using System.IO;

namespace dbgprinter
{
    class Program
    {

        static byte[] cdlog = new byte[0x100000 * 4];


        static void Main(string[] args)
        {
            try
            {
                loadLog();
            }
            catch(Exception x)
            {

                printLog();
                //File.WriteAllBytes("d:/log.bin", cdlog);
                Console.WriteLine("logging complete!");
                while (true) ;
            }
        }

        static void printLog()
        {

            TextWriter tx = new StreamWriter("d:/cdlog.txt");
            

            for (int i = 0; i < cdlog.Length; i += 4)
            {

                if (cdlog[i] == 0) break;

                int mode = cdlog[i + 0];
                int addr = cdlog[i + 1];
                int dat_val = (cdlog[i + 2] << 8) | cdlog[i + 3];


                int oe = mode & 0x01;
                int we_lo = mode & 0x02;
                int we_hi = mode & 0x04;




                string inf = "";

                if (oe == 0)
                {
                    inf += "RD:";
                }
                else
                {
                    inf += "WR:";
                }
               



                //Console.WriteLine(i / 4 + "." + inf + "{0:X2}-{1:X4}", addr, dat_val);
                if(we_hi == 0 && we_lo != 0)
                {
                    tx.WriteLine(i / 4 + "." + inf + "{0:X2}-{1:X2}XX", addr, (dat_val >> 8));
                } else if (we_hi != 0 && we_lo == 0)
                {
                    tx.WriteLine(i / 4 + "." + inf + "{0:X2}-XX{1:X2}", addr, (dat_val & 0xff));
                }
                else
                {
                    tx.WriteLine(i / 4 + "." + inf + "{0:X2}-{1:X4}", addr, dat_val);
                }


            }

            tx.Close();
    }

    static void loadLog()
    {

        SerialPort port = new SerialPort("COM29");
        port.BaudRate = 3000000;
        port.Open();


        for(int i = 0;i < cdlog.Length;)
        {
            i += port.Read(cdlog, i, cdlog.Length - i);
        }
        return;


    }


        static void readPort(SerialPort port, byte []buff,int offset, int len)
        {
            while (len > 0)
            {
                int block = port.Read(buff, offset, len);
                offset += block;
                len -= block;
            }
        }
    }
}
