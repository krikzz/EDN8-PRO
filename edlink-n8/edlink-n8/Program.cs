using System;
using System.IO;
using System.Reflection;

namespace edlink_n8
{
    class Program
    {

        static Edio edio;
        static Usbio usb;
        static void Main(string[] args)
        {

            Console.OutputEncoding = System.Text.Encoding.UTF8;

            Console.WriteLine("edlink-n8 v" + Assembly.GetEntryAssembly().GetName().Version);

            try
            {
                edlink(args);
            }
            catch (Exception x)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("");
                Console.WriteLine("ERROR: " + x.Message);
                Console.ResetColor();
            }

        }


        static void edlink(string[] args)
        {

            edio = new Edio();
            usb = new Usbio(edio);
            Console.WriteLine("EverDrive found at " + edio.PortName);
            Console.WriteLine("EDIO status: " + edio.getStatus().ToString("X4"));
            Console.WriteLine("");


            bool force_app_mode = true;
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].Equals("-appmode")) force_app_mode = false;
                if (args[i].Equals("-sermode")) force_app_mode = false;
            }
            if (force_app_mode)
            {
                edio.exitServiceMode();
            }


            if (args.Length == 0)
            {
                edio.getConfig().printFull();
                Console.WriteLine("");
                printState();
                Console.WriteLine("");
                edio.getPort().Close();
                Console.WriteLine("Press any key");
                Console.ReadKey();
                return;
            }


            cmdProcessor(args);
        }


        static void cmdProcessor(string []args)
        {

            string rom_path = null;
            string map_path = null;


            for (int i = 0; i < args.Length; i++)
            {
                string s = args[i].ToLower().Trim();

                if (s.Equals("-recovery"))
                {
                    cmd_recovery();
                }

                if (s.Equals("-appmode"))
                {
                    cmd_exitServiceMode();
                }

                if (s.Equals("-sermode"))
                {
                    cmd_enterServiceMode();
                }

                if (s.Equals("-diag"))
                {
                    cmd_diagnosics();
                }


                if (s.Equals("-mkdir"))
                {
                    usb.makeDir(args[i + 1]);
                    i += 1;
                    continue;
                }

                if (s.Equals("-rtcset"))
                {
                    edio.rtcSet(DateTime.Now);
                    continue;
                }

                if (s.Equals("-cp"))
                {
                    usb.copyFile(args[i + 1], args[i + 2]);
                    i += 2;
                    continue;
                }

                if (s.Equals("-flawr"))
                {
                    cmd_flashWrite(args[i + 1], args[i + 2]);
                    i += 2;
                    continue;
                }


                if (s.EndsWith(".nes") || s.EndsWith(".fds"))
                {
                    rom_path = args[i];
                    continue;
                }

                if (s.EndsWith(".rbf"))
                {
                    map_path = args[i];
                    continue;
                }

                if (s.StartsWith("-memwr"))
                {
                    cmd_memWrite(args[i + 1], args[i + 2]);
                    i += 2;
                }

                if (s.StartsWith("-memrd"))
                {
                    cmd_memRead(args[i + 1], args[i + 2], args[i + 3]);
                    i += 3;
                }

                if (s.StartsWith("-fpginit"))
                {
                    edio.fpgInit(File.ReadAllBytes(args[i + 1]), null);
                    i += 1;
                }
            }


            if (rom_path != null)
            {
                //edio.getConfig().print();
                loadROM(rom_path, map_path);
            }

            Console.WriteLine("");

        }

       
     

    
        

        static void printState()
        {
            byte[] ss = new byte[256];
            int cons_y = Console.CursorTop;


            edio.memRD(Edio.ADDR_SSR, ss, 0, ss.Length);
            Console.SetCursorPosition(0, cons_y);
            for (int i = 0; i < ss.Length; i += 16)
            {
                if (i == 128) Console.WriteLine("");
                if (i % 256 == 0) Console.WriteLine("");

                Console.ForegroundColor = ConsoleColor.White;

                if (i >= 128 + 0 && i < 128 + 32)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                }

                if (i >= 128 + 32 && i < 128 + 64)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                }

                if (i >= 128 + 64 && i < 256)
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                }

                Console.WriteLine("" + BitConverter.ToString(ss, i, 8) + "  " + BitConverter.ToString(ss, i + 8, 8));
            }

            /*
            Console.ForegroundColor = ConsoleColor.White;
            Console.Write("Mapper regs, ");
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.Write("APU regs, ");
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write("PPU pal, ");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("PPU regs + sst request src");*/

            Console.ForegroundColor = ConsoleColor.White;

        }

        static void cmd_recovery()
        {

            Console.Write("EDIO core recovery...");
            edio.recovery();
            Console.WriteLine("ok");
        }

        static void cmd_exitServiceMode()
        {
            Console.Write("Exit service mode...");
            edio.exitServiceMode();
            Console.WriteLine("ok");
        }

        static void cmd_enterServiceMode()
        {
            Console.Write("Enter service mode...");
            edio.enterServiceMode();
            Console.WriteLine("ok");
        }

        static void cmd_diagnosics()
        {
            Diagnostics diag = new Diagnostics(edio);
            diag.start();
        }


        static void cmd_flashWrite(string addr_str, string path)
        {
            int addr = 0;
            Console.Write("Flash programming...");

            if (addr_str.ToLower().Contains("0x"))
            {
                addr = Convert.ToInt32(addr_str, 16);
            }
            else
            {
                addr = Convert.ToInt32(addr_str);
            }

            byte []data = File.ReadAllBytes(path);

            edio.flaWR(addr, data, 0, data.Length);

            Console.WriteLine("ok");
        }


        static void cmd_memWrite(string path, string addr_str)
        {
            int addr = 0;
            Console.Write("Memory write...");

            addr = getNum(addr_str);

            byte[] data = File.ReadAllBytes(path);
            edio.memWR(addr, data, 0, data.Length);

            Console.WriteLine("ok");
        }

        static void cmd_memRead(string path, string addr_str, string len_str)
        {
            int addr;
            int len;
            Console.Write("Memory read...");

            addr = getNum(addr_str);
            len = getNum(len_str);

            byte[] data = new byte[len];
            edio.memRD(addr, data, 0, data.Length);
            File.WriteAllBytes(path, data);

            Console.WriteLine("ok");
        }
        static int getNum(string num)
        {

            if (num.ToLower().Contains("0x"))
            {
                return Convert.ToInt32(num, 16);
            }
            else
            {
                return Convert.ToInt32(num);
            }

        }

        static void loadROM(string rom_path, string map_path)
        {
            Console.WriteLine("ROM loading...");

            NesRom rom = new NesRom(rom_path);
            rom.print();

            if (rom.Type == NesRom.ROM_TYPE_OS)
            {
                usb.loadOS(rom, map_path);
            }
            else
            {
                //usb.loadGame_old(rom, map_path);
                usb.loadGame_new(rom_path, map_path);
            }

            Console.WriteLine();
            //edio.getConfig().print();
        }

    }
}
