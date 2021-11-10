// ******************************************************************************

// iCEcube Netlister

// Version:            2017.08.27940

// Build Date:         Sep 11 2017 17:30:03

// File Generated:     Sep 16 2019 00:32:54

// Purpose:            Post-Route Verilog/VHDL netlist for timing simulation

// Copyright (C) 2006-2010 by Lattice Semiconductor Corp. All rights reserved.

// ******************************************************************************

// Verilog file for cell "top" view "INTERFACE"

module top (
    cpu_addr,
    cpu_dat,
    gpio,
    spi_mosi,
    cpu_ex,
    cpu_ce,
    cpu_dir,
    ice_ss,
    ice_sdo,
    ice_sck,
    boot0,
    spi_miso,
    cpu_rw,
    clk,
    spi_clk,
    ice_sdi,
    mcu_rst,
    boot_on,
    spi_ss,
    cpu_m2,
    cpu_irq);

    input [14:0] cpu_addr;
    output [7:0] cpu_dat;
    output [3:0] gpio;
    input spi_mosi;
    output cpu_ex;
    input cpu_ce;
    output cpu_dir;
    input ice_ss;
    output ice_sdo;
    input ice_sck;
    output boot0;
    output spi_miso;
    input cpu_rw;
    input clk;
    input spi_clk;
    input ice_sdi;
    output mcu_rst;
    input boot_on;
    input spi_ss;
    input cpu_m2;
    input cpu_irq;

    wire N__1678;
    wire N__1677;
    wire N__1676;
    wire N__1667;
    wire N__1666;
    wire N__1665;
    wire N__1658;
    wire N__1657;
    wire N__1656;
    wire N__1649;
    wire N__1648;
    wire N__1647;
    wire N__1640;
    wire N__1639;
    wire N__1638;
    wire N__1631;
    wire N__1630;
    wire N__1629;
    wire N__1622;
    wire N__1621;
    wire N__1620;
    wire N__1613;
    wire N__1612;
    wire N__1611;
    wire N__1604;
    wire N__1603;
    wire N__1602;
    wire N__1595;
    wire N__1594;
    wire N__1593;
    wire N__1586;
    wire N__1585;
    wire N__1584;
    wire N__1577;
    wire N__1576;
    wire N__1575;
    wire N__1568;
    wire N__1567;
    wire N__1566;
    wire N__1559;
    wire N__1558;
    wire N__1557;
    wire N__1550;
    wire N__1549;
    wire N__1548;
    wire N__1541;
    wire N__1540;
    wire N__1539;
    wire N__1532;
    wire N__1531;
    wire N__1530;
    wire N__1523;
    wire N__1522;
    wire N__1521;
    wire N__1514;
    wire N__1513;
    wire N__1512;
    wire N__1505;
    wire N__1504;
    wire N__1503;
    wire N__1496;
    wire N__1495;
    wire N__1494;
    wire N__1487;
    wire N__1486;
    wire N__1485;
    wire N__1478;
    wire N__1477;
    wire N__1476;
    wire N__1469;
    wire N__1468;
    wire N__1467;
    wire N__1460;
    wire N__1459;
    wire N__1458;
    wire N__1451;
    wire N__1450;
    wire N__1449;
    wire N__1442;
    wire N__1441;
    wire N__1440;
    wire N__1433;
    wire N__1432;
    wire N__1431;
    wire N__1424;
    wire N__1423;
    wire N__1422;
    wire N__1415;
    wire N__1414;
    wire N__1413;
    wire N__1406;
    wire N__1405;
    wire N__1404;
    wire N__1397;
    wire N__1396;
    wire N__1395;
    wire N__1388;
    wire N__1387;
    wire N__1386;
    wire N__1369;
    wire N__1366;
    wire N__1363;
    wire N__1360;
    wire N__1357;
    wire N__1354;
    wire N__1351;
    wire N__1348;
    wire N__1345;
    wire N__1342;
    wire N__1339;
    wire N__1336;
    wire N__1333;
    wire N__1330;
    wire N__1329;
    wire N__1326;
    wire N__1323;
    wire N__1318;
    wire N__1317;
    wire N__1314;
    wire N__1311;
    wire N__1306;
    wire N__1303;
    wire N__1300;
    wire N__1297;
    wire N__1294;
    wire N__1291;
    wire N__1288;
    wire N__1285;
    wire N__1282;
    wire N__1279;
    wire N__1276;
    wire N__1273;
    wire N__1270;
    wire N__1267;
    wire N__1264;
    wire N__1261;
    wire N__1258;
    wire N__1257;
    wire N__1256;
    wire N__1253;
    wire N__1250;
    wire N__1247;
    wire N__1244;
    wire N__1239;
    wire N__1234;
    wire N__1231;
    wire N__1228;
    wire N__1225;
    wire N__1222;
    wire N__1219;
    wire N__1218;
    wire N__1217;
    wire N__1214;
    wire N__1211;
    wire N__1210;
    wire N__1207;
    wire N__1206;
    wire N__1205;
    wire N__1200;
    wire N__1197;
    wire N__1194;
    wire N__1191;
    wire N__1188;
    wire N__1185;
    wire N__1182;
    wire N__1179;
    wire N__1174;
    wire N__1173;
    wire N__1172;
    wire N__1169;
    wire N__1166;
    wire N__1161;
    wire N__1158;
    wire N__1155;
    wire N__1144;
    wire N__1141;
    wire N__1138;
    wire N__1135;
    wire N__1132;
    wire N__1129;
    wire N__1126;
    wire N__1123;
    wire N__1120;
    wire N__1117;
    wire N__1114;
    wire N__1111;
    wire N__1108;
    wire N__1105;
    wire N__1102;
    wire N__1099;
    wire N__1096;
    wire N__1093;
    wire N__1090;
    wire N__1087;
    wire N__1084;
    wire N__1081;
    wire N__1078;
    wire N__1075;
    wire N__1072;
    wire N__1069;
    wire N__1066;
    wire N__1063;
    wire N__1060;
    wire N__1057;
    wire N__1054;
    wire N__1051;
    wire N__1048;
    wire N__1045;
    wire N__1042;
    wire N__1039;
    wire N__1036;
    wire N__1033;
    wire N__1030;
    wire N__1027;
    wire N__1024;
    wire N__1021;
    wire N__1018;
    wire N__1015;
    wire N__1012;
    wire N__1009;
    wire N__1006;
    wire N__1003;
    wire N__1000;
    wire N__997;
    wire N__994;
    wire N__991;
    wire N__988;
    wire N__985;
    wire N__982;
    wire N__979;
    wire N__976;
    wire N__973;
    wire N__970;
    wire N__969;
    wire N__968;
    wire N__967;
    wire N__966;
    wire N__965;
    wire N__964;
    wire N__963;
    wire N__958;
    wire N__945;
    wire N__940;
    wire N__937;
    wire N__934;
    wire N__931;
    wire N__928;
    wire N__925;
    wire N__922;
    wire N__921;
    wire N__918;
    wire N__915;
    wire N__910;
    wire N__907;
    wire N__904;
    wire N__901;
    wire N__898;
    wire N__895;
    wire N__892;
    wire N__889;
    wire N__886;
    wire N__883;
    wire N__880;
    wire N__877;
    wire N__874;
    wire N__871;
    wire N__868;
    wire N__865;
    wire N__862;
    wire N__861;
    wire N__856;
    wire N__853;
    wire N__850;
    wire N__847;
    wire N__844;
    wire N__841;
    wire N__838;
    wire N__835;
    wire N__832;
    wire N__829;
    wire N__826;
    wire N__823;
    wire N__820;
    wire N__817;
    wire N__814;
    wire N__811;
    wire N__808;
    wire N__805;
    wire N__802;
    wire N__799;
    wire N__796;
    wire N__793;
    wire N__790;
    wire N__787;
    wire N__784;
    wire N__781;
    wire N__778;
    wire N__775;
    wire N__772;
    wire N__769;
    wire N__766;
    wire N__763;
    wire N__760;
    wire N__757;
    wire N__754;
    wire N__751;
    wire N__748;
    wire N__745;
    wire N__742;
    wire N__739;
    wire N__736;
    wire VCCG0;
    wire \INVrom_inst.ram0WCLKN_net ;
    wire \INVrom_inst.ram0RCLKN_net ;
    wire clk_c_g;
    wire cpu_addr_c_6;
    wire cpu_addr_c_8;
    wire cpu_addr_c_1;
    wire \INVrom_inst.ram1WCLKN_net ;
    wire cpu_addr_c_5;
    wire cpu_addr_c_2;
    wire \INVrom_inst.ram1RCLKN_net ;
    wire cpu_addr_c_4;
    wire cpu_addr_c_3;
    wire cpu_addr_c_7;
    wire GNDG0;
    wire \rom_inst.data_out_x_1__3 ;
    wire \rom_inst.data_out_x_0__3 ;
    wire rom_dat_3;
    wire \rom_inst.data_out_x_1__0 ;
    wire \rom_inst.data_out_x_0__0 ;
    wire rom_dat_0;
    wire \rom_inst.data_out_x_1__1 ;
    wire \rom_inst.data_out_x_0__1 ;
    wire rom_dat_1;
    wire \rom_inst.data_out_x_1__2 ;
    wire \rom_inst.data_out_x_0__2 ;
    wire rom_dat_2;
    wire \rom_inst.data_out_x_1__4 ;
    wire \rom_inst.data_out_x_0__4 ;
    wire rom_dat_4;
    wire \rom_inst.data_out_x_0__5 ;
    wire \rom_inst.data_out_x_1__5 ;
    wire rom_dat_5;
    wire \rom_inst.data_out_x_1__6 ;
    wire \rom_inst.data_out_x_0__6 ;
    wire rom_dat_6;
    wire \rom_inst.data_out_x_1__7 ;
    wire \rom_inst.data_out_x_0__7 ;
    wire cpu_addr_c_9;
    wire rom_dat_7;
    wire CONSTANT_ZERO_NET;
    wire cpu_addr_c_0;
    wire cpu_addr_c_i_0;
    wire CONSTANT_ONE_NET;
    wire cpu_ce_c;
    wire cpu_rw_c;
    wire cpu_m2_c;
    wire boot_on_c;
    wire rom_oe_i;
    wire rom_oe_i_cascade_;
    wire rom_oe_i_i;
    wire _gnd_net_;

    defparam \rom_inst.ram1_physical .INIT_0=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .WRITE_MODE=1;
    defparam \rom_inst.ram1_physical .READ_MODE=1;
    defparam \rom_inst.ram1_physical .INIT_F=256'b1000101000001000101010101010000000100000000000001010101010100000100010100000100010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_E=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_D=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_C=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_B=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_A=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_9=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_8=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_7=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_6=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_5=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_4=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_3=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_2=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram1_physical .INIT_1=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    SB_RAM40_4K \rom_inst.ram1_physical  (
            .RDATA({dangling_wire_0,\rom_inst.data_out_x_1__7 ,dangling_wire_1,\rom_inst.data_out_x_1__6 ,dangling_wire_2,\rom_inst.data_out_x_1__5 ,dangling_wire_3,\rom_inst.data_out_x_1__4 ,dangling_wire_4,\rom_inst.data_out_x_1__3 ,dangling_wire_5,\rom_inst.data_out_x_1__2 ,dangling_wire_6,\rom_inst.data_out_x_1__1 ,dangling_wire_7,\rom_inst.data_out_x_1__0 }),
            .RADDR({dangling_wire_8,dangling_wire_9,N__823,N__904,N__844,N__787,N__757,N__742,N__772,N__802,N__1354}),
            .WADDR({dangling_wire_10,dangling_wire_11,dangling_wire_12,dangling_wire_13,dangling_wire_14,dangling_wire_15,dangling_wire_16,dangling_wire_17,dangling_wire_18,dangling_wire_19,dangling_wire_20}),
            .MASK({dangling_wire_21,dangling_wire_22,dangling_wire_23,dangling_wire_24,dangling_wire_25,dangling_wire_26,dangling_wire_27,dangling_wire_28,dangling_wire_29,dangling_wire_30,dangling_wire_31,dangling_wire_32,dangling_wire_33,dangling_wire_34,dangling_wire_35,dangling_wire_36}),
            .WDATA({dangling_wire_37,dangling_wire_38,dangling_wire_39,dangling_wire_40,dangling_wire_41,dangling_wire_42,dangling_wire_43,dangling_wire_44,dangling_wire_45,dangling_wire_46,dangling_wire_47,dangling_wire_48,dangling_wire_49,dangling_wire_50,dangling_wire_51,dangling_wire_52}),
            .RCLKE(),
            .RCLK(\INVrom_inst.ram1RCLKN_net ),
            .RE(N__1317),
            .WCLKE(N__922),
            .WCLK(\INVrom_inst.ram1WCLKN_net ),
            .WE());
    defparam \rom_inst.ram0_physical .WRITE_MODE=1;
    defparam \rom_inst.ram0_physical .READ_MODE=1;
    defparam \rom_inst.ram0_physical .INIT_F=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram0_physical .INIT_E=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram0_physical .INIT_D=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram0_physical .INIT_C=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    defparam \rom_inst.ram0_physical .INIT_B=256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000001010101010100000101010101010101;
    defparam \rom_inst.ram0_physical .INIT_A=256'b0101010101000100000101000101000001010000010001000101000100000000000000000001010100000100000000000000010000000000010000000101000100000000000101000100010000000100000001000000000001000100010000010100000001010001000000000001010001000100010000010000000000000000;
    defparam \rom_inst.ram0_physical .INIT_9=256'b0000000000010100000001000000000000000101010101010100000001010001010101010100010101000100010000010000010000000000000000010000000000000100010100000000000000000100000000000000010000000100000000000101010001000000000001000101000001000100000000000101000100000000;
    defparam \rom_inst.ram0_physical .INIT_8=256'b0101010100000000010100000100000101000000010001000000010001000001010100010000000001010100010101010101000001000001000000000000000100000100010000010000000000000001010101010001010001000100010001000001000000000000010100010000000001010000010100010101010101010101;
    defparam \rom_inst.ram0_physical .INIT_7=256'b0001000001000001000000000100000001010101010101010001000000000000010101010100010001000100010100010101000001000100010100010000000000000000000101010000010000000000000001000000000001000000010100010000000001010000010001000000010000000100000000000100010001000001;
    defparam \rom_inst.ram0_physical .INIT_6=256'b0100000001010001000000000001010001000100010000010000000000000000000000000001010000000100000000000000010101010101010000000101000100000100000000000100010001000001010000000101000100000000000000010100010001000001000000000100010000000000000000000000010000000000;
    defparam \rom_inst.ram0_physical .INIT_5=256'b0000000000000000010000000101000101010101010001010100010001000001000001000000000000000001000000000000010001010000000000000000010000000000000001000000010000000000000000000001000000000100010100000001000001010000000000000000000001010001000000000101010100010101;
    defparam \rom_inst.ram0_physical .INIT_4=256'b0000000000010000010101000100000001000001010100010000000000000000000100010001000101010101010100000000010000000000010001010101000101000000010101000000000000000000010001000000010000000000000000000101010101010101010000010100010000010101010000000100010000000100;
    defparam \rom_inst.ram0_physical .INIT_3=256'b0001010001000001000101010100000100010101000001010001010001000101000101000101010100010101000101000001010100010001000101000000010000010100010101010001010001010000000001000000000000010000000101010001010001010101000101010000010000010000010000010001010000010101;
    defparam \rom_inst.ram0_physical .INIT_2=256'b0000010000000000000001000000000000010000010000010001000100010000000100010100010000000100000000000001000001000101000100010100010000010001000001000001000001000001000001000000000000010000010001010000010100000001000001010100000100000101000001000000010100000000;
    defparam \rom_inst.ram0_physical .INIT_1=256'b0000010000000000000001000000000000000101000000000000010100000000000001010000000100000100010101000000010000000000000101010001010000010100000100000001010000010001000101000000010100010100010101010001010001010101000101010001000000010000000001000001010001010101;
    defparam \rom_inst.ram0_physical .INIT_0=256'b0000010000000000000001000000000000000100000000000000010000000000000100000101010000000101010000000001010000010001000001000000000000010100010000010001010100010100000100000001000000010101000001000001010000010001000101010000010000010000000100010001010100010100;
    SB_RAM40_4K \rom_inst.ram0_physical  (
            .RDATA({dangling_wire_53,\rom_inst.data_out_x_0__7 ,dangling_wire_54,\rom_inst.data_out_x_0__6 ,dangling_wire_55,\rom_inst.data_out_x_0__5 ,dangling_wire_56,\rom_inst.data_out_x_0__4 ,dangling_wire_57,\rom_inst.data_out_x_0__3 ,dangling_wire_58,\rom_inst.data_out_x_0__2 ,dangling_wire_59,\rom_inst.data_out_x_0__1 ,dangling_wire_60,\rom_inst.data_out_x_0__0 }),
            .RADDR({dangling_wire_61,dangling_wire_62,N__829,N__910,N__850,N__793,N__763,N__748,N__778,N__808,N__1360}),
            .WADDR({dangling_wire_63,dangling_wire_64,dangling_wire_65,dangling_wire_66,dangling_wire_67,dangling_wire_68,dangling_wire_69,dangling_wire_70,dangling_wire_71,dangling_wire_72,dangling_wire_73}),
            .MASK({dangling_wire_74,dangling_wire_75,dangling_wire_76,dangling_wire_77,dangling_wire_78,dangling_wire_79,dangling_wire_80,dangling_wire_81,dangling_wire_82,dangling_wire_83,dangling_wire_84,dangling_wire_85,dangling_wire_86,dangling_wire_87,dangling_wire_88,dangling_wire_89}),
            .WDATA({dangling_wire_90,dangling_wire_91,dangling_wire_92,dangling_wire_93,dangling_wire_94,dangling_wire_95,dangling_wire_96,dangling_wire_97,dangling_wire_98,dangling_wire_99,dangling_wire_100,dangling_wire_101,dangling_wire_102,dangling_wire_103,dangling_wire_104,dangling_wire_105}),
            .RCLKE(),
            .RCLK(\INVrom_inst.ram0RCLKN_net ),
            .RE(N__1329),
            .WCLKE(N__921),
            .WCLK(\INVrom_inst.ram0WCLKN_net ),
            .WE());
    PRE_IO_GBUF clk_ibuf_gb_io_preiogbuf (
            .PADSIGNALTOGLOBALBUFFER(N__1676),
            .GLOBALBUFFEROUTPUT(clk_c_g));
    IO_PAD clk_ibuf_gb_io_iopad (
            .OE(N__1678),
            .DIN(N__1677),
            .DOUT(N__1676),
            .PACKAGEPIN(clk));
    defparam clk_ibuf_gb_io_preio.NEG_TRIGGER=1'b0;
    defparam clk_ibuf_gb_io_preio.PIN_TYPE=6'b000001;
    PRE_IO clk_ibuf_gb_io_preio (
            .PADOEN(N__1678),
            .PADOUT(N__1677),
            .PADIN(N__1676),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_5_iopad (
            .OE(N__1667),
            .DIN(N__1666),
            .DOUT(N__1665),
            .PACKAGEPIN(cpu_dat[5]));
    defparam cpu_dat_obuft_5_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_5_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_5_preio (
            .PADOEN(N__1667),
            .PADOUT(N__1666),
            .PADIN(N__1665),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1206),
            .DIN0(),
            .DOUT0(N__1018),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD gpio_obuft_0_iopad (
            .OE(N__1658),
            .DIN(N__1657),
            .DOUT(N__1656),
            .PACKAGEPIN(gpio[0]));
    defparam gpio_obuft_0_preio.NEG_TRIGGER=1'b0;
    defparam gpio_obuft_0_preio.PIN_TYPE=6'b101001;
    PRE_IO gpio_obuft_0_preio (
            .PADOEN(N__1658),
            .PADOUT(N__1657),
            .PADIN(N__1656),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_0_iopad (
            .OE(N__1649),
            .DIN(N__1648),
            .DOUT(N__1647),
            .PACKAGEPIN(cpu_addr[0]));
    defparam cpu_addr_ibuf_0_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_0_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_0_preio (
            .PADOEN(N__1649),
            .PADOUT(N__1648),
            .PADIN(N__1647),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_0),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_2_iopad (
            .OE(N__1640),
            .DIN(N__1639),
            .DOUT(N__1638),
            .PACKAGEPIN(cpu_dat[2]));
    defparam cpu_dat_obuft_2_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_2_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_2_preio (
            .PADOEN(N__1640),
            .PADOUT(N__1639),
            .PADIN(N__1638),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1219),
            .DIN0(),
            .DOUT0(N__1069),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_9_iopad (
            .OE(N__1631),
            .DIN(N__1630),
            .DOUT(N__1629),
            .PACKAGEPIN(cpu_addr[9]));
    defparam cpu_addr_ibuf_9_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_9_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_9_preio (
            .PADOEN(N__1631),
            .PADOUT(N__1630),
            .PADIN(N__1629),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_9),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD gpio_obuft_2_iopad (
            .OE(N__1622),
            .DIN(N__1621),
            .DOUT(N__1620),
            .PACKAGEPIN(gpio[2]));
    defparam gpio_obuft_2_preio.NEG_TRIGGER=1'b0;
    defparam gpio_obuft_2_preio.PIN_TYPE=6'b101001;
    PRE_IO gpio_obuft_2_preio (
            .PADOEN(N__1622),
            .PADOUT(N__1621),
            .PADIN(N__1620),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD spi_miso_obuft_iopad (
            .OE(N__1613),
            .DIN(N__1612),
            .DOUT(N__1611),
            .PACKAGEPIN(spi_miso));
    defparam spi_miso_obuft_preio.NEG_TRIGGER=1'b0;
    defparam spi_miso_obuft_preio.PIN_TYPE=6'b101001;
    PRE_IO spi_miso_obuft_preio (
            .PADOEN(N__1613),
            .PADOUT(N__1612),
            .PADIN(N__1611),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    defparam boot_on_ibuf_iopad.PULLUP=1'b1;
    IO_PAD boot_on_ibuf_iopad (
            .OE(N__1604),
            .DIN(N__1603),
            .DOUT(N__1602),
            .PACKAGEPIN(boot_on));
    defparam boot_on_ibuf_preio.NEG_TRIGGER=1'b0;
    defparam boot_on_ibuf_preio.PIN_TYPE=6'b000001;
    PRE_IO boot_on_ibuf_preio (
            .PADOEN(N__1604),
            .PADOUT(N__1603),
            .PADIN(N__1602),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(boot_on_c),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_0_iopad (
            .OE(N__1595),
            .DIN(N__1594),
            .DOUT(N__1593),
            .PACKAGEPIN(cpu_dat[0]));
    defparam cpu_dat_obuft_0_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_0_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_0_preio (
            .PADOEN(N__1595),
            .PADOUT(N__1594),
            .PADIN(N__1593),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1217),
            .DIN0(),
            .DOUT0(N__1126),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_7_iopad (
            .OE(N__1586),
            .DIN(N__1585),
            .DOUT(N__1584),
            .PACKAGEPIN(cpu_addr[7]));
    defparam cpu_addr_ibuf_7_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_7_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_7_preio (
            .PADOEN(N__1586),
            .PADOUT(N__1585),
            .PADIN(N__1584),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_7),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_4_iopad (
            .OE(N__1577),
            .DIN(N__1576),
            .DOUT(N__1575),
            .PACKAGEPIN(cpu_addr[4]));
    defparam cpu_addr_ibuf_4_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_4_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_4_preio (
            .PADOEN(N__1577),
            .PADOUT(N__1576),
            .PADIN(N__1575),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_4),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_ce_ibuf_iopad (
            .OE(N__1568),
            .DIN(N__1567),
            .DOUT(N__1566),
            .PACKAGEPIN(cpu_ce));
    defparam cpu_ce_ibuf_preio.NEG_TRIGGER=1'b0;
    defparam cpu_ce_ibuf_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_ce_ibuf_preio (
            .PADOEN(N__1568),
            .PADOUT(N__1567),
            .PADIN(N__1566),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_ce_c),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_6_iopad (
            .OE(N__1559),
            .DIN(N__1558),
            .DOUT(N__1557),
            .PACKAGEPIN(cpu_dat[6]));
    defparam cpu_dat_obuft_6_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_6_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_6_preio (
            .PADOEN(N__1559),
            .PADOUT(N__1558),
            .PADIN(N__1557),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1172),
            .DIN0(),
            .DOUT0(N__994),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_rw_ibuf_iopad (
            .OE(N__1550),
            .DIN(N__1549),
            .DOUT(N__1548),
            .PACKAGEPIN(cpu_rw));
    defparam cpu_rw_ibuf_preio.NEG_TRIGGER=1'b0;
    defparam cpu_rw_ibuf_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_rw_ibuf_preio (
            .PADOEN(N__1550),
            .PADOUT(N__1549),
            .PADIN(N__1548),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_rw_c),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_5_iopad (
            .OE(N__1541),
            .DIN(N__1540),
            .DOUT(N__1539),
            .PACKAGEPIN(cpu_addr[5]));
    defparam cpu_addr_ibuf_5_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_5_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_5_preio (
            .PADOEN(N__1541),
            .PADOUT(N__1540),
            .PADIN(N__1539),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_5),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_7_iopad (
            .OE(N__1532),
            .DIN(N__1531),
            .DOUT(N__1530),
            .PACKAGEPIN(cpu_dat[7]));
    defparam cpu_dat_obuft_7_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_7_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_7_preio (
            .PADOEN(N__1532),
            .PADOUT(N__1531),
            .PADIN(N__1530),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1173),
            .DIN0(),
            .DOUT0(N__931),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dir_obuft_iopad (
            .OE(N__1523),
            .DIN(N__1522),
            .DOUT(N__1521),
            .PACKAGEPIN(cpu_dir));
    defparam cpu_dir_obuft_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dir_obuft_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dir_obuft_preio (
            .PADOEN(N__1523),
            .PADOUT(N__1522),
            .PADIN(N__1521),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1264),
            .DIN0(),
            .DOUT0(N__1339),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_2_iopad (
            .OE(N__1514),
            .DIN(N__1513),
            .DOUT(N__1512),
            .PACKAGEPIN(cpu_addr[2]));
    defparam cpu_addr_ibuf_2_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_2_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_2_preio (
            .PADOEN(N__1514),
            .PADOUT(N__1513),
            .PADIN(N__1512),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_2),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_4_iopad (
            .OE(N__1505),
            .DIN(N__1504),
            .DOUT(N__1503),
            .PACKAGEPIN(cpu_dat[4]));
    defparam cpu_dat_obuft_4_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_4_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_4_preio (
            .PADOEN(N__1505),
            .PADOUT(N__1504),
            .PADIN(N__1503),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1205),
            .DIN0(),
            .DOUT0(N__1042),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_ex_obuft_iopad (
            .OE(N__1496),
            .DIN(N__1495),
            .DOUT(N__1494),
            .PACKAGEPIN(cpu_ex));
    defparam cpu_ex_obuft_preio.NEG_TRIGGER=1'b0;
    defparam cpu_ex_obuft_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_ex_obuft_preio (
            .PADOEN(N__1496),
            .PADOUT(N__1495),
            .PADIN(N__1494),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1257),
            .DIN0(),
            .DOUT0(N__1228),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD gpio_obuft_1_iopad (
            .OE(N__1487),
            .DIN(N__1486),
            .DOUT(N__1485),
            .PACKAGEPIN(gpio[1]));
    defparam gpio_obuft_1_preio.NEG_TRIGGER=1'b0;
    defparam gpio_obuft_1_preio.PIN_TYPE=6'b101001;
    PRE_IO gpio_obuft_1_preio (
            .PADOEN(N__1487),
            .PADOUT(N__1486),
            .PADIN(N__1485),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD ice_sdo_obuft_iopad (
            .OE(N__1478),
            .DIN(N__1477),
            .DOUT(N__1476),
            .PACKAGEPIN(ice_sdo));
    defparam ice_sdo_obuft_preio.NEG_TRIGGER=1'b0;
    defparam ice_sdo_obuft_preio.PIN_TYPE=6'b101001;
    PRE_IO ice_sdo_obuft_preio (
            .PADOEN(N__1478),
            .PADOUT(N__1477),
            .PADIN(N__1476),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_3_iopad (
            .OE(N__1469),
            .DIN(N__1468),
            .DOUT(N__1467),
            .PACKAGEPIN(cpu_addr[3]));
    defparam cpu_addr_ibuf_3_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_3_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_3_preio (
            .PADOEN(N__1469),
            .PADOUT(N__1468),
            .PADIN(N__1467),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_3),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD boot0_obuft_iopad (
            .OE(N__1460),
            .DIN(N__1459),
            .DOUT(N__1458),
            .PACKAGEPIN(boot0));
    defparam boot0_obuft_preio.NEG_TRIGGER=1'b0;
    defparam boot0_obuft_preio.PIN_TYPE=6'b101001;
    PRE_IO boot0_obuft_preio (
            .PADOEN(N__1460),
            .PADOUT(N__1459),
            .PADIN(N__1458),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_8_iopad (
            .OE(N__1451),
            .DIN(N__1450),
            .DOUT(N__1449),
            .PACKAGEPIN(cpu_addr[8]));
    defparam cpu_addr_ibuf_8_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_8_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_8_preio (
            .PADOEN(N__1451),
            .PADOUT(N__1450),
            .PADIN(N__1449),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_8),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_m2_ibuf_iopad (
            .OE(N__1442),
            .DIN(N__1441),
            .DOUT(N__1440),
            .PACKAGEPIN(cpu_m2));
    defparam cpu_m2_ibuf_preio.NEG_TRIGGER=1'b0;
    defparam cpu_m2_ibuf_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_m2_ibuf_preio (
            .PADOEN(N__1442),
            .PADOUT(N__1441),
            .PADIN(N__1440),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_m2_c),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD gpio_obuft_3_iopad (
            .OE(N__1433),
            .DIN(N__1432),
            .DOUT(N__1431),
            .PACKAGEPIN(gpio[3]));
    defparam gpio_obuft_3_preio.NEG_TRIGGER=1'b0;
    defparam gpio_obuft_3_preio.PIN_TYPE=6'b101001;
    PRE_IO gpio_obuft_3_preio (
            .PADOEN(N__1433),
            .PADOUT(N__1432),
            .PADIN(N__1431),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_1_iopad (
            .OE(N__1424),
            .DIN(N__1423),
            .DOUT(N__1422),
            .PACKAGEPIN(cpu_addr[1]));
    defparam cpu_addr_ibuf_1_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_1_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_1_preio (
            .PADOEN(N__1424),
            .PADOUT(N__1423),
            .PADIN(N__1422),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_1),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_3_iopad (
            .OE(N__1415),
            .DIN(N__1414),
            .DOUT(N__1413),
            .PACKAGEPIN(cpu_dat[3]));
    defparam cpu_dat_obuft_3_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_3_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_3_preio (
            .PADOEN(N__1415),
            .PADOUT(N__1414),
            .PADIN(N__1413),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1210),
            .DIN0(),
            .DOUT0(N__874),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_addr_ibuf_6_iopad (
            .OE(N__1406),
            .DIN(N__1405),
            .DOUT(N__1404),
            .PACKAGEPIN(cpu_addr[6]));
    defparam cpu_addr_ibuf_6_preio.NEG_TRIGGER=1'b0;
    defparam cpu_addr_ibuf_6_preio.PIN_TYPE=6'b000001;
    PRE_IO cpu_addr_ibuf_6_preio (
            .PADOEN(N__1406),
            .PADOUT(N__1405),
            .PADIN(N__1404),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(cpu_addr_c_6),
            .DOUT0(),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD mcu_rst_obuft_iopad (
            .OE(N__1397),
            .DIN(N__1396),
            .DOUT(N__1395),
            .PACKAGEPIN(mcu_rst));
    defparam mcu_rst_obuft_preio.NEG_TRIGGER=1'b0;
    defparam mcu_rst_obuft_preio.PIN_TYPE=6'b101001;
    PRE_IO mcu_rst_obuft_preio (
            .PADOEN(N__1397),
            .PADOUT(N__1396),
            .PADIN(N__1395),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(),
            .DIN0(),
            .DOUT0(GNDG0),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    IO_PAD cpu_dat_obuft_1_iopad (
            .OE(N__1388),
            .DIN(N__1387),
            .DOUT(N__1386),
            .PACKAGEPIN(cpu_dat[1]));
    defparam cpu_dat_obuft_1_preio.NEG_TRIGGER=1'b0;
    defparam cpu_dat_obuft_1_preio.PIN_TYPE=6'b101001;
    PRE_IO cpu_dat_obuft_1_preio (
            .PADOEN(N__1388),
            .PADOUT(N__1387),
            .PADIN(N__1386),
            .CLOCKENABLE(),
            .DOUT1(),
            .OUTPUTENABLE(N__1218),
            .DIN0(),
            .DOUT0(N__1096),
            .INPUTCLK(),
            .LATCHINPUTVALUE(),
            .DIN1(),
            .OUTPUTCLK());
    InMux I__266 (
            .O(N__1369),
            .I(N__1366));
    LocalMux I__265 (
            .O(N__1366),
            .I(N__1363));
    Odrv4 I__264 (
            .O(N__1363),
            .I(cpu_addr_c_0));
    CascadeMux I__263 (
            .O(N__1360),
            .I(N__1357));
    CascadeBuf I__262 (
            .O(N__1357),
            .I(N__1354));
    CascadeMux I__261 (
            .O(N__1354),
            .I(N__1351));
    InMux I__260 (
            .O(N__1351),
            .I(N__1348));
    LocalMux I__259 (
            .O(N__1348),
            .I(N__1345));
    Span4Mux_s1_v I__258 (
            .O(N__1345),
            .I(N__1342));
    Odrv4 I__257 (
            .O(N__1342),
            .I(cpu_addr_c_i_0));
    IoInMux I__256 (
            .O(N__1339),
            .I(N__1336));
    LocalMux I__255 (
            .O(N__1336),
            .I(N__1333));
    IoSpan4Mux I__254 (
            .O(N__1333),
            .I(N__1330));
    IoSpan4Mux I__253 (
            .O(N__1330),
            .I(N__1326));
    SRMux I__252 (
            .O(N__1329),
            .I(N__1323));
    Span4Mux_s1_h I__251 (
            .O(N__1326),
            .I(N__1318));
    LocalMux I__250 (
            .O(N__1323),
            .I(N__1318));
    Span4Mux_v I__249 (
            .O(N__1318),
            .I(N__1314));
    SRMux I__248 (
            .O(N__1317),
            .I(N__1311));
    Span4Mux_s1_h I__247 (
            .O(N__1314),
            .I(N__1306));
    LocalMux I__246 (
            .O(N__1311),
            .I(N__1306));
    Span4Mux_s1_v I__245 (
            .O(N__1306),
            .I(N__1303));
    Sp12to4 I__244 (
            .O(N__1303),
            .I(N__1300));
    Odrv12 I__243 (
            .O(N__1300),
            .I(CONSTANT_ONE_NET));
    InMux I__242 (
            .O(N__1297),
            .I(N__1294));
    LocalMux I__241 (
            .O(N__1294),
            .I(N__1291));
    Odrv4 I__240 (
            .O(N__1291),
            .I(cpu_ce_c));
    InMux I__239 (
            .O(N__1288),
            .I(N__1285));
    LocalMux I__238 (
            .O(N__1285),
            .I(cpu_rw_c));
    CascadeMux I__237 (
            .O(N__1282),
            .I(N__1279));
    InMux I__236 (
            .O(N__1279),
            .I(N__1276));
    LocalMux I__235 (
            .O(N__1276),
            .I(N__1273));
    Span4Mux_s1_h I__234 (
            .O(N__1273),
            .I(N__1270));
    IoSpan4Mux I__233 (
            .O(N__1270),
            .I(N__1267));
    Odrv4 I__232 (
            .O(N__1267),
            .I(cpu_m2_c));
    IoInMux I__231 (
            .O(N__1264),
            .I(N__1261));
    LocalMux I__230 (
            .O(N__1261),
            .I(N__1258));
    IoSpan4Mux I__229 (
            .O(N__1258),
            .I(N__1253));
    IoInMux I__228 (
            .O(N__1257),
            .I(N__1250));
    InMux I__227 (
            .O(N__1256),
            .I(N__1247));
    IoSpan4Mux I__226 (
            .O(N__1253),
            .I(N__1244));
    LocalMux I__225 (
            .O(N__1250),
            .I(N__1239));
    LocalMux I__224 (
            .O(N__1247),
            .I(N__1239));
    IoSpan4Mux I__223 (
            .O(N__1244),
            .I(N__1234));
    IoSpan4Mux I__222 (
            .O(N__1239),
            .I(N__1234));
    IoSpan4Mux I__221 (
            .O(N__1234),
            .I(N__1231));
    Odrv4 I__220 (
            .O(N__1231),
            .I(boot_on_c));
    IoInMux I__219 (
            .O(N__1228),
            .I(N__1225));
    LocalMux I__218 (
            .O(N__1225),
            .I(rom_oe_i));
    CascadeMux I__217 (
            .O(N__1222),
            .I(rom_oe_i_cascade_));
    IoInMux I__216 (
            .O(N__1219),
            .I(N__1214));
    IoInMux I__215 (
            .O(N__1218),
            .I(N__1211));
    IoInMux I__214 (
            .O(N__1217),
            .I(N__1207));
    LocalMux I__213 (
            .O(N__1214),
            .I(N__1200));
    LocalMux I__212 (
            .O(N__1211),
            .I(N__1200));
    IoInMux I__211 (
            .O(N__1210),
            .I(N__1197));
    LocalMux I__210 (
            .O(N__1207),
            .I(N__1194));
    IoInMux I__209 (
            .O(N__1206),
            .I(N__1191));
    IoInMux I__208 (
            .O(N__1205),
            .I(N__1188));
    Span4Mux_s1_h I__207 (
            .O(N__1200),
            .I(N__1185));
    LocalMux I__206 (
            .O(N__1197),
            .I(N__1182));
    Span4Mux_s0_h I__205 (
            .O(N__1194),
            .I(N__1179));
    LocalMux I__204 (
            .O(N__1191),
            .I(N__1174));
    LocalMux I__203 (
            .O(N__1188),
            .I(N__1174));
    Span4Mux_v I__202 (
            .O(N__1185),
            .I(N__1169));
    Span4Mux_s0_h I__201 (
            .O(N__1182),
            .I(N__1166));
    Span4Mux_v I__200 (
            .O(N__1179),
            .I(N__1161));
    Span4Mux_s0_h I__199 (
            .O(N__1174),
            .I(N__1161));
    IoInMux I__198 (
            .O(N__1173),
            .I(N__1158));
    IoInMux I__197 (
            .O(N__1172),
            .I(N__1155));
    Odrv4 I__196 (
            .O(N__1169),
            .I(rom_oe_i_i));
    Odrv4 I__195 (
            .O(N__1166),
            .I(rom_oe_i_i));
    Odrv4 I__194 (
            .O(N__1161),
            .I(rom_oe_i_i));
    LocalMux I__193 (
            .O(N__1158),
            .I(rom_oe_i_i));
    LocalMux I__192 (
            .O(N__1155),
            .I(rom_oe_i_i));
    InMux I__191 (
            .O(N__1144),
            .I(N__1141));
    LocalMux I__190 (
            .O(N__1141),
            .I(N__1138));
    Span4Mux_v I__189 (
            .O(N__1138),
            .I(N__1135));
    Odrv4 I__188 (
            .O(N__1135),
            .I(\rom_inst.data_out_x_1__0 ));
    InMux I__187 (
            .O(N__1132),
            .I(N__1129));
    LocalMux I__186 (
            .O(N__1129),
            .I(\rom_inst.data_out_x_0__0 ));
    IoInMux I__185 (
            .O(N__1126),
            .I(N__1123));
    LocalMux I__184 (
            .O(N__1123),
            .I(N__1120));
    Span4Mux_s1_h I__183 (
            .O(N__1120),
            .I(N__1117));
    Odrv4 I__182 (
            .O(N__1117),
            .I(rom_dat_0));
    InMux I__181 (
            .O(N__1114),
            .I(N__1111));
    LocalMux I__180 (
            .O(N__1111),
            .I(N__1108));
    Span12Mux_s2_h I__179 (
            .O(N__1108),
            .I(N__1105));
    Odrv12 I__178 (
            .O(N__1105),
            .I(\rom_inst.data_out_x_1__1 ));
    InMux I__177 (
            .O(N__1102),
            .I(N__1099));
    LocalMux I__176 (
            .O(N__1099),
            .I(\rom_inst.data_out_x_0__1 ));
    IoInMux I__175 (
            .O(N__1096),
            .I(N__1093));
    LocalMux I__174 (
            .O(N__1093),
            .I(N__1090));
    IoSpan4Mux I__173 (
            .O(N__1090),
            .I(N__1087));
    Odrv4 I__172 (
            .O(N__1087),
            .I(rom_dat_1));
    InMux I__171 (
            .O(N__1084),
            .I(N__1081));
    LocalMux I__170 (
            .O(N__1081),
            .I(N__1078));
    Odrv4 I__169 (
            .O(N__1078),
            .I(\rom_inst.data_out_x_1__2 ));
    InMux I__168 (
            .O(N__1075),
            .I(N__1072));
    LocalMux I__167 (
            .O(N__1072),
            .I(\rom_inst.data_out_x_0__2 ));
    IoInMux I__166 (
            .O(N__1069),
            .I(N__1066));
    LocalMux I__165 (
            .O(N__1066),
            .I(N__1063));
    Span4Mux_s1_h I__164 (
            .O(N__1063),
            .I(N__1060));
    Odrv4 I__163 (
            .O(N__1060),
            .I(rom_dat_2));
    InMux I__162 (
            .O(N__1057),
            .I(N__1054));
    LocalMux I__161 (
            .O(N__1054),
            .I(N__1051));
    Odrv4 I__160 (
            .O(N__1051),
            .I(\rom_inst.data_out_x_1__4 ));
    InMux I__159 (
            .O(N__1048),
            .I(N__1045));
    LocalMux I__158 (
            .O(N__1045),
            .I(\rom_inst.data_out_x_0__4 ));
    IoInMux I__157 (
            .O(N__1042),
            .I(N__1039));
    LocalMux I__156 (
            .O(N__1039),
            .I(N__1036));
    Odrv4 I__155 (
            .O(N__1036),
            .I(rom_dat_4));
    InMux I__154 (
            .O(N__1033),
            .I(N__1030));
    LocalMux I__153 (
            .O(N__1030),
            .I(\rom_inst.data_out_x_0__5 ));
    InMux I__152 (
            .O(N__1027),
            .I(N__1024));
    LocalMux I__151 (
            .O(N__1024),
            .I(N__1021));
    Odrv4 I__150 (
            .O(N__1021),
            .I(\rom_inst.data_out_x_1__5 ));
    IoInMux I__149 (
            .O(N__1018),
            .I(N__1015));
    LocalMux I__148 (
            .O(N__1015),
            .I(N__1012));
    Odrv4 I__147 (
            .O(N__1012),
            .I(rom_dat_5));
    InMux I__146 (
            .O(N__1009),
            .I(N__1006));
    LocalMux I__145 (
            .O(N__1006),
            .I(N__1003));
    Odrv4 I__144 (
            .O(N__1003),
            .I(\rom_inst.data_out_x_1__6 ));
    InMux I__143 (
            .O(N__1000),
            .I(N__997));
    LocalMux I__142 (
            .O(N__997),
            .I(\rom_inst.data_out_x_0__6 ));
    IoInMux I__141 (
            .O(N__994),
            .I(N__991));
    LocalMux I__140 (
            .O(N__991),
            .I(N__988));
    Odrv4 I__139 (
            .O(N__988),
            .I(rom_dat_6));
    InMux I__138 (
            .O(N__985),
            .I(N__982));
    LocalMux I__137 (
            .O(N__982),
            .I(N__979));
    Odrv4 I__136 (
            .O(N__979),
            .I(\rom_inst.data_out_x_1__7 ));
    InMux I__135 (
            .O(N__976),
            .I(N__973));
    LocalMux I__134 (
            .O(N__973),
            .I(\rom_inst.data_out_x_0__7 ));
    InMux I__133 (
            .O(N__970),
            .I(N__958));
    InMux I__132 (
            .O(N__969),
            .I(N__958));
    InMux I__131 (
            .O(N__968),
            .I(N__945));
    InMux I__130 (
            .O(N__967),
            .I(N__945));
    InMux I__129 (
            .O(N__966),
            .I(N__945));
    InMux I__128 (
            .O(N__965),
            .I(N__945));
    InMux I__127 (
            .O(N__964),
            .I(N__945));
    InMux I__126 (
            .O(N__963),
            .I(N__945));
    LocalMux I__125 (
            .O(N__958),
            .I(N__940));
    LocalMux I__124 (
            .O(N__945),
            .I(N__940));
    Span4Mux_v I__123 (
            .O(N__940),
            .I(N__937));
    Span4Mux_v I__122 (
            .O(N__937),
            .I(N__934));
    Odrv4 I__121 (
            .O(N__934),
            .I(cpu_addr_c_9));
    IoInMux I__120 (
            .O(N__931),
            .I(N__928));
    LocalMux I__119 (
            .O(N__928),
            .I(N__925));
    Odrv12 I__118 (
            .O(N__925),
            .I(rom_dat_7));
    CEMux I__117 (
            .O(N__922),
            .I(N__918));
    CEMux I__116 (
            .O(N__921),
            .I(N__915));
    LocalMux I__115 (
            .O(N__918),
            .I(CONSTANT_ZERO_NET));
    LocalMux I__114 (
            .O(N__915),
            .I(CONSTANT_ZERO_NET));
    CascadeMux I__113 (
            .O(N__910),
            .I(N__907));
    CascadeBuf I__112 (
            .O(N__907),
            .I(N__904));
    CascadeMux I__111 (
            .O(N__904),
            .I(N__901));
    InMux I__110 (
            .O(N__901),
            .I(N__898));
    LocalMux I__109 (
            .O(N__898),
            .I(N__895));
    Span4Mux_h I__108 (
            .O(N__895),
            .I(N__892));
    Odrv4 I__107 (
            .O(N__892),
            .I(cpu_addr_c_7));
    InMux I__106 (
            .O(N__889),
            .I(N__886));
    LocalMux I__105 (
            .O(N__886),
            .I(N__883));
    Odrv4 I__104 (
            .O(N__883),
            .I(\rom_inst.data_out_x_1__3 ));
    InMux I__103 (
            .O(N__880),
            .I(N__877));
    LocalMux I__102 (
            .O(N__877),
            .I(\rom_inst.data_out_x_0__3 ));
    IoInMux I__101 (
            .O(N__874),
            .I(N__871));
    LocalMux I__100 (
            .O(N__871),
            .I(N__868));
    IoSpan4Mux I__99 (
            .O(N__868),
            .I(N__865));
    Odrv4 I__98 (
            .O(N__865),
            .I(rom_dat_3));
    ClkMux I__97 (
            .O(N__862),
            .I(N__856));
    ClkMux I__96 (
            .O(N__861),
            .I(N__856));
    GlobalMux I__95 (
            .O(N__856),
            .I(N__853));
    gio2CtrlBuf I__94 (
            .O(N__853),
            .I(clk_c_g));
    CascadeMux I__93 (
            .O(N__850),
            .I(N__847));
    CascadeBuf I__92 (
            .O(N__847),
            .I(N__844));
    CascadeMux I__91 (
            .O(N__844),
            .I(N__841));
    InMux I__90 (
            .O(N__841),
            .I(N__838));
    LocalMux I__89 (
            .O(N__838),
            .I(N__835));
    IoSpan4Mux I__88 (
            .O(N__835),
            .I(N__832));
    Odrv4 I__87 (
            .O(N__832),
            .I(cpu_addr_c_6));
    CascadeMux I__86 (
            .O(N__829),
            .I(N__826));
    CascadeBuf I__85 (
            .O(N__826),
            .I(N__823));
    CascadeMux I__84 (
            .O(N__823),
            .I(N__820));
    InMux I__83 (
            .O(N__820),
            .I(N__817));
    LocalMux I__82 (
            .O(N__817),
            .I(N__814));
    Span12Mux_v I__81 (
            .O(N__814),
            .I(N__811));
    Odrv12 I__80 (
            .O(N__811),
            .I(cpu_addr_c_8));
    CascadeMux I__79 (
            .O(N__808),
            .I(N__805));
    CascadeBuf I__78 (
            .O(N__805),
            .I(N__802));
    CascadeMux I__77 (
            .O(N__802),
            .I(N__799));
    InMux I__76 (
            .O(N__799),
            .I(N__796));
    LocalMux I__75 (
            .O(N__796),
            .I(cpu_addr_c_1));
    CascadeMux I__74 (
            .O(N__793),
            .I(N__790));
    CascadeBuf I__73 (
            .O(N__790),
            .I(N__787));
    CascadeMux I__72 (
            .O(N__787),
            .I(N__784));
    InMux I__71 (
            .O(N__784),
            .I(N__781));
    LocalMux I__70 (
            .O(N__781),
            .I(cpu_addr_c_5));
    CascadeMux I__69 (
            .O(N__778),
            .I(N__775));
    CascadeBuf I__68 (
            .O(N__775),
            .I(N__772));
    CascadeMux I__67 (
            .O(N__772),
            .I(N__769));
    InMux I__66 (
            .O(N__769),
            .I(N__766));
    LocalMux I__65 (
            .O(N__766),
            .I(cpu_addr_c_2));
    CascadeMux I__64 (
            .O(N__763),
            .I(N__760));
    CascadeBuf I__63 (
            .O(N__760),
            .I(N__757));
    CascadeMux I__62 (
            .O(N__757),
            .I(N__754));
    InMux I__61 (
            .O(N__754),
            .I(N__751));
    LocalMux I__60 (
            .O(N__751),
            .I(cpu_addr_c_4));
    CascadeMux I__59 (
            .O(N__748),
            .I(N__745));
    CascadeBuf I__58 (
            .O(N__745),
            .I(N__742));
    CascadeMux I__57 (
            .O(N__742),
            .I(N__739));
    InMux I__56 (
            .O(N__739),
            .I(N__736));
    LocalMux I__55 (
            .O(N__736),
            .I(cpu_addr_c_3));
    INV \INVrom_inst.ram1WCLKN  (
            .O(\INVrom_inst.ram1WCLKN_net ),
            .I(GNDG0));
    INV \INVrom_inst.ram1RCLKN  (
            .O(\INVrom_inst.ram1RCLKN_net ),
            .I(N__861));
    INV \INVrom_inst.ram0WCLKN  (
            .O(\INVrom_inst.ram0WCLKN_net ),
            .I(GNDG0));
    INV \INVrom_inst.ram0RCLKN  (
            .O(\INVrom_inst.ram0RCLKN_net ),
            .I(N__862));
    VCC VCC (
            .Y(VCCG0));
    GND GND (
            .Y(GNDG0));
    GND GND_Inst (
            .Y(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_2_LC_11_13_0 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_2_LC_11_13_0 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_2_LC_11_13_0 .LUT_INIT=16'b1101110110001000;
    LogicCell40 \rom_inst.ram0_RNIBF5F_2_LC_11_13_0  (
            .in0(N__965),
            .in1(N__889),
            .in2(_gnd_net_),
            .in3(N__880),
            .lcout(rom_dat_3),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_LC_11_13_2 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_LC_11_13_2 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_LC_11_13_2 .LUT_INIT=16'b1101110110001000;
    LogicCell40 \rom_inst.ram0_RNIBF5F_LC_11_13_2  (
            .in0(N__968),
            .in1(N__1144),
            .in2(_gnd_net_),
            .in3(N__1132),
            .lcout(rom_dat_0),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_0_LC_11_13_3 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_0_LC_11_13_3 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_0_LC_11_13_3 .LUT_INIT=16'b1010101011001100;
    LogicCell40 \rom_inst.ram0_RNIBF5F_0_LC_11_13_3  (
            .in0(N__1114),
            .in1(N__1102),
            .in2(_gnd_net_),
            .in3(N__963),
            .lcout(rom_dat_1),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_1_LC_11_13_4 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_1_LC_11_13_4 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_1_LC_11_13_4 .LUT_INIT=16'b1101110110001000;
    LogicCell40 \rom_inst.ram0_RNIBF5F_1_LC_11_13_4  (
            .in0(N__964),
            .in1(N__1084),
            .in2(_gnd_net_),
            .in3(N__1075),
            .lcout(rom_dat_2),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_3_LC_11_13_6 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_3_LC_11_13_6 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_3_LC_11_13_6 .LUT_INIT=16'b1101110110001000;
    LogicCell40 \rom_inst.ram0_RNIBF5F_3_LC_11_13_6  (
            .in0(N__966),
            .in1(N__1057),
            .in2(_gnd_net_),
            .in3(N__1048),
            .lcout(rom_dat_4),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_4_LC_11_13_7 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_4_LC_11_13_7 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_4_LC_11_13_7 .LUT_INIT=16'b1100110010101010;
    LogicCell40 \rom_inst.ram0_RNIBF5F_4_LC_11_13_7  (
            .in0(N__1033),
            .in1(N__1027),
            .in2(_gnd_net_),
            .in3(N__967),
            .lcout(rom_dat_5),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_5_LC_11_14_0 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_5_LC_11_14_0 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_5_LC_11_14_0 .LUT_INIT=16'b1101110110001000;
    LogicCell40 \rom_inst.ram0_RNIBF5F_5_LC_11_14_0  (
            .in0(N__969),
            .in1(N__1009),
            .in2(_gnd_net_),
            .in3(N__1000),
            .lcout(rom_dat_6),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam \rom_inst.ram0_RNIBF5F_6_LC_11_14_1 .C_ON=1'b0;
    defparam \rom_inst.ram0_RNIBF5F_6_LC_11_14_1 .SEQ_MODE=4'b0000;
    defparam \rom_inst.ram0_RNIBF5F_6_LC_11_14_1 .LUT_INIT=16'b1010101011001100;
    LogicCell40 \rom_inst.ram0_RNIBF5F_6_LC_11_14_1  (
            .in0(N__985),
            .in1(N__976),
            .in2(_gnd_net_),
            .in3(N__970),
            .lcout(rom_dat_7),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam CONSTANT_ZERO_LUT4_LC_11_14_3.C_ON=1'b0;
    defparam CONSTANT_ZERO_LUT4_LC_11_14_3.SEQ_MODE=4'b0000;
    defparam CONSTANT_ZERO_LUT4_LC_11_14_3.LUT_INIT=16'b0000000000000000;
    LogicCell40 CONSTANT_ZERO_LUT4_LC_11_14_3 (
            .in0(_gnd_net_),
            .in1(_gnd_net_),
            .in2(_gnd_net_),
            .in3(_gnd_net_),
            .lcout(CONSTANT_ZERO_NET),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam cpu_addr_ibuf_RNIFFNB_0_LC_12_15_0.C_ON=1'b0;
    defparam cpu_addr_ibuf_RNIFFNB_0_LC_12_15_0.SEQ_MODE=4'b0000;
    defparam cpu_addr_ibuf_RNIFFNB_0_LC_12_15_0.LUT_INIT=16'b0000000011111111;
    LogicCell40 cpu_addr_ibuf_RNIFFNB_0_LC_12_15_0 (
            .in0(_gnd_net_),
            .in1(_gnd_net_),
            .in2(_gnd_net_),
            .in3(N__1369),
            .lcout(cpu_addr_c_i_0),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam CONSTANT_ONE_LUT4_LC_12_15_2.C_ON=1'b0;
    defparam CONSTANT_ONE_LUT4_LC_12_15_2.SEQ_MODE=4'b0000;
    defparam CONSTANT_ONE_LUT4_LC_12_15_2.LUT_INIT=16'b1111111111111111;
    LogicCell40 CONSTANT_ONE_LUT4_LC_12_15_2 (
            .in0(_gnd_net_),
            .in1(_gnd_net_),
            .in2(_gnd_net_),
            .in3(_gnd_net_),
            .lcout(CONSTANT_ONE_NET),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam cpu_ce_ibuf_RNI9TA51_LC_12_15_6.C_ON=1'b0;
    defparam cpu_ce_ibuf_RNI9TA51_LC_12_15_6.SEQ_MODE=4'b0000;
    defparam cpu_ce_ibuf_RNI9TA51_LC_12_15_6.LUT_INIT=16'b1011111111111111;
    LogicCell40 cpu_ce_ibuf_RNI9TA51_LC_12_15_6 (
            .in0(N__1297),
            .in1(N__1288),
            .in2(N__1282),
            .in3(N__1256),
            .lcout(rom_oe_i),
            .ltout(rom_oe_i_cascade_),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
    defparam cpu_ce_ibuf_RNI9TA51_0_LC_12_15_7.C_ON=1'b0;
    defparam cpu_ce_ibuf_RNI9TA51_0_LC_12_15_7.SEQ_MODE=4'b0000;
    defparam cpu_ce_ibuf_RNI9TA51_0_LC_12_15_7.LUT_INIT=16'b0000111100001111;
    LogicCell40 cpu_ce_ibuf_RNI9TA51_0_LC_12_15_7 (
            .in0(_gnd_net_),
            .in1(_gnd_net_),
            .in2(N__1222),
            .in3(_gnd_net_),
            .lcout(rom_oe_i_i),
            .ltout(),
            .carryin(_gnd_net_),
            .carryout(),
            .clk(_gnd_net_),
            .ce(),
            .sr(_gnd_net_));
endmodule // top
