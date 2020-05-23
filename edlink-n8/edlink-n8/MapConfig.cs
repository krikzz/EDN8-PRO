using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace edlink_n8
{
    class MapConfig
    {

        const int cfg_base = 32;

        public const byte cfg_mir_h = 0;
        public const byte cfg_mir_v = 1;
        public const byte cfg_mir_4 = 2;
        public const byte cfg_mir_1 = 3;
        public const byte cfg_chr_ram = 4;
        public const byte cfg_srm_off = 8;

        public const byte ctrl_rst_delay = 0x01;
        public const byte ctrl_ss_on = 0x02;
        public const byte ctrl_ss_btn = 0x08;

        public const byte ctrl_unlock = 0x80;

        byte[] config = new byte[cfg_base + 8];

        public MapConfig(byte[] bin)
        {
            Array.Copy(bin, 0, config, 0, config.Length);
        }

        public MapConfig()
        {
            map_idx = 255;
            SSKey_load = 0xff;
            SSKey_save = 0xff;
        }

        public MapConfig(NesRom rom)
        {

            map_idx = rom.Mapper;

            if (rom.Mirroring == 'H') MapCfg |= cfg_mir_h;
            if (rom.Mirroring == 'V') MapCfg |= cfg_mir_v;
            if (rom.Mirroring == '4') MapCfg |= cfg_mir_4;
            if (rom.ChrSize == 0) MapCfg |= cfg_chr_ram;

            PrgSize = rom.PrgSize;
            ChrSize = rom.ChrSize;
            SrmSize = rom.SrmSize;

            MasterVol = 8;
            SSKey_save = 0x14;//start + down
            SSKey_load = 0x18;//start + up

        }


        public void printFull()
        {
            
            Console.WriteLine("mappper....." + map_idx + " sub."+Submap);

            Console.WriteLine("prg size...." + PrgSize / 1024 + "K");
            string chr_type = (MapCfg & cfg_chr_ram) == 0 ? "" : "ram";
            Console.WriteLine("chr size...." + ChrSize / 1024 + "K "+ chr_type);
            string stm_state = (MapCfg & cfg_srm_off) != 0 ? "srm off" : SrmSize < 1024 ? (SrmSize + "B ") : (SrmSize / 1024 + "K ");
            Console.WriteLine("srm size...." + stm_state);

            Console.WriteLine("master vol.." + MasterVol);

            string mir = "?";
            if ((MapCfg & 3) == cfg_mir_h) mir = "h";
            if ((MapCfg & 3) == cfg_mir_v) mir = "v";
            if ((MapCfg & 3) == cfg_mir_4) mir = "4";
            if ((MapCfg & 3) == cfg_mir_1) mir = "1";
            Console.WriteLine("mirroring..." + mir);
            Console.WriteLine("cfg bits...."+ Convert.ToString(MapCfg, 2).PadLeft(8, '0'));

            Console.WriteLine("save key....0x{0:X2}", SSKey_save);
            Console.WriteLine("load key....0x{0:X2}", SSKey_load);
            Console.WriteLine("rst delay..." + ((Ctrl & ctrl_rst_delay) != 0 ? "yes" : "no"));
            Console.WriteLine("save state.." + ((Ctrl & ctrl_ss_on) != 0 ? "yes" : "no"));
            Console.WriteLine("ss button..." + ((Ctrl & ctrl_ss_btn) != 0 ? "yes" : "no"));
            Console.WriteLine("unlock......" + ((Ctrl & ctrl_unlock) != 0 ? "yes" : "no"));
            Console.WriteLine("ctrl bits..." + Convert.ToString(Ctrl, 2).PadLeft(8, '0'));
            print();

        }

        public void print()
        {
            Console.WriteLine("CFG: "+ BitConverter.ToString(config, cfg_base));
        }

        public byte[] getBinary()
        {
            return config;
        }

        byte getRomMask(int size)
        {
            byte msk = 0;
            while ((8192 << msk) < size && msk < 15)
            {
                msk++;
            }
            return (byte)(msk & 0x0F);
        }

        byte getSrmMask(int size)
        {
            byte msk = 0;
            while ((128 << msk) < size && msk < 15)
            {
                msk++;
            }
            return (byte)(msk & 0x0F);
        }

        public int map_idx
        {
            get
            {
                return config[cfg_base + 0] | ((config[cfg_base + 2] & 0xf0) << 4);
            }
            set
            {
                config[cfg_base + 0] = (byte)(value);
                config[cfg_base + 2] |= (byte)((value & 0xf00) >> 4);
            }
        }

        public int PrgSize
        {
            get
            {
                return 8192 << (config[cfg_base + 1] & 0x0f);
            }
            set
            {
                config[cfg_base + 1] = (byte)((config[cfg_base + 1] & 0xf0) | getRomMask(value));
            }
        }

        public int SrmSize
        {
            get
            {
                return 128 << (config[cfg_base + 1] >> 4);
            }
            set
            {
                config[cfg_base + 1] = (byte)((config[cfg_base + 1] & 0x0f) | getSrmMask(value) << 4);
            }
        }

        public int ChrSize
        {
            get
            {
                return 8192 << (config[cfg_base + 2] & 0x0f);
            }
            set
            {
                config[cfg_base + 2] = (byte)((config[cfg_base + 2] & 0xf0) | getSrmMask(value));
            }
        }


        public byte MasterVol
        {
            get { return config[cfg_base + 3]; }
            set { config[cfg_base + 3] = value; }
        }

        public byte Submap
        {
            get { return (byte)(MapCfg >> 4); }
            set { MapCfg = (byte)((MapCfg & ~0xf0)  | (value)); }
        }

        public byte MapCfg
        {
            get { return config[cfg_base + 4]; }
            set { config[cfg_base + 4] = value; }
        }


        public byte SSKey_save
        {
            get { return config[cfg_base + 5]; }
            set { config[cfg_base + 5] = value; }
        }
        public byte SSKey_load
        {
            get { return config[cfg_base + 6]; }
            set { config[cfg_base + 6] = value; }
        }

        public byte Ctrl
        {
            get { return config[cfg_base + 7]; }
            set { config[cfg_base + 7] = value; }
        }

        



    }
}
