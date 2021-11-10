using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace romfix_n8
{
    class Program
    {
        static void Main(string[] args)
        {

            XmlDocument xml_db = new XmlDocument();
            xml_db.Load("D:/nesdb.xml");

            XmlElement xRoot = xml_db.DocumentElement;



            //XmlNode attr = xnode.Attributes.GetNamedItem("name");
            
            string str =  "cnt: " + xRoot.ChildNodes.Item(1).ChildNodes.Item(1).Attributes.GetNamedItem("crc").InnerText; 

            Console.WriteLine("resp: " + str);

        }
    }
}
