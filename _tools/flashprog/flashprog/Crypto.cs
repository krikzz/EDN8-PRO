using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace flashprog
{
    class Crypto
    {

        static byte[] enc_table = new byte[] {

            0x94,0x5E,0xA3,0x4B,0xC4,0x2D,0xD7,0xB0,0x71,0x39,0x69,0x1B,0x49,0xF6,0xBD,0xD2,
            0x42,0x0E,0x78,0xBC,0x5C,0x0A,0xD0,0xCA,0x17,0xED,0x24,0x1F,0xAC,0xD1,0xDE,0x9A,
            0xB7,0xC7,0xA2,0x54,0x2F,0x29,0x8C,0x85,0x4F,0xEA,0xBF,0x93,0xD6,0x67,0x00,0xE8,
            0xA0,0x89,0x81,0x99,0xE9,0x8B,0x52,0x8D,0x97,0x3C,0xAE,0x3F,0x0B,0x9F,0xBA,0x48,
            0x4D,0xDF,0x58,0xE7,0x5A,0x4E,0xAB,0x3D,0xFA,0x61,0xF4,0x21,0xA7,0x96,0xF7,0xAD,
            0x10,0x6D,0xC2,0xCB,0x45,0x4C,0x55,0x88,0x3E,0x51,0xA1,0x53,0xB1,0x8E,0xE1,0x46,
            0xB4,0x11,0x6F,0x16,0x7E,0x12,0xC9,0x31,0x7A,0x83,0xEF,0x65,0xF1,0xA4,0x22,0x7F,
            0xE5,0xC3,0x1C,0x15,0x5D,0x5B,0x33,0x01,0xFF,0x87,0x36,0x7C,0xA5,0x8A,0x6C,0x73,
            0xFE,0xBE,0x0D,0x2C,0xEC,0x1D,0x44,0xCE,0xA6,0x32,0x56,0x2A,0xB9,0x08,0x05,0x41,
            0x4A,0x74,0xF2,0xA8,0x1A,0x19,0xB2,0xEB,0x60,0x07,0x13,0x57,0xEE,0x76,0x04,0xBB,
            0x2E,0x37,0x90,0x6A,0x28,0x95,0x06,0x50,0x70,0x02,0x9C,0xA9,0x82,0xE2,0xAA,0xCC,
            0xFB,0x5F,0x92,0x47,0xD8,0x59,0x27,0xB3,0xE0,0xB5,0xDB,0x91,0x63,0x14,0xDD,0x26,
            0x3A,0xF3,0x7D,0x6B,0x79,0x7B,0xFC,0x8F,0x84,0x9E,0xC6,0x38,0xD3,0xE4,0x62,0x03,
            0x77,0xD4,0x9D,0xC8,0xF9,0xE6,0x80,0xC5,0x18,0xE3,0xD9,0x64,0x20,0x34,0xB8,0x2B,
            0xAF,0xCD,0x9B,0x86,0xC0,0x23,0x25,0x09,0xF0,0x6E,0x3B,0x0C,0x75,0xB6,0x40,0xC1,
            0x30,0xCF,0xF8,0xDA,0x1E,0xD5,0x68,0x0F,0x72,0xFD,0xF5,0x66,0xDC,0x35,0x43,0x98,
        };

        static byte[] key = new byte[] { 0x56, 0xB0, 0x6A, 0x41, 0x3C, 0xE2, 0xF9, 0xCB, 0xEB, 0x08, 0x9E, 0xD1, 0x34, 0xE8, 0x76, 0xF2 };

        static byte cr_len;
        static byte cr_key_ptr;
        static byte cr_idx;
        static byte cr_inc;
        static byte cr_shift;
        static int cr_addr;

        public static byte [] encrypt(byte []data)
        {

            initEngine();

            data = trimArray(data, 256);

            replaceBytes(data);
            shuffleBytes(data);
            xorBytes(data);

            return data;
        }

        public static void decrypt(byte []data)
        {
            initEngine();

            byte[] buff = new byte[256];
            for (int i = 0; i < data.Length; i += 256)
            {

                Array.Copy(data, i, buff, 0, 256);

                xorBytes_back(buff);
                shuffleBytes_back(buff);
                replaceBytes_back(buff);
                cr_addr += 256;

                Array.Copy(buff, 0, data, i, 256);
            }
        }

        static byte[] trimArray(byte[] data, int mod)
        {

            if (data.Length % mod == 0) return data;

            byte[] buff = new byte[data.Length / mod * mod + mod];
            for (int i = 0; i < buff.Length; i++) buff[i] = 0xff;
            Array.Copy(data, 0, buff, 0, data.Length);
            return buff;
        }

        static void initEngine()
        {
            cr_len = 0;
            cr_key_ptr = 0;
            cr_idx = 0;
            cr_inc = 0;
            cr_shift = 0;
            cr_addr = 0;
        }
        //************************************************************************************ encryption
        //************************************************************************************
        //************************************************************************************
        //************************************************************************************

        static void replaceBytes(byte[] data)
        {

            byte[] dec_table = new byte[256];
            for (int i = 0; i < dec_table.Length; i++)
            {
                dec_table[enc_table[i]] = (byte)i;
            }

            for (int i = 0; i < data.Length; i++)
            {
                data[i] = dec_table[data[i]];
            }
        }

        static void shuffleBytes(byte[] data)
        {

            byte shift = 0;

            for (int i = data.Length - 1; i >= 0; i--)
            {

                if (i % 256 == 255) shift = (byte)(key[i / 256 % key.Length] + 255);

                int idx = enc_table[shift--] + i / 256 * 256;

                byte tmp = data[i];
                data[i] = data[idx];
                data[idx] = tmp;
            }
        }

        static void xorBytes(byte[] data)
        {

            byte idx = 0;
            byte len = 0;
            byte key_val = 0;
            int key_ptr = 0;
            byte inc = 0;
            int[] stat = new int[256];

            for (int i = 0; i < data.Length; i++)
            {

                len &= 15;

                if (len == 0)
                {

                    key_val = key[key_ptr % key.Length];
                    len = (byte)(key_ptr % (key.Length * 2) == 0 ? key_val >> 4 : key_val & 15);
                    key_ptr++;

                    idx += key_val;
                    inc++;
                    if (idx == inc) inc++;
                    //Console.WriteLine("len: {0:X2}, idx: {1:X2}", len, idx);

                }


                data[i] ^= enc_table[idx];
                data[i] ^= enc_table[inc];
                data[i] += (byte)i;

                len--;
                idx++;

            }

        }


        //************************************************************************************ decryption
        //************************************************************************************
        //************************************************************************************
        //************************************************************************************

        static void shuffleBytes_back(byte[] data)
        {

            byte tmp;
            byte idx;
            byte block_idx = (byte)(cr_addr / 256);
            int i;

            cr_shift = key[cr_addr / 256 % key.Length];

            for (i = 0; i < 256; i++)
            {

                idx = enc_table[cr_shift++];
                tmp = data[i];
                data[i] = data[idx];
                data[idx] = tmp;
            }

        }


        static void xorBytes_back(byte[] data)
        {

            byte key_val = 0;
            int i;

            for (i = 0; i < 256; i++)
            {

                cr_len &= 15;

                if (cr_len == 0)
                {

                    key_val = key[cr_key_ptr % key.Length];
                    cr_len = key_val;
                    cr_len = (byte)(cr_key_ptr % (key.Length * 2) == 0 ? key_val >> 4 : key_val & 15);
                    cr_key_ptr++;

                    cr_idx += key_val;
                    cr_inc++;
                    if (cr_idx == cr_inc) cr_inc++;
                }


                data[i] -= (byte)i;
                data[i] ^= enc_table[cr_inc];
                data[i] ^= enc_table[cr_idx];

                cr_len--;
                cr_idx++;

            }

        }


        static void replaceBytes_back(byte[] data)
        {

            int i;

            for (i = 0; i < 256; i++)
            {
                data[i] = enc_table[data[i]];
            }

        }

    }


}
