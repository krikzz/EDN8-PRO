using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Drawing;

namespace nesbuild
{
    class Program
    {


        static string home = "E:/projects/EDN8-PRO/";
        static string dist = home + "EDN8/";

        static void Main(string[] args)
        {

            try
            {
                osBuild();
            }
            catch (Exception x)
            {
                System.Console.WriteLine("ERROR: "+x.Message);
                System.Console.ReadLine();
            }
        }

        static byte[] loadMaprout()
        {
            byte[] mrout = File.ReadAllBytes("E:/projects/EDN8-PRO/mappers/MAPROUT.BIN");

            mrout[253] = 0xff;
            //mrout[254] = 1;

            return mrout;
        }

        static void osBuild()
        {

            Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8");
            Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8/maps");
            Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8/gamedata");
            Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8/sysdata");
            Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8/syscore");
            //Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8/SAVE");
            //Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8/SNAP");
            //Directory.CreateDirectory("E:/projects/EDN8-PRO/EDN8/CHEATS");

            File.Copy("E:/projects/EDN8-PRO/mappers/MAPROUT.BIN", "E:/projects/EDN8-PRO/EDN8/MAPROUT.BIN", true);

            File.Copy("E:/projects/EDN8-PRO/modules/n8nsf/n8nsf.nes", "E:/projects/EDN8-PRO/EDN8/syscore/n8nsf.nes", true);

            File.Copy("E:/projects/EDN8-PRO/sys-dist/iocore.bin", "E:/projects/EDN8-PRO/EDN8/syscore/iocore.bin", true);

            byte []mrout = loadMaprout();


            ushort[] musage = new ushort[4096];

            

            for (int i = 0; i < musage.Length; i++)
            {
                musage[mrout[i]] = 1;
            }

            string []list = Directory.GetFiles("E:/projects/EDN8-PRO/EDN8/MAPS/");
            for (int i = 0; i < list.Length; i++)
            {
                File.Delete(list[i]);
            }

            for (int i = 0; i < musage.Length; i++)
            {
                if (musage[i] == 0) continue;
                string src = "E:/projects/EDN8-PRO/mappers/";
                string dst = "E:/projects/EDN8-PRO/EDN8/MAPS/";
                if (i < 100) {
                    src += "0";
                    dst += "0";
                }
                if (i < 10) {
                    src += "0";
                    dst += "0";
                }

                src += i + "/output_files/top.rbf";
                dst += i + ".RBF";

                FileStream f;
                f = File.OpenRead(src);
                int len = (int)f.Length;
                if (len % 512 != 0) len = len / 512 * 512 + 512;
                byte[] buff = new byte[len];
                for (int u = 0; u < len; u++) buff[u] = 0xff;
                f.Read(buff, 0, (int)f.Length);
                f.Close();

                f = File.OpenWrite(dst);
                f.Write(buff, 0, len);
                f.Close();

                System.Console.WriteLine(src);
                System.Console.WriteLine(dst);

            }

            byte[] osbuff = File.ReadAllBytes("E:/projects/EDN8-PRO/N8-OS/nesos.nes");
            File.WriteAllBytes("E:/projects/EDN8-PRO/EDN8/nesos.nes", osbuff);


            picMaker();
            
        }

        static void picMaker()
        {
            int exist = 0;
            int total = 0;
            int w = 512;
            int h = 256;
            byte[] exlist = File.ReadAllBytes("E:/projects/EDN8-PRO/_tools/extable.bin");

            byte[] maprout = loadMaprout();


            for (int i = 0; i < maprout.Length; i++)
            {
                if (maprout[i] < 254) total++;
            }

            for (int i = 0; i < 254; i++)
            {
                if (maprout[i] != 0xff) exlist[i] = 1;
            }

            Bitmap pic = new Bitmap(w, h + 56 + 18);

            Graphics g = Graphics.FromImage(pic);

            g.FillRectangle(Brushes.Black, 0, 0, w, h+56+18);

            for (int i = 0; i < 256; i++)
            {
                int x = i % 16 * 32;
                int y = i / 16 * 16;
                if (maprout[i] < 254)

                exist += exlist[i] == 0 ? 0 : 1;
                Brush b = maprout[i] < 254 ? Brushes.SpringGreen : Brushes.White;// exlist[i] == 0 ? Brushes.White : Brushes.Yellow;
                g.FillRectangle(b, x, y, 32, 16);
                g.DrawString("" + i, new Font("Thaoma", 8), Brushes.Black, i % 16 * 32 + 4, i / 16 * 16);
            }

            
            for (int i = 0; i < 16; i++)
            {
                g.DrawLine(Pens.Black, 0, i * 16, w, i * 16);
                g.DrawLine(Pens.Black, i * 32, 0, i * 32, h);
                
            }

            /*
            int color = 0xff0000;
            color <<= 8;

            for (int i = 0; i < 128; i++)
            {
                color += (4+256*2+256*256);
                g.DrawLine(new Pen(Color.FromArgb(color)), i, 0, i, h);
                //if(color % )
            }
            */
            int yy = h+2;
            g.FillRectangle(Brushes.Yellow, 2, yy, 200, 24*3-3);
            g.DrawString("Mapper supported: " + total, new Font("Thaoma", 12), Brushes.Black, 8, yy + 24);
            yy += 24;

            /*
            g.FillRectangle(Brushes.SkyBlue, 0, yy, 200, 16);
            g.DrawString("Mapper + SaveState: " + ss_map, new Font("Thaoma", 8), Brushes.Black, 8, yy);
            yy += 18;
            */

            //g.FillRectangle(Brushes.Yellow, 0, yy, 200, 22);
            //g.DrawString("Mapper not supported: " + (exist - total), new Font("Thaoma", 8), Brushes.Black, 8, yy+4);

            //yy += 24;
            //g.FillRectangle(Brushes.White, 0, yy, 200, 22);
            //g.DrawString("Mapper not exist: " + (256-exist), new Font("Thaoma", 8), Brushes.Black, 8, yy + 4);


            g.DrawString("EverDrive-N8 PRO", new Font("Thaoma", 16), Brushes.White, 256, h+8+8);

            g.DrawString("" + DateTime.Now.Day + "." + DateTime.Now.Month + "." + DateTime.Now.Year, new Font("Thaoma", 8), Brushes.White, 315, pic.Height - 36+8);

            //g.DrawString("Based on No-Intro rom set", new Font("Thaoma", 8), Brushes.White, 256 + 24, pic.Height - 16);

            Brush bx = Brushes.DarkGray;
            g.FillRectangle(bx, 0, 0, pic.Width, 1);
            g.FillRectangle(bx, 0, pic.Height-1, pic.Width, 1);

            g.FillRectangle(bx, 0, 0, 1, pic.Height);
            g.FillRectangle(bx, pic.Width-1, 0, 1, pic.Height);

            pic.Save("E:/projects/EDN8-PRO/EDN8/mappers.png");
        }

        
    }
}
 