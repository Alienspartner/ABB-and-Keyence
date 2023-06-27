MODULE KEY_OPERATION
!  Operation Program Ver. 2.0
!  This program should be used with CV-X Ver. 5.3
!  or later versions.

PROC main()
    KeyOperation;
ENDPROC

PROC KeyOperation()
    ! Variable declaration, initialization
    VAR bool bRet;
    VAR num nRet;
    VAR speeddata move_speed;
    
    !Initialize.
    KUtilInitialization;
    KeySetParam;

    !Opens the connection.
    KeyConnect \Address:=g_key_vision_ip_addr, \Port:=g_key_vision_port;

    !Get path planning config
	nRet := KUtilGetConfig();
	IF nRet <> 0 THEN
        g_key_operation_status := 2;
		GOTO KEY_END_PROG;
	ENDIF

KEY_START:
    !Returns to the capture wait position
    curTool := CTool();
    curWobj := CWobj();
    move_speed := [100, 500, 5000, 1000]; ! v100
	MOVEABSJ g_key_waypoint_data{1}, move_speed, fine, curTool, \WObj:=curWobj;

    !Issues the trigger.
    bRet := KeyIssueTrigger();
    IF bRet <> TRUE GOTO KEY_END_PROG;

KEY_LOOP:
    KUtilMoveAlongPath;
    IF g_key_operation_status = 0 THEN
        ! success
    ELSE
        IF g_key_operation_status = 1 THEN
            g_key_no_path_count := g_key_no_path_count + 1;
            IF g_key_no_path_count <= g_key_max_retry_num THEN
                g_key_operation_status := 0;
                GOTO KEY_START;
            ENDIF
        ENDIF
        GOTO KEY_END_PROG;
    ENDIF

    IF g_key_slide_executed <> 0 GOTO KEY_START;

    !Issues the trigger.
    bRet := KeyIssueTrigger();
    IF bRet <> TRUE GOTO KEY_END_PROG;

    GOTO KEY_LOOP;

KEY_END_PROG:
    ! Closes the connection.
    KeyClose;
ENDPROC
    
ENDMODULE
