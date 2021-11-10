

.segment "CODE"
    nop

.segment "BI_FL_LD"
    nop
    nop
.segment "BI_FL_AP"
.segment "BI_FL_WR"
.segment "BI_FL_CC"
.segment "BI_FL_AC"
.segment "BI_FL_SC1"
.segment "BI_FL_SC0"
.segment "BI_DINFO"

.word $ffff,$ffff,$ffff,$ffff,$ffff

nmi:
rst:
irq:
    rti

.segment "VECTORS"
    
.word  nmi, rst, irq
