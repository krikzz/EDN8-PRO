using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace memreport
{
    class Program
    {
        static void Main(string[] args)
        {

            try
            {

                byte[] rom = File.ReadAllBytes(args[0]);

                Console.WriteLine("BANK    USED    FREE");
                
                for(int i = 0;i < 8; i++)
                {
                    string bnk = "BNK";
                    int addr = 0x8000 + i * 8192;
                    int bank_idx = addr / 8192;

                    if (bank_idx < 10) bnk += "0";
                    bnk += bank_idx;


                    report(bnk, rom, addr, 8192);
                }

                report("PRGXX", rom, 0x18000, 32768 - 16);
                /*
                string used = " (" + mem_used / 1024 + "K)";
                string free = " (" + mem_free / 1024 + "K)";
                string totl = " (" + mem_free / 1024 + "K)";
                Console.WriteLine("Main: "+ used);*/

            }


            catch(Exception x)
            {
                Console.WriteLine("ERROR: " + x.Message);
            }

        }

        
        static void report(string name,  byte []rom, int offset, int size)
        {
            
            int mem_used = 0;
            int mem_free = 0;

            offset += 0x10;

            for (int i = 0; i < size; i++)
            {
                if (rom[i + offset] != 0) mem_used = i;
            }

            mem_free = size - mem_used;

            
            Console.WriteLine(name + "   " + mem_used.ToString().PadLeft(5, '0') + "   " + mem_free.ToString().PadLeft(5, '0') + " (" + mem_free / 1024 + "K)");


        }
    }
}
