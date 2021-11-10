using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace dasma
{
    class Program
    {
        static void Main(string[] args)
        {

            
          //  try
            {
                //args = new string[2];
                //args[0] = "src=E:/soft/portable/Telegram";
                //args[0] = "src=D:/sync/src";
                //args[0] = "src=D:/";
                //args[1] = "dst=D:/sync/dst";
                //args[1] = "dst=f:/sync/D";
                //args[1] = "dst=\\\\datahub\\krikzz\\sync";
                //parse();
                parseHex();
            }
           // catch (NullReferenceException x)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("");
               // Console.WriteLine("ERROR: " + x.Message);
                Console.ResetColor();

            }

        }


        static void parseHex()
        {
            while (true)
            {
                string inp = Console.ReadLine();

                string outp = ".byte ";

                for(int i = 0;i < inp.Length; i += 2)
                {
                    if (i != 0) outp += ",";
                    outp += "$" + inp.Substring(i, 2);

                }

                Console.CursorTop = Console.CursorTop - 1;

                Console.WriteLine(outp);
            }
        }


        static void parse()
        {
            string inp = File.ReadAllText("E:/projects/EDN8-PRO/fds-bios/src.s");

            

            inp = inp.Replace("BEQ $", "BEQ _");
            inp = inp.Replace("BNE $", "BNE _");
            inp = inp.Replace("BCC $", "BCC _");
            inp = inp.Replace("BCS $", "BCS _");
            inp = inp.Replace("BVC $", "BVC _");
            inp = inp.Replace("JSR $", "JSR _");

            inp = inp.Replace("BPL $", "BPL _");
            inp = inp.Replace("BMI $", "BMI _");
            inp = inp.Replace("BVS $", "BVS _");

            inp = inp.Replace("Get#ofFiles", "Get_ofFiles");
            inp = inp.Replace("Set#ofFiles", "Set_ofFiles");
            inp = inp.Replace("LoadSiz&Src", "LoadSiz_Src");

            


            int offset = 0;
            while (true)
            {
                offset++;
                offset = inp.IndexOf('_', offset);
                string mark = inp.Substring(offset + 1, 4);
                inp = inp.Replace(System.Environment.NewLine + "$" + mark, System.Environment.NewLine + "_" + mark + ":" + System.Environment.NewLine);

                if (offset < 0) break;
            }

            string[] tokens = inp.Split(new [] { System.Environment.NewLine }, System.StringSplitOptions.None);

            Console.WriteLine("lines: " + tokens.Length);




            for(int i = 0; i < tokens.Length; i++)
            {

                if (!tokens[i].StartsWith(";"))
                {
                    tokens[i] = tokens[i].Replace(":\t", ":" + System.Environment.NewLine+"    ");
                }

                if (tokens[i].StartsWith("$") && tokens[i].Length == 5)
                {
                    tokens[i] = "";
                }
                if (tokens[i].StartsWith("$") && tokens[i].Substring(5,1).Equals("\t")){
                    tokens[i] = tokens[i].Substring(5).Trim();
                }

                if(i < tokens.Length - 2)
                {
                    if(tokens[i].StartsWith(";") && !tokens[i+1].StartsWith(";") && tokens[i+1].Contains("???????"))
                    {
                        tokens[i] += tokens[i + 1];
                        tokens[i + 1] = "";
                    }
                }
            }



            string oup = "";
            for (int i = 0; i < tokens.Length; i++)
            {
                tokens[i] = tokens[i].Trim();

                if(!tokens[i].StartsWith(";") && !tokens[i].StartsWith(".") && !tokens[i].Contains(":"))
                {
                    tokens[i] = "    " + tokens[i];
                }

                oup += tokens[i] + System.Environment.NewLine;
            }

            File.WriteAllText("E:/projects/EDN8-PRO/fds-bios/fdsio.s", oup);
        }





    }
}
