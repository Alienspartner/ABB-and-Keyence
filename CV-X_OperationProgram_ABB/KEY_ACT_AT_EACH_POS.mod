MODULE KEY_ACT_AT_EACH_POS

PROC KeyActAtEachPos(num leg_i)
    !Vision controller is zero-base numbering,
    !So the leg index is (leg_i - 1).
    
    IF leg_i = 1 THEN
        !Action at leg 0
    ELSEIF leg_i = 2 THEN
        !Action at leg 1
    ELSEIF leg_i = 3 THEN
        !Action at leg 2
    ELSEIF leg_i = 4 THEN
        !Action at leg 3
    ELSEIF leg_i = 5 THEN
        !Action at leg 4
    ELSEIF leg_i = 6 THEN
        !Action at leg 5
    ELSEIF leg_i = 7 THEN
        !Action at leg 6
    ELSEIF leg_i = 8 THEN
        !Action at leg 7
    ELSEIF leg_i = 9 THEN
        !Action at leg 8
    ENDIF
    
ENDPROC

ENDMODULE
