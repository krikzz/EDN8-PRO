-- ******************************************************************************

-- iCEcube Netlister

-- Version:            2017.08.27940

-- Build Date:         Sep 11 2017 17:29:57

-- File Generated:     Sep 16 2019 00:32:54

-- Purpose:            Post-Route Verilog/VHDL netlist for timing simulation

-- Copyright (C) 2006-2010 by Lattice Semiconductor Corp. All rights reserved.

-- ******************************************************************************

-- VHDL file for cell "top" view "INTERFACE"

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library ice;
use ice.vcomponent_vital.all;

-- Entity of top
entity top is
port (
    cpu_addr : in std_logic_vector(14 downto 0);
    cpu_dat : out std_logic_vector(7 downto 0);
    gpio : out std_logic_vector(3 downto 0);
    spi_mosi : in std_logic;
    cpu_ex : out std_logic;
    cpu_ce : in std_logic;
    cpu_dir : out std_logic;
    ice_ss : in std_logic;
    ice_sdo : out std_logic;
    ice_sck : in std_logic;
    boot0 : out std_logic;
    spi_miso : out std_logic;
    cpu_rw : in std_logic;
    clk : in std_logic;
    spi_clk : in std_logic;
    ice_sdi : in std_logic;
    mcu_rst : out std_logic;
    boot_on : in std_logic;
    spi_ss : in std_logic;
    cpu_m2 : in std_logic;
    cpu_irq : in std_logic);
end top;

-- Architecture of top
-- View name is \INTERFACE\
architecture \INTERFACE\ of top is

signal \N__1678\ : std_logic;
signal \N__1677\ : std_logic;
signal \N__1676\ : std_logic;
signal \N__1667\ : std_logic;
signal \N__1666\ : std_logic;
signal \N__1665\ : std_logic;
signal \N__1658\ : std_logic;
signal \N__1657\ : std_logic;
signal \N__1656\ : std_logic;
signal \N__1649\ : std_logic;
signal \N__1648\ : std_logic;
signal \N__1647\ : std_logic;
signal \N__1640\ : std_logic;
signal \N__1639\ : std_logic;
signal \N__1638\ : std_logic;
signal \N__1631\ : std_logic;
signal \N__1630\ : std_logic;
signal \N__1629\ : std_logic;
signal \N__1622\ : std_logic;
signal \N__1621\ : std_logic;
signal \N__1620\ : std_logic;
signal \N__1613\ : std_logic;
signal \N__1612\ : std_logic;
signal \N__1611\ : std_logic;
signal \N__1604\ : std_logic;
signal \N__1603\ : std_logic;
signal \N__1602\ : std_logic;
signal \N__1595\ : std_logic;
signal \N__1594\ : std_logic;
signal \N__1593\ : std_logic;
signal \N__1586\ : std_logic;
signal \N__1585\ : std_logic;
signal \N__1584\ : std_logic;
signal \N__1577\ : std_logic;
signal \N__1576\ : std_logic;
signal \N__1575\ : std_logic;
signal \N__1568\ : std_logic;
signal \N__1567\ : std_logic;
signal \N__1566\ : std_logic;
signal \N__1559\ : std_logic;
signal \N__1558\ : std_logic;
signal \N__1557\ : std_logic;
signal \N__1550\ : std_logic;
signal \N__1549\ : std_logic;
signal \N__1548\ : std_logic;
signal \N__1541\ : std_logic;
signal \N__1540\ : std_logic;
signal \N__1539\ : std_logic;
signal \N__1532\ : std_logic;
signal \N__1531\ : std_logic;
signal \N__1530\ : std_logic;
signal \N__1523\ : std_logic;
signal \N__1522\ : std_logic;
signal \N__1521\ : std_logic;
signal \N__1514\ : std_logic;
signal \N__1513\ : std_logic;
signal \N__1512\ : std_logic;
signal \N__1505\ : std_logic;
signal \N__1504\ : std_logic;
signal \N__1503\ : std_logic;
signal \N__1496\ : std_logic;
signal \N__1495\ : std_logic;
signal \N__1494\ : std_logic;
signal \N__1487\ : std_logic;
signal \N__1486\ : std_logic;
signal \N__1485\ : std_logic;
signal \N__1478\ : std_logic;
signal \N__1477\ : std_logic;
signal \N__1476\ : std_logic;
signal \N__1469\ : std_logic;
signal \N__1468\ : std_logic;
signal \N__1467\ : std_logic;
signal \N__1460\ : std_logic;
signal \N__1459\ : std_logic;
signal \N__1458\ : std_logic;
signal \N__1451\ : std_logic;
signal \N__1450\ : std_logic;
signal \N__1449\ : std_logic;
signal \N__1442\ : std_logic;
signal \N__1441\ : std_logic;
signal \N__1440\ : std_logic;
signal \N__1433\ : std_logic;
signal \N__1432\ : std_logic;
signal \N__1431\ : std_logic;
signal \N__1424\ : std_logic;
signal \N__1423\ : std_logic;
signal \N__1422\ : std_logic;
signal \N__1415\ : std_logic;
signal \N__1414\ : std_logic;
signal \N__1413\ : std_logic;
signal \N__1406\ : std_logic;
signal \N__1405\ : std_logic;
signal \N__1404\ : std_logic;
signal \N__1397\ : std_logic;
signal \N__1396\ : std_logic;
signal \N__1395\ : std_logic;
signal \N__1388\ : std_logic;
signal \N__1387\ : std_logic;
signal \N__1386\ : std_logic;
signal \N__1369\ : std_logic;
signal \N__1366\ : std_logic;
signal \N__1363\ : std_logic;
signal \N__1360\ : std_logic;
signal \N__1357\ : std_logic;
signal \N__1354\ : std_logic;
signal \N__1351\ : std_logic;
signal \N__1348\ : std_logic;
signal \N__1345\ : std_logic;
signal \N__1342\ : std_logic;
signal \N__1339\ : std_logic;
signal \N__1336\ : std_logic;
signal \N__1333\ : std_logic;
signal \N__1330\ : std_logic;
signal \N__1329\ : std_logic;
signal \N__1326\ : std_logic;
signal \N__1323\ : std_logic;
signal \N__1318\ : std_logic;
signal \N__1317\ : std_logic;
signal \N__1314\ : std_logic;
signal \N__1311\ : std_logic;
signal \N__1306\ : std_logic;
signal \N__1303\ : std_logic;
signal \N__1300\ : std_logic;
signal \N__1297\ : std_logic;
signal \N__1294\ : std_logic;
signal \N__1291\ : std_logic;
signal \N__1288\ : std_logic;
signal \N__1285\ : std_logic;
signal \N__1282\ : std_logic;
signal \N__1279\ : std_logic;
signal \N__1276\ : std_logic;
signal \N__1273\ : std_logic;
signal \N__1270\ : std_logic;
signal \N__1267\ : std_logic;
signal \N__1264\ : std_logic;
signal \N__1261\ : std_logic;
signal \N__1258\ : std_logic;
signal \N__1257\ : std_logic;
signal \N__1256\ : std_logic;
signal \N__1253\ : std_logic;
signal \N__1250\ : std_logic;
signal \N__1247\ : std_logic;
signal \N__1244\ : std_logic;
signal \N__1239\ : std_logic;
signal \N__1234\ : std_logic;
signal \N__1231\ : std_logic;
signal \N__1228\ : std_logic;
signal \N__1225\ : std_logic;
signal \N__1222\ : std_logic;
signal \N__1219\ : std_logic;
signal \N__1218\ : std_logic;
signal \N__1217\ : std_logic;
signal \N__1214\ : std_logic;
signal \N__1211\ : std_logic;
signal \N__1210\ : std_logic;
signal \N__1207\ : std_logic;
signal \N__1206\ : std_logic;
signal \N__1205\ : std_logic;
signal \N__1200\ : std_logic;
signal \N__1197\ : std_logic;
signal \N__1194\ : std_logic;
signal \N__1191\ : std_logic;
signal \N__1188\ : std_logic;
signal \N__1185\ : std_logic;
signal \N__1182\ : std_logic;
signal \N__1179\ : std_logic;
signal \N__1174\ : std_logic;
signal \N__1173\ : std_logic;
signal \N__1172\ : std_logic;
signal \N__1169\ : std_logic;
signal \N__1166\ : std_logic;
signal \N__1161\ : std_logic;
signal \N__1158\ : std_logic;
signal \N__1155\ : std_logic;
signal \N__1144\ : std_logic;
signal \N__1141\ : std_logic;
signal \N__1138\ : std_logic;
signal \N__1135\ : std_logic;
signal \N__1132\ : std_logic;
signal \N__1129\ : std_logic;
signal \N__1126\ : std_logic;
signal \N__1123\ : std_logic;
signal \N__1120\ : std_logic;
signal \N__1117\ : std_logic;
signal \N__1114\ : std_logic;
signal \N__1111\ : std_logic;
signal \N__1108\ : std_logic;
signal \N__1105\ : std_logic;
signal \N__1102\ : std_logic;
signal \N__1099\ : std_logic;
signal \N__1096\ : std_logic;
signal \N__1093\ : std_logic;
signal \N__1090\ : std_logic;
signal \N__1087\ : std_logic;
signal \N__1084\ : std_logic;
signal \N__1081\ : std_logic;
signal \N__1078\ : std_logic;
signal \N__1075\ : std_logic;
signal \N__1072\ : std_logic;
signal \N__1069\ : std_logic;
signal \N__1066\ : std_logic;
signal \N__1063\ : std_logic;
signal \N__1060\ : std_logic;
signal \N__1057\ : std_logic;
signal \N__1054\ : std_logic;
signal \N__1051\ : std_logic;
signal \N__1048\ : std_logic;
signal \N__1045\ : std_logic;
signal \N__1042\ : std_logic;
signal \N__1039\ : std_logic;
signal \N__1036\ : std_logic;
signal \N__1033\ : std_logic;
signal \N__1030\ : std_logic;
signal \N__1027\ : std_logic;
signal \N__1024\ : std_logic;
signal \N__1021\ : std_logic;
signal \N__1018\ : std_logic;
signal \N__1015\ : std_logic;
signal \N__1012\ : std_logic;
signal \N__1009\ : std_logic;
signal \N__1006\ : std_logic;
signal \N__1003\ : std_logic;
signal \N__1000\ : std_logic;
signal \N__997\ : std_logic;
signal \N__994\ : std_logic;
signal \N__991\ : std_logic;
signal \N__988\ : std_logic;
signal \N__985\ : std_logic;
signal \N__982\ : std_logic;
signal \N__979\ : std_logic;
signal \N__976\ : std_logic;
signal \N__973\ : std_logic;
signal \N__970\ : std_logic;
signal \N__969\ : std_logic;
signal \N__968\ : std_logic;
signal \N__967\ : std_logic;
signal \N__966\ : std_logic;
signal \N__965\ : std_logic;
signal \N__964\ : std_logic;
signal \N__963\ : std_logic;
signal \N__958\ : std_logic;
signal \N__945\ : std_logic;
signal \N__940\ : std_logic;
signal \N__937\ : std_logic;
signal \N__934\ : std_logic;
signal \N__931\ : std_logic;
signal \N__928\ : std_logic;
signal \N__925\ : std_logic;
signal \N__922\ : std_logic;
signal \N__921\ : std_logic;
signal \N__918\ : std_logic;
signal \N__915\ : std_logic;
signal \N__910\ : std_logic;
signal \N__907\ : std_logic;
signal \N__904\ : std_logic;
signal \N__901\ : std_logic;
signal \N__898\ : std_logic;
signal \N__895\ : std_logic;
signal \N__892\ : std_logic;
signal \N__889\ : std_logic;
signal \N__886\ : std_logic;
signal \N__883\ : std_logic;
signal \N__880\ : std_logic;
signal \N__877\ : std_logic;
signal \N__874\ : std_logic;
signal \N__871\ : std_logic;
signal \N__868\ : std_logic;
signal \N__865\ : std_logic;
signal \N__862\ : std_logic;
signal \N__861\ : std_logic;
signal \N__856\ : std_logic;
signal \N__853\ : std_logic;
signal \N__850\ : std_logic;
signal \N__847\ : std_logic;
signal \N__844\ : std_logic;
signal \N__841\ : std_logic;
signal \N__838\ : std_logic;
signal \N__835\ : std_logic;
signal \N__832\ : std_logic;
signal \N__829\ : std_logic;
signal \N__826\ : std_logic;
signal \N__823\ : std_logic;
signal \N__820\ : std_logic;
signal \N__817\ : std_logic;
signal \N__814\ : std_logic;
signal \N__811\ : std_logic;
signal \N__808\ : std_logic;
signal \N__805\ : std_logic;
signal \N__802\ : std_logic;
signal \N__799\ : std_logic;
signal \N__796\ : std_logic;
signal \N__793\ : std_logic;
signal \N__790\ : std_logic;
signal \N__787\ : std_logic;
signal \N__784\ : std_logic;
signal \N__781\ : std_logic;
signal \N__778\ : std_logic;
signal \N__775\ : std_logic;
signal \N__772\ : std_logic;
signal \N__769\ : std_logic;
signal \N__766\ : std_logic;
signal \N__763\ : std_logic;
signal \N__760\ : std_logic;
signal \N__757\ : std_logic;
signal \N__754\ : std_logic;
signal \N__751\ : std_logic;
signal \N__748\ : std_logic;
signal \N__745\ : std_logic;
signal \N__742\ : std_logic;
signal \N__739\ : std_logic;
signal \N__736\ : std_logic;
signal \VCCG0\ : std_logic;
signal \INVrom_inst.ram0WCLKN_net\ : std_logic;
signal \INVrom_inst.ram0RCLKN_net\ : std_logic;
signal clk_c_g : std_logic;
signal cpu_addr_c_6 : std_logic;
signal cpu_addr_c_8 : std_logic;
signal cpu_addr_c_1 : std_logic;
signal \INVrom_inst.ram1WCLKN_net\ : std_logic;
signal cpu_addr_c_5 : std_logic;
signal cpu_addr_c_2 : std_logic;
signal \INVrom_inst.ram1RCLKN_net\ : std_logic;
signal cpu_addr_c_4 : std_logic;
signal cpu_addr_c_3 : std_logic;
signal cpu_addr_c_7 : std_logic;
signal \GNDG0\ : std_logic;
signal \rom_inst.data_out_x_1__3\ : std_logic;
signal \rom_inst.data_out_x_0__3\ : std_logic;
signal rom_dat_3 : std_logic;
signal \rom_inst.data_out_x_1__0\ : std_logic;
signal \rom_inst.data_out_x_0__0\ : std_logic;
signal rom_dat_0 : std_logic;
signal \rom_inst.data_out_x_1__1\ : std_logic;
signal \rom_inst.data_out_x_0__1\ : std_logic;
signal rom_dat_1 : std_logic;
signal \rom_inst.data_out_x_1__2\ : std_logic;
signal \rom_inst.data_out_x_0__2\ : std_logic;
signal rom_dat_2 : std_logic;
signal \rom_inst.data_out_x_1__4\ : std_logic;
signal \rom_inst.data_out_x_0__4\ : std_logic;
signal rom_dat_4 : std_logic;
signal \rom_inst.data_out_x_0__5\ : std_logic;
signal \rom_inst.data_out_x_1__5\ : std_logic;
signal rom_dat_5 : std_logic;
signal \rom_inst.data_out_x_1__6\ : std_logic;
signal \rom_inst.data_out_x_0__6\ : std_logic;
signal rom_dat_6 : std_logic;
signal \rom_inst.data_out_x_1__7\ : std_logic;
signal \rom_inst.data_out_x_0__7\ : std_logic;
signal cpu_addr_c_9 : std_logic;
signal rom_dat_7 : std_logic;
signal \CONSTANT_ZERO_NET\ : std_logic;
signal cpu_addr_c_0 : std_logic;
signal cpu_addr_c_i_0 : std_logic;
signal \CONSTANT_ONE_NET\ : std_logic;
signal cpu_ce_c : std_logic;
signal cpu_rw_c : std_logic;
signal cpu_m2_c : std_logic;
signal boot_on_c : std_logic;
signal rom_oe_i : std_logic;
signal \rom_oe_i_cascade_\ : std_logic;
signal rom_oe_i_i : std_logic;
signal \_gnd_net_\ : std_logic;

signal clk_wire : std_logic;
signal cpu_dat_wire : std_logic_vector(7 downto 0);
signal gpio_wire : std_logic_vector(3 downto 0);
signal cpu_addr_wire : std_logic_vector(14 downto 0);
signal spi_miso_wire : std_logic;
signal boot_on_wire : std_logic;
signal cpu_ce_wire : std_logic;
signal cpu_rw_wire : std_logic;
signal cpu_dir_wire : std_logic;
signal cpu_ex_wire : std_logic;
signal ice_sdo_wire : std_logic;
signal boot0_wire : std_logic;
signal cpu_m2_wire : std_logic;
signal mcu_rst_wire : std_logic;
signal \rom_inst.ram1_physical_RDATA_wire\ : std_logic_vector(15 downto 0);
signal \rom_inst.ram1_physical_RADDR_wire\ : std_logic_vector(10 downto 0);
signal \rom_inst.ram1_physical_WADDR_wire\ : std_logic_vector(10 downto 0);
signal \rom_inst.ram1_physical_MASK_wire\ : std_logic_vector(15 downto 0);
signal \rom_inst.ram1_physical_WDATA_wire\ : std_logic_vector(15 downto 0);
signal \rom_inst.ram0_physical_RDATA_wire\ : std_logic_vector(15 downto 0);
signal \rom_inst.ram0_physical_RADDR_wire\ : std_logic_vector(10 downto 0);
signal \rom_inst.ram0_physical_WADDR_wire\ : std_logic_vector(10 downto 0);
signal \rom_inst.ram0_physical_MASK_wire\ : std_logic_vector(15 downto 0);
signal \rom_inst.ram0_physical_WDATA_wire\ : std_logic_vector(15 downto 0);

begin
    clk_wire <= clk;
    cpu_dat <= cpu_dat_wire;
    gpio <= gpio_wire;
    cpu_addr_wire <= cpu_addr;
    spi_miso <= spi_miso_wire;
    boot_on_wire <= boot_on;
    cpu_ce_wire <= cpu_ce;
    cpu_rw_wire <= cpu_rw;
    cpu_dir <= cpu_dir_wire;
    cpu_ex <= cpu_ex_wire;
    ice_sdo <= ice_sdo_wire;
    boot0 <= boot0_wire;
    cpu_m2_wire <= cpu_m2;
    mcu_rst <= mcu_rst_wire;
    \rom_inst.data_out_x_1__7\ <= \rom_inst.ram1_physical_RDATA_wire\(14);
    \rom_inst.data_out_x_1__6\ <= \rom_inst.ram1_physical_RDATA_wire\(12);
    \rom_inst.data_out_x_1__5\ <= \rom_inst.ram1_physical_RDATA_wire\(10);
    \rom_inst.data_out_x_1__4\ <= \rom_inst.ram1_physical_RDATA_wire\(8);
    \rom_inst.data_out_x_1__3\ <= \rom_inst.ram1_physical_RDATA_wire\(6);
    \rom_inst.data_out_x_1__2\ <= \rom_inst.ram1_physical_RDATA_wire\(4);
    \rom_inst.data_out_x_1__1\ <= \rom_inst.ram1_physical_RDATA_wire\(2);
    \rom_inst.data_out_x_1__0\ <= \rom_inst.ram1_physical_RDATA_wire\(0);
    \rom_inst.ram1_physical_RADDR_wire\ <= '0'&'0'&\N__823\&\N__904\&\N__844\&\N__787\&\N__757\&\N__742\&\N__772\&\N__802\&\N__1354\;
    \rom_inst.ram1_physical_WADDR_wire\ <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0';
    \rom_inst.ram1_physical_MASK_wire\ <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0';
    \rom_inst.ram1_physical_WDATA_wire\ <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0';
    \rom_inst.data_out_x_0__7\ <= \rom_inst.ram0_physical_RDATA_wire\(14);
    \rom_inst.data_out_x_0__6\ <= \rom_inst.ram0_physical_RDATA_wire\(12);
    \rom_inst.data_out_x_0__5\ <= \rom_inst.ram0_physical_RDATA_wire\(10);
    \rom_inst.data_out_x_0__4\ <= \rom_inst.ram0_physical_RDATA_wire\(8);
    \rom_inst.data_out_x_0__3\ <= \rom_inst.ram0_physical_RDATA_wire\(6);
    \rom_inst.data_out_x_0__2\ <= \rom_inst.ram0_physical_RDATA_wire\(4);
    \rom_inst.data_out_x_0__1\ <= \rom_inst.ram0_physical_RDATA_wire\(2);
    \rom_inst.data_out_x_0__0\ <= \rom_inst.ram0_physical_RDATA_wire\(0);
    \rom_inst.ram0_physical_RADDR_wire\ <= '0'&'0'&\N__829\&\N__910\&\N__850\&\N__793\&\N__763\&\N__748\&\N__778\&\N__808\&\N__1360\;
    \rom_inst.ram0_physical_WADDR_wire\ <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0';
    \rom_inst.ram0_physical_MASK_wire\ <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0';
    \rom_inst.ram0_physical_WDATA_wire\ <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'0';

    \rom_inst.ram1_physical\ : SB_RAM40_4K
    generic map (
            INIT_0 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            WRITE_MODE => 1,
            READ_MODE => 1,
            INIT_F => "1000101000001000101010101010000000100000000000001010101010100000100010100000100010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_E => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_D => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_C => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_B => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_A => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_9 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_8 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_7 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_6 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_5 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_4 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_3 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_2 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_1 => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        )
    port map (
            RDATA => \rom_inst.ram1_physical_RDATA_wire\,
            RADDR => \rom_inst.ram1_physical_RADDR_wire\,
            WADDR => \rom_inst.ram1_physical_WADDR_wire\,
            MASK => \rom_inst.ram1_physical_MASK_wire\,
            WDATA => \rom_inst.ram1_physical_WDATA_wire\,
            RCLKE => 'H',
            RCLK => \INVrom_inst.ram1RCLKN_net\,
            RE => \N__1317\,
            WCLKE => \N__922\,
            WCLK => \INVrom_inst.ram1WCLKN_net\,
            WE => 'L'
        );

    \rom_inst.ram0_physical\ : SB_RAM40_4K
    generic map (
            WRITE_MODE => 1,
            READ_MODE => 1,
            INIT_F => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_E => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_D => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_C => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            INIT_B => "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000001010101010100000101010101010101",
            INIT_A => "0101010101000100000101000101000001010000010001000101000100000000000000000001010100000100000000000000010000000000010000000101000100000000000101000100010000000100000001000000000001000100010000010100000001010001000000000001010001000100010000010000000000000000",
            INIT_9 => "0000000000010100000001000000000000000101010101010100000001010001010101010100010101000100010000010000010000000000000000010000000000000100010100000000000000000100000000000000010000000100000000000101010001000000000001000101000001000100000000000101000100000000",
            INIT_8 => "0101010100000000010100000100000101000000010001000000010001000001010100010000000001010100010101010101000001000001000000000000000100000100010000010000000000000001010101010001010001000100010001000001000000000000010100010000000001010000010100010101010101010101",
            INIT_7 => "0001000001000001000000000100000001010101010101010001000000000000010101010100010001000100010100010101000001000100010100010000000000000000000101010000010000000000000001000000000001000000010100010000000001010000010001000000010000000100000000000100010001000001",
            INIT_6 => "0100000001010001000000000001010001000100010000010000000000000000000000000001010000000100000000000000010101010101010000000101000100000100000000000100010001000001010000000101000100000000000000010100010001000001000000000100010000000000000000000000010000000000",
            INIT_5 => "0000000000000000010000000101000101010101010001010100010001000001000001000000000000000001000000000000010001010000000000000000010000000000000001000000010000000000000000000001000000000100010100000001000001010000000000000000000001010001000000000101010100010101",
            INIT_4 => "0000000000010000010101000100000001000001010100010000000000000000000100010001000101010101010100000000010000000000010001010101000101000000010101000000000000000000010001000000010000000000000000000101010101010101010000010100010000010101010000000100010000000100",
            INIT_3 => "0001010001000001000101010100000100010101000001010001010001000101000101000101010100010101000101000001010100010001000101000000010000010100010101010001010001010000000001000000000000010000000101010001010001010101000101010000010000010000010000010001010000010101",
            INIT_2 => "0000010000000000000001000000000000010000010000010001000100010000000100010100010000000100000000000001000001000101000100010100010000010001000001000001000001000001000001000000000000010000010001010000010100000001000001010100000100000101000001000000010100000000",
            INIT_1 => "0000010000000000000001000000000000000101000000000000010100000000000001010000000100000100010101000000010000000000000101010001010000010100000100000001010000010001000101000000010100010100010101010001010001010101000101010001000000010000000001000001010001010101",
            INIT_0 => "0000010000000000000001000000000000000100000000000000010000000000000100000101010000000101010000000001010000010001000001000000000000010100010000010001010100010100000100000001000000010101000001000001010000010001000101010000010000010000000100010001010100010100"
        )
    port map (
            RDATA => \rom_inst.ram0_physical_RDATA_wire\,
            RADDR => \rom_inst.ram0_physical_RADDR_wire\,
            WADDR => \rom_inst.ram0_physical_WADDR_wire\,
            MASK => \rom_inst.ram0_physical_MASK_wire\,
            WDATA => \rom_inst.ram0_physical_WDATA_wire\,
            RCLKE => 'H',
            RCLK => \INVrom_inst.ram0RCLKN_net\,
            RE => \N__1329\,
            WCLKE => \N__921\,
            WCLK => \INVrom_inst.ram0WCLKN_net\,
            WE => 'L'
        );

    \clk_ibuf_gb_io_preiogbuf\ : PRE_IO_GBUF
    port map (
            PADSIGNALTOGLOBALBUFFER => \N__1676\,
            GLOBALBUFFEROUTPUT => clk_c_g
        );

    \clk_ibuf_gb_io_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1678\,
            DIN => \N__1677\,
            DOUT => \N__1676\,
            PACKAGEPIN => clk_wire
        );

    \clk_ibuf_gb_io_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1678\,
            PADOUT => \N__1677\,
            PADIN => \N__1676\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_5_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1667\,
            DIN => \N__1666\,
            DOUT => \N__1665\,
            PACKAGEPIN => cpu_dat_wire(5)
        );

    \cpu_dat_obuft_5_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1667\,
            PADOUT => \N__1666\,
            PADIN => \N__1665\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1206\,
            DIN0 => OPEN,
            DOUT0 => \N__1018\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \gpio_obuft_0_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1658\,
            DIN => \N__1657\,
            DOUT => \N__1656\,
            PACKAGEPIN => gpio_wire(0)
        );

    \gpio_obuft_0_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1658\,
            PADOUT => \N__1657\,
            PADIN => \N__1656\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_0_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1649\,
            DIN => \N__1648\,
            DOUT => \N__1647\,
            PACKAGEPIN => cpu_addr_wire(0)
        );

    \cpu_addr_ibuf_0_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1649\,
            PADOUT => \N__1648\,
            PADIN => \N__1647\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_0,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_2_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1640\,
            DIN => \N__1639\,
            DOUT => \N__1638\,
            PACKAGEPIN => cpu_dat_wire(2)
        );

    \cpu_dat_obuft_2_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1640\,
            PADOUT => \N__1639\,
            PADIN => \N__1638\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1219\,
            DIN0 => OPEN,
            DOUT0 => \N__1069\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_9_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1631\,
            DIN => \N__1630\,
            DOUT => \N__1629\,
            PACKAGEPIN => cpu_addr_wire(9)
        );

    \cpu_addr_ibuf_9_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1631\,
            PADOUT => \N__1630\,
            PADIN => \N__1629\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_9,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \gpio_obuft_2_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1622\,
            DIN => \N__1621\,
            DOUT => \N__1620\,
            PACKAGEPIN => gpio_wire(2)
        );

    \gpio_obuft_2_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1622\,
            PADOUT => \N__1621\,
            PADIN => \N__1620\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \spi_miso_obuft_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1613\,
            DIN => \N__1612\,
            DOUT => \N__1611\,
            PACKAGEPIN => spi_miso_wire
        );

    \spi_miso_obuft_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1613\,
            PADOUT => \N__1612\,
            PADIN => \N__1611\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \boot_on_ibuf_iopad\ : IO_PAD
    generic map (
            PULLUP => '1',
            IO_STANDARD => "SB_LVCMOS"
        )
    port map (
            OE => \N__1604\,
            DIN => \N__1603\,
            DOUT => \N__1602\,
            PACKAGEPIN => boot_on_wire
        );

    \boot_on_ibuf_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1604\,
            PADOUT => \N__1603\,
            PADIN => \N__1602\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => boot_on_c,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_0_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1595\,
            DIN => \N__1594\,
            DOUT => \N__1593\,
            PACKAGEPIN => cpu_dat_wire(0)
        );

    \cpu_dat_obuft_0_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1595\,
            PADOUT => \N__1594\,
            PADIN => \N__1593\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1217\,
            DIN0 => OPEN,
            DOUT0 => \N__1126\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_7_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1586\,
            DIN => \N__1585\,
            DOUT => \N__1584\,
            PACKAGEPIN => cpu_addr_wire(7)
        );

    \cpu_addr_ibuf_7_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1586\,
            PADOUT => \N__1585\,
            PADIN => \N__1584\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_7,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_4_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1577\,
            DIN => \N__1576\,
            DOUT => \N__1575\,
            PACKAGEPIN => cpu_addr_wire(4)
        );

    \cpu_addr_ibuf_4_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1577\,
            PADOUT => \N__1576\,
            PADIN => \N__1575\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_4,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_ce_ibuf_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1568\,
            DIN => \N__1567\,
            DOUT => \N__1566\,
            PACKAGEPIN => cpu_ce_wire
        );

    \cpu_ce_ibuf_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1568\,
            PADOUT => \N__1567\,
            PADIN => \N__1566\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_ce_c,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_6_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1559\,
            DIN => \N__1558\,
            DOUT => \N__1557\,
            PACKAGEPIN => cpu_dat_wire(6)
        );

    \cpu_dat_obuft_6_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1559\,
            PADOUT => \N__1558\,
            PADIN => \N__1557\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1172\,
            DIN0 => OPEN,
            DOUT0 => \N__994\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_rw_ibuf_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1550\,
            DIN => \N__1549\,
            DOUT => \N__1548\,
            PACKAGEPIN => cpu_rw_wire
        );

    \cpu_rw_ibuf_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1550\,
            PADOUT => \N__1549\,
            PADIN => \N__1548\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_rw_c,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_5_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1541\,
            DIN => \N__1540\,
            DOUT => \N__1539\,
            PACKAGEPIN => cpu_addr_wire(5)
        );

    \cpu_addr_ibuf_5_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1541\,
            PADOUT => \N__1540\,
            PADIN => \N__1539\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_5,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_7_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1532\,
            DIN => \N__1531\,
            DOUT => \N__1530\,
            PACKAGEPIN => cpu_dat_wire(7)
        );

    \cpu_dat_obuft_7_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1532\,
            PADOUT => \N__1531\,
            PADIN => \N__1530\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1173\,
            DIN0 => OPEN,
            DOUT0 => \N__931\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dir_obuft_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1523\,
            DIN => \N__1522\,
            DOUT => \N__1521\,
            PACKAGEPIN => cpu_dir_wire
        );

    \cpu_dir_obuft_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1523\,
            PADOUT => \N__1522\,
            PADIN => \N__1521\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1264\,
            DIN0 => OPEN,
            DOUT0 => \N__1339\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_2_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1514\,
            DIN => \N__1513\,
            DOUT => \N__1512\,
            PACKAGEPIN => cpu_addr_wire(2)
        );

    \cpu_addr_ibuf_2_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1514\,
            PADOUT => \N__1513\,
            PADIN => \N__1512\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_2,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_4_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1505\,
            DIN => \N__1504\,
            DOUT => \N__1503\,
            PACKAGEPIN => cpu_dat_wire(4)
        );

    \cpu_dat_obuft_4_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1505\,
            PADOUT => \N__1504\,
            PADIN => \N__1503\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1205\,
            DIN0 => OPEN,
            DOUT0 => \N__1042\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_ex_obuft_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1496\,
            DIN => \N__1495\,
            DOUT => \N__1494\,
            PACKAGEPIN => cpu_ex_wire
        );

    \cpu_ex_obuft_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1496\,
            PADOUT => \N__1495\,
            PADIN => \N__1494\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1257\,
            DIN0 => OPEN,
            DOUT0 => \N__1228\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \gpio_obuft_1_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1487\,
            DIN => \N__1486\,
            DOUT => \N__1485\,
            PACKAGEPIN => gpio_wire(1)
        );

    \gpio_obuft_1_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1487\,
            PADOUT => \N__1486\,
            PADIN => \N__1485\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \ice_sdo_obuft_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1478\,
            DIN => \N__1477\,
            DOUT => \N__1476\,
            PACKAGEPIN => ice_sdo_wire
        );

    \ice_sdo_obuft_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1478\,
            PADOUT => \N__1477\,
            PADIN => \N__1476\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_3_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1469\,
            DIN => \N__1468\,
            DOUT => \N__1467\,
            PACKAGEPIN => cpu_addr_wire(3)
        );

    \cpu_addr_ibuf_3_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1469\,
            PADOUT => \N__1468\,
            PADIN => \N__1467\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_3,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \boot0_obuft_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1460\,
            DIN => \N__1459\,
            DOUT => \N__1458\,
            PACKAGEPIN => boot0_wire
        );

    \boot0_obuft_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1460\,
            PADOUT => \N__1459\,
            PADIN => \N__1458\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_8_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1451\,
            DIN => \N__1450\,
            DOUT => \N__1449\,
            PACKAGEPIN => cpu_addr_wire(8)
        );

    \cpu_addr_ibuf_8_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1451\,
            PADOUT => \N__1450\,
            PADIN => \N__1449\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_8,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_m2_ibuf_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1442\,
            DIN => \N__1441\,
            DOUT => \N__1440\,
            PACKAGEPIN => cpu_m2_wire
        );

    \cpu_m2_ibuf_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1442\,
            PADOUT => \N__1441\,
            PADIN => \N__1440\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_m2_c,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \gpio_obuft_3_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1433\,
            DIN => \N__1432\,
            DOUT => \N__1431\,
            PACKAGEPIN => gpio_wire(3)
        );

    \gpio_obuft_3_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1433\,
            PADOUT => \N__1432\,
            PADIN => \N__1431\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_1_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1424\,
            DIN => \N__1423\,
            DOUT => \N__1422\,
            PACKAGEPIN => cpu_addr_wire(1)
        );

    \cpu_addr_ibuf_1_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1424\,
            PADOUT => \N__1423\,
            PADIN => \N__1422\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_1,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_3_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1415\,
            DIN => \N__1414\,
            DOUT => \N__1413\,
            PACKAGEPIN => cpu_dat_wire(3)
        );

    \cpu_dat_obuft_3_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1415\,
            PADOUT => \N__1414\,
            PADIN => \N__1413\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1210\,
            DIN0 => OPEN,
            DOUT0 => \N__874\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_addr_ibuf_6_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1406\,
            DIN => \N__1405\,
            DOUT => \N__1404\,
            PACKAGEPIN => cpu_addr_wire(6)
        );

    \cpu_addr_ibuf_6_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "000001"
        )
    port map (
            PADOEN => \N__1406\,
            PADOUT => \N__1405\,
            PADIN => \N__1404\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => cpu_addr_c_6,
            DOUT0 => '0',
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \mcu_rst_obuft_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1397\,
            DIN => \N__1396\,
            DOUT => \N__1395\,
            PACKAGEPIN => mcu_rst_wire
        );

    \mcu_rst_obuft_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1397\,
            PADOUT => \N__1396\,
            PADIN => \N__1395\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => '0',
            DIN0 => OPEN,
            DOUT0 => \GNDG0\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \cpu_dat_obuft_1_iopad\ : IO_PAD
    generic map (
            IO_STANDARD => "SB_LVCMOS",
            PULLUP => '0'
        )
    port map (
            OE => \N__1388\,
            DIN => \N__1387\,
            DOUT => \N__1386\,
            PACKAGEPIN => cpu_dat_wire(1)
        );

    \cpu_dat_obuft_1_preio\ : PRE_IO
    generic map (
            NEG_TRIGGER => '0',
            PIN_TYPE => "101001"
        )
    port map (
            PADOEN => \N__1388\,
            PADOUT => \N__1387\,
            PADIN => \N__1386\,
            CLOCKENABLE => 'H',
            DOUT1 => '0',
            OUTPUTENABLE => \N__1218\,
            DIN0 => OPEN,
            DOUT0 => \N__1096\,
            INPUTCLK => '0',
            LATCHINPUTVALUE => '0',
            DIN1 => OPEN,
            OUTPUTCLK => '0'
        );

    \I__266\ : InMux
    port map (
            O => \N__1369\,
            I => \N__1366\
        );

    \I__265\ : LocalMux
    port map (
            O => \N__1366\,
            I => \N__1363\
        );

    \I__264\ : Odrv4
    port map (
            O => \N__1363\,
            I => cpu_addr_c_0
        );

    \I__263\ : CascadeMux
    port map (
            O => \N__1360\,
            I => \N__1357\
        );

    \I__262\ : CascadeBuf
    port map (
            O => \N__1357\,
            I => \N__1354\
        );

    \I__261\ : CascadeMux
    port map (
            O => \N__1354\,
            I => \N__1351\
        );

    \I__260\ : InMux
    port map (
            O => \N__1351\,
            I => \N__1348\
        );

    \I__259\ : LocalMux
    port map (
            O => \N__1348\,
            I => \N__1345\
        );

    \I__258\ : Span4Mux_s1_v
    port map (
            O => \N__1345\,
            I => \N__1342\
        );

    \I__257\ : Odrv4
    port map (
            O => \N__1342\,
            I => cpu_addr_c_i_0
        );

    \I__256\ : IoInMux
    port map (
            O => \N__1339\,
            I => \N__1336\
        );

    \I__255\ : LocalMux
    port map (
            O => \N__1336\,
            I => \N__1333\
        );

    \I__254\ : IoSpan4Mux
    port map (
            O => \N__1333\,
            I => \N__1330\
        );

    \I__253\ : IoSpan4Mux
    port map (
            O => \N__1330\,
            I => \N__1326\
        );

    \I__252\ : SRMux
    port map (
            O => \N__1329\,
            I => \N__1323\
        );

    \I__251\ : Span4Mux_s1_h
    port map (
            O => \N__1326\,
            I => \N__1318\
        );

    \I__250\ : LocalMux
    port map (
            O => \N__1323\,
            I => \N__1318\
        );

    \I__249\ : Span4Mux_v
    port map (
            O => \N__1318\,
            I => \N__1314\
        );

    \I__248\ : SRMux
    port map (
            O => \N__1317\,
            I => \N__1311\
        );

    \I__247\ : Span4Mux_s1_h
    port map (
            O => \N__1314\,
            I => \N__1306\
        );

    \I__246\ : LocalMux
    port map (
            O => \N__1311\,
            I => \N__1306\
        );

    \I__245\ : Span4Mux_s1_v
    port map (
            O => \N__1306\,
            I => \N__1303\
        );

    \I__244\ : Sp12to4
    port map (
            O => \N__1303\,
            I => \N__1300\
        );

    \I__243\ : Odrv12
    port map (
            O => \N__1300\,
            I => \CONSTANT_ONE_NET\
        );

    \I__242\ : InMux
    port map (
            O => \N__1297\,
            I => \N__1294\
        );

    \I__241\ : LocalMux
    port map (
            O => \N__1294\,
            I => \N__1291\
        );

    \I__240\ : Odrv4
    port map (
            O => \N__1291\,
            I => cpu_ce_c
        );

    \I__239\ : InMux
    port map (
            O => \N__1288\,
            I => \N__1285\
        );

    \I__238\ : LocalMux
    port map (
            O => \N__1285\,
            I => cpu_rw_c
        );

    \I__237\ : CascadeMux
    port map (
            O => \N__1282\,
            I => \N__1279\
        );

    \I__236\ : InMux
    port map (
            O => \N__1279\,
            I => \N__1276\
        );

    \I__235\ : LocalMux
    port map (
            O => \N__1276\,
            I => \N__1273\
        );

    \I__234\ : Span4Mux_s1_h
    port map (
            O => \N__1273\,
            I => \N__1270\
        );

    \I__233\ : IoSpan4Mux
    port map (
            O => \N__1270\,
            I => \N__1267\
        );

    \I__232\ : Odrv4
    port map (
            O => \N__1267\,
            I => cpu_m2_c
        );

    \I__231\ : IoInMux
    port map (
            O => \N__1264\,
            I => \N__1261\
        );

    \I__230\ : LocalMux
    port map (
            O => \N__1261\,
            I => \N__1258\
        );

    \I__229\ : IoSpan4Mux
    port map (
            O => \N__1258\,
            I => \N__1253\
        );

    \I__228\ : IoInMux
    port map (
            O => \N__1257\,
            I => \N__1250\
        );

    \I__227\ : InMux
    port map (
            O => \N__1256\,
            I => \N__1247\
        );

    \I__226\ : IoSpan4Mux
    port map (
            O => \N__1253\,
            I => \N__1244\
        );

    \I__225\ : LocalMux
    port map (
            O => \N__1250\,
            I => \N__1239\
        );

    \I__224\ : LocalMux
    port map (
            O => \N__1247\,
            I => \N__1239\
        );

    \I__223\ : IoSpan4Mux
    port map (
            O => \N__1244\,
            I => \N__1234\
        );

    \I__222\ : IoSpan4Mux
    port map (
            O => \N__1239\,
            I => \N__1234\
        );

    \I__221\ : IoSpan4Mux
    port map (
            O => \N__1234\,
            I => \N__1231\
        );

    \I__220\ : Odrv4
    port map (
            O => \N__1231\,
            I => boot_on_c
        );

    \I__219\ : IoInMux
    port map (
            O => \N__1228\,
            I => \N__1225\
        );

    \I__218\ : LocalMux
    port map (
            O => \N__1225\,
            I => rom_oe_i
        );

    \I__217\ : CascadeMux
    port map (
            O => \N__1222\,
            I => \rom_oe_i_cascade_\
        );

    \I__216\ : IoInMux
    port map (
            O => \N__1219\,
            I => \N__1214\
        );

    \I__215\ : IoInMux
    port map (
            O => \N__1218\,
            I => \N__1211\
        );

    \I__214\ : IoInMux
    port map (
            O => \N__1217\,
            I => \N__1207\
        );

    \I__213\ : LocalMux
    port map (
            O => \N__1214\,
            I => \N__1200\
        );

    \I__212\ : LocalMux
    port map (
            O => \N__1211\,
            I => \N__1200\
        );

    \I__211\ : IoInMux
    port map (
            O => \N__1210\,
            I => \N__1197\
        );

    \I__210\ : LocalMux
    port map (
            O => \N__1207\,
            I => \N__1194\
        );

    \I__209\ : IoInMux
    port map (
            O => \N__1206\,
            I => \N__1191\
        );

    \I__208\ : IoInMux
    port map (
            O => \N__1205\,
            I => \N__1188\
        );

    \I__207\ : Span4Mux_s1_h
    port map (
            O => \N__1200\,
            I => \N__1185\
        );

    \I__206\ : LocalMux
    port map (
            O => \N__1197\,
            I => \N__1182\
        );

    \I__205\ : Span4Mux_s0_h
    port map (
            O => \N__1194\,
            I => \N__1179\
        );

    \I__204\ : LocalMux
    port map (
            O => \N__1191\,
            I => \N__1174\
        );

    \I__203\ : LocalMux
    port map (
            O => \N__1188\,
            I => \N__1174\
        );

    \I__202\ : Span4Mux_v
    port map (
            O => \N__1185\,
            I => \N__1169\
        );

    \I__201\ : Span4Mux_s0_h
    port map (
            O => \N__1182\,
            I => \N__1166\
        );

    \I__200\ : Span4Mux_v
    port map (
            O => \N__1179\,
            I => \N__1161\
        );

    \I__199\ : Span4Mux_s0_h
    port map (
            O => \N__1174\,
            I => \N__1161\
        );

    \I__198\ : IoInMux
    port map (
            O => \N__1173\,
            I => \N__1158\
        );

    \I__197\ : IoInMux
    port map (
            O => \N__1172\,
            I => \N__1155\
        );

    \I__196\ : Odrv4
    port map (
            O => \N__1169\,
            I => rom_oe_i_i
        );

    \I__195\ : Odrv4
    port map (
            O => \N__1166\,
            I => rom_oe_i_i
        );

    \I__194\ : Odrv4
    port map (
            O => \N__1161\,
            I => rom_oe_i_i
        );

    \I__193\ : LocalMux
    port map (
            O => \N__1158\,
            I => rom_oe_i_i
        );

    \I__192\ : LocalMux
    port map (
            O => \N__1155\,
            I => rom_oe_i_i
        );

    \I__191\ : InMux
    port map (
            O => \N__1144\,
            I => \N__1141\
        );

    \I__190\ : LocalMux
    port map (
            O => \N__1141\,
            I => \N__1138\
        );

    \I__189\ : Span4Mux_v
    port map (
            O => \N__1138\,
            I => \N__1135\
        );

    \I__188\ : Odrv4
    port map (
            O => \N__1135\,
            I => \rom_inst.data_out_x_1__0\
        );

    \I__187\ : InMux
    port map (
            O => \N__1132\,
            I => \N__1129\
        );

    \I__186\ : LocalMux
    port map (
            O => \N__1129\,
            I => \rom_inst.data_out_x_0__0\
        );

    \I__185\ : IoInMux
    port map (
            O => \N__1126\,
            I => \N__1123\
        );

    \I__184\ : LocalMux
    port map (
            O => \N__1123\,
            I => \N__1120\
        );

    \I__183\ : Span4Mux_s1_h
    port map (
            O => \N__1120\,
            I => \N__1117\
        );

    \I__182\ : Odrv4
    port map (
            O => \N__1117\,
            I => rom_dat_0
        );

    \I__181\ : InMux
    port map (
            O => \N__1114\,
            I => \N__1111\
        );

    \I__180\ : LocalMux
    port map (
            O => \N__1111\,
            I => \N__1108\
        );

    \I__179\ : Span12Mux_s2_h
    port map (
            O => \N__1108\,
            I => \N__1105\
        );

    \I__178\ : Odrv12
    port map (
            O => \N__1105\,
            I => \rom_inst.data_out_x_1__1\
        );

    \I__177\ : InMux
    port map (
            O => \N__1102\,
            I => \N__1099\
        );

    \I__176\ : LocalMux
    port map (
            O => \N__1099\,
            I => \rom_inst.data_out_x_0__1\
        );

    \I__175\ : IoInMux
    port map (
            O => \N__1096\,
            I => \N__1093\
        );

    \I__174\ : LocalMux
    port map (
            O => \N__1093\,
            I => \N__1090\
        );

    \I__173\ : IoSpan4Mux
    port map (
            O => \N__1090\,
            I => \N__1087\
        );

    \I__172\ : Odrv4
    port map (
            O => \N__1087\,
            I => rom_dat_1
        );

    \I__171\ : InMux
    port map (
            O => \N__1084\,
            I => \N__1081\
        );

    \I__170\ : LocalMux
    port map (
            O => \N__1081\,
            I => \N__1078\
        );

    \I__169\ : Odrv4
    port map (
            O => \N__1078\,
            I => \rom_inst.data_out_x_1__2\
        );

    \I__168\ : InMux
    port map (
            O => \N__1075\,
            I => \N__1072\
        );

    \I__167\ : LocalMux
    port map (
            O => \N__1072\,
            I => \rom_inst.data_out_x_0__2\
        );

    \I__166\ : IoInMux
    port map (
            O => \N__1069\,
            I => \N__1066\
        );

    \I__165\ : LocalMux
    port map (
            O => \N__1066\,
            I => \N__1063\
        );

    \I__164\ : Span4Mux_s1_h
    port map (
            O => \N__1063\,
            I => \N__1060\
        );

    \I__163\ : Odrv4
    port map (
            O => \N__1060\,
            I => rom_dat_2
        );

    \I__162\ : InMux
    port map (
            O => \N__1057\,
            I => \N__1054\
        );

    \I__161\ : LocalMux
    port map (
            O => \N__1054\,
            I => \N__1051\
        );

    \I__160\ : Odrv4
    port map (
            O => \N__1051\,
            I => \rom_inst.data_out_x_1__4\
        );

    \I__159\ : InMux
    port map (
            O => \N__1048\,
            I => \N__1045\
        );

    \I__158\ : LocalMux
    port map (
            O => \N__1045\,
            I => \rom_inst.data_out_x_0__4\
        );

    \I__157\ : IoInMux
    port map (
            O => \N__1042\,
            I => \N__1039\
        );

    \I__156\ : LocalMux
    port map (
            O => \N__1039\,
            I => \N__1036\
        );

    \I__155\ : Odrv4
    port map (
            O => \N__1036\,
            I => rom_dat_4
        );

    \I__154\ : InMux
    port map (
            O => \N__1033\,
            I => \N__1030\
        );

    \I__153\ : LocalMux
    port map (
            O => \N__1030\,
            I => \rom_inst.data_out_x_0__5\
        );

    \I__152\ : InMux
    port map (
            O => \N__1027\,
            I => \N__1024\
        );

    \I__151\ : LocalMux
    port map (
            O => \N__1024\,
            I => \N__1021\
        );

    \I__150\ : Odrv4
    port map (
            O => \N__1021\,
            I => \rom_inst.data_out_x_1__5\
        );

    \I__149\ : IoInMux
    port map (
            O => \N__1018\,
            I => \N__1015\
        );

    \I__148\ : LocalMux
    port map (
            O => \N__1015\,
            I => \N__1012\
        );

    \I__147\ : Odrv4
    port map (
            O => \N__1012\,
            I => rom_dat_5
        );

    \I__146\ : InMux
    port map (
            O => \N__1009\,
            I => \N__1006\
        );

    \I__145\ : LocalMux
    port map (
            O => \N__1006\,
            I => \N__1003\
        );

    \I__144\ : Odrv4
    port map (
            O => \N__1003\,
            I => \rom_inst.data_out_x_1__6\
        );

    \I__143\ : InMux
    port map (
            O => \N__1000\,
            I => \N__997\
        );

    \I__142\ : LocalMux
    port map (
            O => \N__997\,
            I => \rom_inst.data_out_x_0__6\
        );

    \I__141\ : IoInMux
    port map (
            O => \N__994\,
            I => \N__991\
        );

    \I__140\ : LocalMux
    port map (
            O => \N__991\,
            I => \N__988\
        );

    \I__139\ : Odrv4
    port map (
            O => \N__988\,
            I => rom_dat_6
        );

    \I__138\ : InMux
    port map (
            O => \N__985\,
            I => \N__982\
        );

    \I__137\ : LocalMux
    port map (
            O => \N__982\,
            I => \N__979\
        );

    \I__136\ : Odrv4
    port map (
            O => \N__979\,
            I => \rom_inst.data_out_x_1__7\
        );

    \I__135\ : InMux
    port map (
            O => \N__976\,
            I => \N__973\
        );

    \I__134\ : LocalMux
    port map (
            O => \N__973\,
            I => \rom_inst.data_out_x_0__7\
        );

    \I__133\ : InMux
    port map (
            O => \N__970\,
            I => \N__958\
        );

    \I__132\ : InMux
    port map (
            O => \N__969\,
            I => \N__958\
        );

    \I__131\ : InMux
    port map (
            O => \N__968\,
            I => \N__945\
        );

    \I__130\ : InMux
    port map (
            O => \N__967\,
            I => \N__945\
        );

    \I__129\ : InMux
    port map (
            O => \N__966\,
            I => \N__945\
        );

    \I__128\ : InMux
    port map (
            O => \N__965\,
            I => \N__945\
        );

    \I__127\ : InMux
    port map (
            O => \N__964\,
            I => \N__945\
        );

    \I__126\ : InMux
    port map (
            O => \N__963\,
            I => \N__945\
        );

    \I__125\ : LocalMux
    port map (
            O => \N__958\,
            I => \N__940\
        );

    \I__124\ : LocalMux
    port map (
            O => \N__945\,
            I => \N__940\
        );

    \I__123\ : Span4Mux_v
    port map (
            O => \N__940\,
            I => \N__937\
        );

    \I__122\ : Span4Mux_v
    port map (
            O => \N__937\,
            I => \N__934\
        );

    \I__121\ : Odrv4
    port map (
            O => \N__934\,
            I => cpu_addr_c_9
        );

    \I__120\ : IoInMux
    port map (
            O => \N__931\,
            I => \N__928\
        );

    \I__119\ : LocalMux
    port map (
            O => \N__928\,
            I => \N__925\
        );

    \I__118\ : Odrv12
    port map (
            O => \N__925\,
            I => rom_dat_7
        );

    \I__117\ : CEMux
    port map (
            O => \N__922\,
            I => \N__918\
        );

    \I__116\ : CEMux
    port map (
            O => \N__921\,
            I => \N__915\
        );

    \I__115\ : LocalMux
    port map (
            O => \N__918\,
            I => \CONSTANT_ZERO_NET\
        );

    \I__114\ : LocalMux
    port map (
            O => \N__915\,
            I => \CONSTANT_ZERO_NET\
        );

    \I__113\ : CascadeMux
    port map (
            O => \N__910\,
            I => \N__907\
        );

    \I__112\ : CascadeBuf
    port map (
            O => \N__907\,
            I => \N__904\
        );

    \I__111\ : CascadeMux
    port map (
            O => \N__904\,
            I => \N__901\
        );

    \I__110\ : InMux
    port map (
            O => \N__901\,
            I => \N__898\
        );

    \I__109\ : LocalMux
    port map (
            O => \N__898\,
            I => \N__895\
        );

    \I__108\ : Span4Mux_h
    port map (
            O => \N__895\,
            I => \N__892\
        );

    \I__107\ : Odrv4
    port map (
            O => \N__892\,
            I => cpu_addr_c_7
        );

    \I__106\ : InMux
    port map (
            O => \N__889\,
            I => \N__886\
        );

    \I__105\ : LocalMux
    port map (
            O => \N__886\,
            I => \N__883\
        );

    \I__104\ : Odrv4
    port map (
            O => \N__883\,
            I => \rom_inst.data_out_x_1__3\
        );

    \I__103\ : InMux
    port map (
            O => \N__880\,
            I => \N__877\
        );

    \I__102\ : LocalMux
    port map (
            O => \N__877\,
            I => \rom_inst.data_out_x_0__3\
        );

    \I__101\ : IoInMux
    port map (
            O => \N__874\,
            I => \N__871\
        );

    \I__100\ : LocalMux
    port map (
            O => \N__871\,
            I => \N__868\
        );

    \I__99\ : IoSpan4Mux
    port map (
            O => \N__868\,
            I => \N__865\
        );

    \I__98\ : Odrv4
    port map (
            O => \N__865\,
            I => rom_dat_3
        );

    \I__97\ : ClkMux
    port map (
            O => \N__862\,
            I => \N__856\
        );

    \I__96\ : ClkMux
    port map (
            O => \N__861\,
            I => \N__856\
        );

    \I__95\ : GlobalMux
    port map (
            O => \N__856\,
            I => \N__853\
        );

    \I__94\ : gio2CtrlBuf
    port map (
            O => \N__853\,
            I => clk_c_g
        );

    \I__93\ : CascadeMux
    port map (
            O => \N__850\,
            I => \N__847\
        );

    \I__92\ : CascadeBuf
    port map (
            O => \N__847\,
            I => \N__844\
        );

    \I__91\ : CascadeMux
    port map (
            O => \N__844\,
            I => \N__841\
        );

    \I__90\ : InMux
    port map (
            O => \N__841\,
            I => \N__838\
        );

    \I__89\ : LocalMux
    port map (
            O => \N__838\,
            I => \N__835\
        );

    \I__88\ : IoSpan4Mux
    port map (
            O => \N__835\,
            I => \N__832\
        );

    \I__87\ : Odrv4
    port map (
            O => \N__832\,
            I => cpu_addr_c_6
        );

    \I__86\ : CascadeMux
    port map (
            O => \N__829\,
            I => \N__826\
        );

    \I__85\ : CascadeBuf
    port map (
            O => \N__826\,
            I => \N__823\
        );

    \I__84\ : CascadeMux
    port map (
            O => \N__823\,
            I => \N__820\
        );

    \I__83\ : InMux
    port map (
            O => \N__820\,
            I => \N__817\
        );

    \I__82\ : LocalMux
    port map (
            O => \N__817\,
            I => \N__814\
        );

    \I__81\ : Span12Mux_v
    port map (
            O => \N__814\,
            I => \N__811\
        );

    \I__80\ : Odrv12
    port map (
            O => \N__811\,
            I => cpu_addr_c_8
        );

    \I__79\ : CascadeMux
    port map (
            O => \N__808\,
            I => \N__805\
        );

    \I__78\ : CascadeBuf
    port map (
            O => \N__805\,
            I => \N__802\
        );

    \I__77\ : CascadeMux
    port map (
            O => \N__802\,
            I => \N__799\
        );

    \I__76\ : InMux
    port map (
            O => \N__799\,
            I => \N__796\
        );

    \I__75\ : LocalMux
    port map (
            O => \N__796\,
            I => cpu_addr_c_1
        );

    \I__74\ : CascadeMux
    port map (
            O => \N__793\,
            I => \N__790\
        );

    \I__73\ : CascadeBuf
    port map (
            O => \N__790\,
            I => \N__787\
        );

    \I__72\ : CascadeMux
    port map (
            O => \N__787\,
            I => \N__784\
        );

    \I__71\ : InMux
    port map (
            O => \N__784\,
            I => \N__781\
        );

    \I__70\ : LocalMux
    port map (
            O => \N__781\,
            I => cpu_addr_c_5
        );

    \I__69\ : CascadeMux
    port map (
            O => \N__778\,
            I => \N__775\
        );

    \I__68\ : CascadeBuf
    port map (
            O => \N__775\,
            I => \N__772\
        );

    \I__67\ : CascadeMux
    port map (
            O => \N__772\,
            I => \N__769\
        );

    \I__66\ : InMux
    port map (
            O => \N__769\,
            I => \N__766\
        );

    \I__65\ : LocalMux
    port map (
            O => \N__766\,
            I => cpu_addr_c_2
        );

    \I__64\ : CascadeMux
    port map (
            O => \N__763\,
            I => \N__760\
        );

    \I__63\ : CascadeBuf
    port map (
            O => \N__760\,
            I => \N__757\
        );

    \I__62\ : CascadeMux
    port map (
            O => \N__757\,
            I => \N__754\
        );

    \I__61\ : InMux
    port map (
            O => \N__754\,
            I => \N__751\
        );

    \I__60\ : LocalMux
    port map (
            O => \N__751\,
            I => cpu_addr_c_4
        );

    \I__59\ : CascadeMux
    port map (
            O => \N__748\,
            I => \N__745\
        );

    \I__58\ : CascadeBuf
    port map (
            O => \N__745\,
            I => \N__742\
        );

    \I__57\ : CascadeMux
    port map (
            O => \N__742\,
            I => \N__739\
        );

    \I__56\ : InMux
    port map (
            O => \N__739\,
            I => \N__736\
        );

    \I__55\ : LocalMux
    port map (
            O => \N__736\,
            I => cpu_addr_c_3
        );

    \INVrom_inst.ram1WCLKN\ : INV
    port map (
            O => \INVrom_inst.ram1WCLKN_net\,
            I => \GNDG0\
        );

    \INVrom_inst.ram1RCLKN\ : INV
    port map (
            O => \INVrom_inst.ram1RCLKN_net\,
            I => \N__861\
        );

    \INVrom_inst.ram0WCLKN\ : INV
    port map (
            O => \INVrom_inst.ram0WCLKN_net\,
            I => \GNDG0\
        );

    \INVrom_inst.ram0RCLKN\ : INV
    port map (
            O => \INVrom_inst.ram0RCLKN_net\,
            I => \N__862\
        );

    \VCC\ : VCC
    port map (
            Y => \VCCG0\
        );

    \GND\ : GND
    port map (
            Y => \GNDG0\
        );

    \GND_Inst\ : GND
    port map (
            Y => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_2_LC_11_13_0\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1101110110001000"
        )
    port map (
            in0 => \N__965\,
            in1 => \N__889\,
            in2 => \_gnd_net_\,
            in3 => \N__880\,
            lcout => rom_dat_3,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_LC_11_13_2\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1101110110001000"
        )
    port map (
            in0 => \N__968\,
            in1 => \N__1144\,
            in2 => \_gnd_net_\,
            in3 => \N__1132\,
            lcout => rom_dat_0,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_0_LC_11_13_3\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1010101011001100"
        )
    port map (
            in0 => \N__1114\,
            in1 => \N__1102\,
            in2 => \_gnd_net_\,
            in3 => \N__963\,
            lcout => rom_dat_1,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_1_LC_11_13_4\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1101110110001000"
        )
    port map (
            in0 => \N__964\,
            in1 => \N__1084\,
            in2 => \_gnd_net_\,
            in3 => \N__1075\,
            lcout => rom_dat_2,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_3_LC_11_13_6\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1101110110001000"
        )
    port map (
            in0 => \N__966\,
            in1 => \N__1057\,
            in2 => \_gnd_net_\,
            in3 => \N__1048\,
            lcout => rom_dat_4,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_4_LC_11_13_7\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1100110010101010"
        )
    port map (
            in0 => \N__1033\,
            in1 => \N__1027\,
            in2 => \_gnd_net_\,
            in3 => \N__967\,
            lcout => rom_dat_5,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_5_LC_11_14_0\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1101110110001000"
        )
    port map (
            in0 => \N__969\,
            in1 => \N__1009\,
            in2 => \_gnd_net_\,
            in3 => \N__1000\,
            lcout => rom_dat_6,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \rom_inst.ram0_RNIBF5F_6_LC_11_14_1\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1010101011001100"
        )
    port map (
            in0 => \N__985\,
            in1 => \N__976\,
            in2 => \_gnd_net_\,
            in3 => \N__970\,
            lcout => rom_dat_7,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \CONSTANT_ZERO_LUT4_LC_11_14_3\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "0000000000000000"
        )
    port map (
            in0 => \_gnd_net_\,
            in1 => \_gnd_net_\,
            in2 => \_gnd_net_\,
            in3 => \_gnd_net_\,
            lcout => \CONSTANT_ZERO_NET\,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \cpu_addr_ibuf_RNIFFNB_0_LC_12_15_0\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "0000000011111111"
        )
    port map (
            in0 => \_gnd_net_\,
            in1 => \_gnd_net_\,
            in2 => \_gnd_net_\,
            in3 => \N__1369\,
            lcout => cpu_addr_c_i_0,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \CONSTANT_ONE_LUT4_LC_12_15_2\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1111111111111111"
        )
    port map (
            in0 => \_gnd_net_\,
            in1 => \_gnd_net_\,
            in2 => \_gnd_net_\,
            in3 => \_gnd_net_\,
            lcout => \CONSTANT_ONE_NET\,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \cpu_ce_ibuf_RNI9TA51_LC_12_15_6\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "1011111111111111"
        )
    port map (
            in0 => \N__1297\,
            in1 => \N__1288\,
            in2 => \N__1282\,
            in3 => \N__1256\,
            lcout => rom_oe_i,
            ltout => \rom_oe_i_cascade_\,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );

    \cpu_ce_ibuf_RNI9TA51_0_LC_12_15_7\ : LogicCell40
    generic map (
            C_ON => '0',
            SEQ_MODE => "0000",
            LUT_INIT => "0000111100001111"
        )
    port map (
            in0 => \_gnd_net_\,
            in1 => \_gnd_net_\,
            in2 => \N__1222\,
            in3 => \_gnd_net_\,
            lcout => rom_oe_i_i,
            ltout => OPEN,
            carryin => \_gnd_net_\,
            carryout => OPEN,
            clk => \_gnd_net_\,
            ce => 'H',
            sr => \_gnd_net_\
        );
end \INTERFACE\;
