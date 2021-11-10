using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO.Ports;

namespace stm32_boot_uart
{
    class Program
    {

        static SerialPort port;

        static void Main(string[] args)
        {

            try
            {

                port = new SerialPort("COM4");
                port.ReadTimeout = 1000;
                port.WriteTimeout = 1000;
                port.BaudRate = 19200;
                port.Parity = Parity.Even;
                port.StopBits = StopBits.One;
                port.Open();


                //cmdInit();

                byte[] cfg = cmdGet();
                Console.WriteLine("cfg: " + BitConverter.ToString(cfg));

                byte[] sta = cmdStatus();
                Console.WriteLine("sta: " + BitConverter.ToString(sta));

                byte[] dat = cmdRead();
                Console.WriteLine("dat: " + BitConverter.ToString(dat));




                port.Close();
            }
            catch (Exception x)
            {
                Console.WriteLine("ERROR: " + x.Message);
            }
        }

        static void waitAck()
        {
            int resp = port.ReadByte();
            if (resp == 0x79) return;
            throw new Exception("ack error: " + resp);

        }


        static void cmdInit()
        {
            port.Write(new byte[] { 0x7F }, 0, 1);
            waitAck();
            Console.WriteLine("init ok");
        }


        static byte[] cmdGet()
        {

            port.Write(new byte[] { 0x00, 0xff }, 0, 2);
            waitAck();


            byte[] resp = new byte[port.ReadByte() + 1];

            for (int i = 0; i < resp.Length;)
            {
                i += port.Read(resp, i, resp.Length - i);
            }

            waitAck();

            return resp;
        }

        static byte[] cmdRead()
        {

            port.Write(new byte[] { 0x11, 0xee }, 0, 2);
            waitAck();

            int a = 0x1FFFF7E0;

            byte[] addr = new byte[5];
            addr[0] = (byte)(a >> 24);
            addr[1] = (byte)(a >> 16);
            addr[2] = (byte)(a >> 8);
            addr[3] = (byte)(a >> 0);
            addr[4] = (byte)(addr[0] ^ addr[1] ^ addr[2] ^ addr[3]);
            port.Write(addr, 0, addr.Length);

            waitAck();


            byte[] len = new byte[2];
            len[0] = 15;
            len[1] = (byte)(len[0] ^ 0xff);
            port.Write(len, 0, len.Length);
            waitAck();


            byte[] resp = new byte[len[0] + 1];

            for (int i = 0; i < resp.Length;)
            {
                i += port.Read(resp, i, resp.Length - i);
            }

            return resp;
        }

        static byte[] cmdStatus()
        {

            port.Write(new byte[] { 0x02, 0xfd}, 0, 2);
            waitAck();
            

            byte[] resp = new byte[port.ReadByte() + 1];

            for (int i = 0; i < resp.Length;)
            {
                i += port.Read(resp, i, resp.Length - i);
            }

            waitAck();


            return resp;
        }
    }
}
