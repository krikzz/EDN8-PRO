using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace hubgen
{
    class Program
    {
        static void Main(string[] args)
        {
            try {

                printer();

            }
            catch(Exception x)
            {
                Console.WriteLine("error: " + x.Message);
            }
        }



        static void printer()
        {
            

            while (true)
            {
                string inp = Console.ReadLine();
                Console.CursorTop = Console.CursorTop - 1;

                string num = inp.Substring(inp.IndexOf("map_out_") + 8, 3);

                Console.WriteLine("wire [`BW_MAP_OUT-1:0]map_out_" + num + ";");
                Console.WriteLine("map_" + num + " m" + num + "(map_out_" + num + ", bus, sys_cfg, ss_ctrl);");
                Console.WriteLine("");

            }

            
        }
    }
}
