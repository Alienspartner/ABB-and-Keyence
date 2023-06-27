MODULE KUTIL_FUNCTIONS

    !Return values
    CONST num RET_OK := 0;
    CONST num RET_ERR_PARAM := 1;

    !Position type
    CONST num INTERVAL_TYPE_APPROACH := 0;
    CONST num INTERVAL_TYPE_GRASP := 1;
    CONST num INTERVAL_TYPE_DEPART := 2;
    CONST num INTERVAL_TYPE_PLACE := 3;
    CONST num INTERVAL_TYPE_SPECIFIED := 4;
    CONST num INTERVAL_TYPE_REL_SPECIFIED := 5;
    CONST num INTERVAL_TYPE_NEXT_START := 6;

    !PPR command type
    CONST num PPR_CMD_LEG_NUM_DETECTED := 0;
    CONST num PPR_CMD_WAYPOINT_NUM := 2;
    CONST num PPR_CMD_WAYPOINT_DATA := 3;
    CONST num PPR_CMD_SLIDE_EXE := 16;
    CONST num PPR_CMD_TRIG_WAYPOINT_IDX := 18;
    CONST num PPR_CMD_TRIG_LEG_IDX := 19;
    CONST num PPR_CMD_CAPTURE_WAIT_POS_TRIG := 20;
    CONST num PPR_CMD_NEXT_START_POSITION := 21;
    CONST num PPR_CMD_LEG_SPEED := 22;
    CONST num PPR_CMD_LEG_NUM_SET := 23;
    CONST num PPR_CMD_LEG_TYPE := 24;
    CONST num PPR_CMD_INITIAL_WAYPOINT := 25;
    CONST num PPR_OPT_FIXED_LEN := 3;
    
    !User's variables
    PERS String g_key_vision_ip_addr := "192.168.0.10";
    PERS num g_key_vision_port := 8500;
    PERS num g_key_tool_id := 101;
    PERS num g_key_path_label_no := 0;
    PERS num g_key_max_retry_num := 0;

    !Global variables definition
    CONST num KEY_LEG_NUM_MAX   := 20;
    CONST num KEY_WAYPOINT_NUM_MAX       := 80;
    PERS num g_key_operation_status := 0;
    PERS num g_key_v_tcp_max;
    PERS num g_key_v_ori := 500;
    PERS num g_key_v_leax := 5000;
    PERS num g_key_v_reax := 1000;
    PERS num g_key_rPrm{20};
    PERS num g_key_no_path_count;
    PERS num g_key_slide_executed;
    PERS num g_key_leg_num_set;
    PERS num g_key_leg_num_detected;
    PERS num g_key_trigger_leg_idx;
    PERS num g_key_trigger_wp_idx;
    PERS num g_key_next_start_pos_set;
    PERS num g_key_leg_type{20};
    PERS num g_key_leg_speed{20};
    PERS num g_key_waypoint_num{20};
    PERS jointtarget g_key_waypoint_data{80};

PROC KUtilInitialization()
    VAR num axis_i := 0;
    VAR num leg_i := 0;
    VAR num waypoint_i := 0;
    
    ! Position variable for initialization
    CONST jointtarget initial_pos := [ [ 0, 0, 0, 0, 0, 0], [ 0, 9E9, 9E9, 9E9, 9E9, 9E9] ];

    ! Max speed num
    VAR num max_speed := 0;
    g_key_v_tcp_max := MaxRobSpeed();

    !Initialize parameters
    IF Dim(g_key_leg_type, 1) <> KEY_LEG_NUM_MAX THEN
        TPWrite "The size of the matrices are not the same";
        Stop;
    ENDIF
    IF Dim(g_key_leg_speed, 1) <> KEY_LEG_NUM_MAX THEN
        TPWrite "The size of the matrices are not the same";
        Stop;
    ENDIF
    IF Dim(g_key_waypoint_num, 1) <> KEY_LEG_NUM_MAX THEN
        TPWrite "The size of the matrices are not the same";
        Stop;
    ENDIF
    IF Dim(g_key_rPrm, 1) <> KEY_LEG_NUM_MAX THEN
        TPWrite "The size of the matrices are not the same";
        Stop;
    ENDIF

    g_key_operation_status := 0;
    g_key_no_path_count := 0;
    g_key_leg_num_set :=0;
    g_key_leg_num_detected :=0;
    g_key_trigger_leg_idx :=-1;
    g_key_trigger_wp_idx :=-1;
    g_key_next_start_pos_set :=0;
    g_key_slide_executed := 0;
    FOR leg_i FROM 1 TO KEY_LEG_NUM_MAX DO
        g_key_waypoint_num{leg_i} := 0;
        g_key_leg_type{leg_i} := 0;
        g_key_leg_speed{leg_i} := 0;
    ENDFOR

    IF Dim(g_key_waypoint_data, 1) <> KEY_WAYPOINT_NUM_MAX THEN
        TPWrite "The size of the matrices are not the same";
        Stop;
    ENDIF

    FOR waypoint_i FROM 1 TO KEY_WAYPOINT_NUM_MAX DO
        g_key_waypoint_data{waypoint_i} := initial_pos;
    ENDFOR
ENDPROC

FUNC bool KUtilSplitString(String stValues)
    VAR num nStart  := 0;
    VAR num nEnd    := 0;
    VAR num nIdx    := 0;
    VAR num nVal    := 0;
    VAR String stParam;
    WHILE nEnd < StrLen(stValues) DO
        nIdx := nIdx+1;
        nStart := nEnd+1;
        nEnd := StrFind(stValues, nStart, ",");
        stParam := StrPart(stValues, nStart, nEnd-nStart);
        IF StrToVal(stParam, nVal) THEN
            g_key_rPrm{nIdx} := nVal;
        ELSE
            RETURN FALSE;
        ENDIF
    ENDWHILE
    RETURN TRUE;
ENDFUNC

FUNC num KUtilRecvVal()
	VAR String stReply;
    VAR bool bRet := FALSE;
    VAR num nRet := 0;
    KeyRecvString stReply;
    bRet := KUtilSplitString(stReply);
    IF bRet <> TRUE THEN
        nRet := -1;
    ELSE
        nRet := g_key_rPrm{1};
    ENDIF
    RETURN nRet;
ENDFUNC

FUNC num KUtilGetNextStartLeg(num b_slide_occured)
    VAR num next_start_leg;
    next_start_leg := g_key_next_start_pos_set;
    IF next_start_leg > -1 THEN
        IF b_slide_occured = 0 THEN
            RETURN next_start_leg;
        ENDIF
    ELSE
        next_start_leg := -1;
        RETURN next_start_leg;
    ENDIF
    next_start_leg := 0;
    RETURN next_start_leg;
ENDFUNC

FUNC num KUtilGetTrigLeg(num b_slide_occured)
    VAR num trig_leg := 0;
	IF b_slide_occured > 0 THEN
		trig_leg := g_key_leg_num_detected - 1;
		RETURN trig_leg;
	ELSE
		trig_leg := g_key_trigger_leg_idx;
		RETURN trig_leg;
	ENDIF
ENDFUNC

FUNC num KUtilGetLegSpeed(num leg_idx, num b_slide_occured)
    VAR num leg_speed := 0;
    VAR num leg_detected; 
    leg_detected := g_key_leg_num_detected;
	IF (b_slide_occured > 0) AND (leg_idx = leg_detected - 1) THEN
		leg_speed := g_key_leg_speed{g_key_leg_num_detected - 3};
	ELSE
		leg_speed := g_key_leg_speed{leg_idx + 1};
	ENDIF
	RETURN leg_speed*0.01;
ENDFUNC

FUNC num KUtilGetLegType(num leg_idx, num b_slide_occured)
    VAR num leg_type := 0;
    VAR num leg_detected;
    leg_detected := g_key_leg_num_detected;
	IF (b_slide_occured > 0) AND (leg_idx = leg_detected - 1) THEN
		leg_type := INTERVAL_TYPE_SPECIFIED;
	ELSE
		leg_type := g_key_leg_type{leg_idx + 1};
	ENDIF
	RETURN leg_type;
ENDFUNC

PROC KUtilMoveAlongPath()
    VAR num nextStartLeg := 0;
	VAR num pathNum := 0;
	VAR num returnVal := 0;
	VAR num leg_i := 0;
	VAR num legType := 0;
    VAR num nRet := 0;

KEY_RECV_VAL:
    ! Gets the results from the controller.
	pathNum := KUtilRecvVal();
	IF pathNum = 0 THEN
		g_key_operation_status := 1;
        GOTO KEY_END_MAP;
	ENDIF

    ! Gets the path result
    nRet := KUtilGetPath();
    IF nRet <> 0 THEN
        g_key_operation_status := 2;
        GOTO KEY_END_MAP;
    ENDIF

    ! initialize
    g_key_operation_status := 0;
    g_key_no_path_count := 0;

    ! Calls start pos action
	KeyActAtStartPos;

    FOR leg_i FROM nextStartLeg TO (g_key_leg_num_detected - 1) DO
        ! Move robot
        KUtilMoveAlongLeg leg_i, g_key_slide_executed;
        IF g_key_operation_status <> 0 THEN
            GOTO KEY_END_MAP;
        ENDIF

        ! Do action
        legType := KUtilGetLegType(leg_i,g_key_slide_executed);
        IF legType = INTERVAL_TYPE_APPROACH THEN
            KeyActAtApproachPos;
        ELSEIF legType = INTERVAL_TYPE_GRASP THEN
            KeyActAtGripPos;
        ELSEIF legType = INTERVAL_TYPE_DEPART THEN
            KeyActAtDepartDest;
        ELSEIF legType = INTERVAL_TYPE_PLACE THEN
            KeyActAtPlacePos;
        ENDIF
        KeyActAtEachPos(leg_i);
    ENDFOR

    ! Gets next start leg
	nextStartLeg := KUtilGetNextStartLeg(g_key_slide_executed);
	IF nextStartLeg > -1 THEN
		GOTO KEY_RECV_VAL;
	ENDIF
    g_key_operation_status := 0;
KEY_END_MAP:
ENDPROC

PROC KUtilMoveAlongLeg(num nLegIndex, num bSlide)
    VAR bool bRet := FALSE;
    VAR num leg_i := 0;
    VAR num waypoint_i := 0;
    VAR num waypoint_idx := 0;
    VAR num nTotalWaypointNum := 0;
    VAR num trig_leg;
    VAR num speed_ratio_i;
    VAR speeddata speed_i;
    
    trig_leg := KUtilGetTrigLeg(bSlide);
    speed_ratio_i := KUtilGetLegSpeed(nLegIndex,bSlide);
    speed_i := [g_key_v_tcp_max*speed_ratio_i, g_key_v_ori, g_key_v_leax, g_key_v_reax];

    !Calculate total number up to previous leg
    IF nLegIndex <> 0 THEN
        FOR leg_i FROM 1 TO nLegIndex DO
            !Previous leg last waypoint eqauals next leg first waypoint.
            !So number to be added is (leg waypoint number - 1)
            nTotalWaypointNum := nTotalWaypointNum + g_key_waypoint_num{leg_i} - 1;
        ENDFOR
    ENDIF
    curTool := CTool();
    curWobj := CWobj();
    waypoint_idx := nTotalWaypointNum + 1;
    FOR waypoint_i FROM 1 TO g_key_waypoint_num{nLegIndex + 1} DO
        !Move Robot
        MOVEABSJ g_key_waypoint_data{waypoint_idx}, speed_i, fine, curTool, \WObj:=curWobj;
        !Issues trigger
		IF (trig_leg = nLegIndex) AND (g_key_trigger_wp_idx = waypoint_i - 1) THEN
			bRet := KeyIssueTrigger();
			IF bRet <> TRUE THEN
                GOTO KEY_END_MAL;
			ENDIF
		ENDIF
        waypoint_idx := waypoint_idx + 1;
    ENDFOR
    waypoint_idx := waypoint_idx - 1;
    MOVEABSJ g_key_waypoint_data{waypoint_idx}, speed_i, fine, curTool, \WObj:=curWobj;
KEY_END_MAL:
ENDPROC

FUNC num KUtilGetPath()
    VAR num nRet := 0;

    !Get leg number
    nRet := KUtilGetPathParam(PPR_CMD_LEG_NUM_DETECTED);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF
    g_key_leg_num_detected := g_key_rPrm{1};

    !Get slide execution flag
    nRet := KUtilGetPathParam(PPR_CMD_SLIDE_EXE);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF
    g_key_slide_executed := g_key_rPrm{1};

    !Get trigger position
    nRet := KUtilGetPathParam(PPR_CMD_TRIG_WAYPOINT_IDX);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF
    g_key_trigger_wp_idx := g_key_rPrm{1};

    !Get waypoint number
    nRet := KUtilGetLegParam(PPR_CMD_WAYPOINT_NUM);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF

    !Get waypoint data
    nRet := KUtilGetWaypointData();
    RETURN nRet;
ENDFUNC

FUNC num KUtilGetPathParam(num nCommandType)
    VAR bool bRet := TRUE;
    VAR String stReply;

    !Send command to vision controller.
    KeySendString "PPR,"
        + ValToStr(nCommandType) + ","
        + ValToStr(g_key_tool_id) + ","
        + ValToStr(g_key_path_label_no) + ","
        + ValToStr(PPR_OPT_FIXED_LEN);

    !Recieve data from vision controller
    KeyRcvStrMax stReply, 1, -1;
    bRet := KUtilRecvCommandString("PPR", stReply);
    IF bRet <> TRUE THEN
        RETURN RET_ERR_PARAM;
    ENDIF

    RETURN RET_OK;
ENDFUNC

FUNC num KUtilGetLegParam(num nCommandType)
    VAR bool bRet := TRUE;
    VAR String stReply;
    VAR num leg_i := 0;

    !Send command to vision controller.
    KeySendString "PPR,"
        + ValToStr(nCommandType) + ","
        + ValToStr(g_key_tool_id) + ","
        + ValToStr(g_key_path_label_no)
        + ",-1" + ","
        + ValToStr(PPR_OPT_FIXED_LEN);

    !Recieve data from vision controller.
    KeyRcvStrMax stReply, 2, g_key_leg_num_detected;
    bRet := KUtilRecvCommandString("PPR", stReply);
    IF bRet <> TRUE THEN
        RETURN RET_ERR_PARAM;
    ENDIF

    IF nCommandType = PPR_CMD_WAYPOINT_NUM THEN
        FOR leg_i FROM 1 TO g_key_leg_num_detected DO
            g_key_waypoint_num{leg_i} := g_key_rPrm{leg_i};
        ENDFOR
    ELSE
        Stop;
    ENDIF
    RETURN RET_OK;
ENDFUNC

FUNC num KUtilGetWaypointData()
    VAR bool bRet := TRUE;
    VAR num leg_i := 0;
    VAR num waypoint_i := 0;
    VAR num nStartWaypointIndex := 0;
    VAR num nWaypointIndex := 0;
    VAR num nTotalWaypointNum := 0;
    VAR String stReply;

    FOR leg_i FROM 1 TO g_key_leg_num_detected DO
        IF leg_i = 1 THEN
            nStartWaypointIndex := 1;
        ELSE
            nStartWaypointIndex := 2;
        ENDIF
        FOR waypoint_i FROM nStartWaypointIndex TO g_key_waypoint_num{leg_i} DO
            !Send command to vision controller.
            KeySendString "PPR,"
                + ValToStr(PPR_CMD_WAYPOINT_DATA) + ","
                + ValToStr(g_key_tool_id) + ","
                + ValToStr(g_key_path_label_no) + ","
                + ValToStr(leg_i - 1) + ","
                + ValToStr(waypoint_i - 1) + ","
                + ValToStr(PPR_OPT_FIXED_LEN);

            !Recieve data from vision controller.
            KeyRcvStrMax stReply, 3, -1;
            bRet := KUtilRecvCommandString("PPR", stReply);
            IF bRet <> TRUE THEN
                RETURN RET_ERR_PARAM;
            ENDIF

            nWaypointIndex := waypoint_i + nTotalWaypointNum;
            g_key_waypoint_data{nWaypointIndex}.robax.rax_1 := g_key_rPrm{1};
            g_key_waypoint_data{nWaypointIndex}.robax.rax_2 := g_key_rPrm{2};
            g_key_waypoint_data{nWaypointIndex}.robax.rax_3 := g_key_rPrm{3};
            g_key_waypoint_data{nWaypointIndex}.robax.rax_4 := g_key_rPrm{4};
            g_key_waypoint_data{nWaypointIndex}.robax.rax_5 := g_key_rPrm{5};
            g_key_waypoint_data{nWaypointIndex}.robax.rax_6 := g_key_rPrm{6};
        ENDFOR

        !Previous leg last waypoint equals next leg first waypoint.
        !So number to be added is (leg waypoint number - 1).
        nTotalWaypointNum := nTotalWaypointNum + g_key_waypoint_num{leg_i} - 1;
    ENDFOR

    RETURN RET_OK;
ENDFUNC

FUNC num KUtilGetConfig()
    VAR num nRet := 0;

    !Get leg number
    nRet := KUtilGetPathSetting(PPR_CMD_LEG_NUM_SET);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF
    g_key_leg_num_set := g_key_rPrm{1};

    !Get trigger position
    nRet := KUtilGetPathSetting(PPR_CMD_TRIG_LEG_IDX);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF
    g_key_trigger_leg_idx := g_key_rPrm{1};

    !Get next start position
    nRet := KUtilGetPathSetting(PPR_CMD_NEXT_START_POSITION);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF
    g_key_next_start_pos_set := g_key_rPrm{1};

    !Get leg type
    nRet := KUtilGetLegSetting(PPR_CMD_LEG_TYPE);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF

    !Get movement speed
    nRet := KUtilGetLegSetting(PPR_CMD_LEG_SPEED);
    IF nRet <> RET_OK THEN
        RETURN nRet;
    ENDIF

    !Get waypoint data
    nRet := KUtilGetCaptureWaitPosWayPoint();
    RETURN nRet;
ENDFUNC

FUNC num KUtilGetPathSetting(num nCommandType)
    VAR bool bRet := TRUE;
    VAR String stReply;

    !Send command to vision controller.
    KeySendString "PPR,"
        + ValToStr(nCommandType) + ","
        + ValToStr(g_key_tool_id) + ","
        + ValToStr(PPR_OPT_FIXED_LEN);

    !Recieve data from vision controller
    KeyRcvStrMax stReply, 1, -1;
    bRet := KUtilRecvCommandString("PPR", stReply);
    IF bRet <> TRUE THEN
        RETURN RET_ERR_PARAM;
    ENDIF

    RETURN RET_OK;
ENDFUNC

FUNC num KUtilGetLegSetting(num nCommandType)
    VAR bool bRet := TRUE;
    VAR String stReply;
    VAR num leg_i := 0;

    !Send command to vision controller.
    KeySendString "PPR,"
        + ValToStr(nCommandType) + ","
        + ValToStr(g_key_tool_id)
        + ",-1" + ","
        + ValToStr(PPR_OPT_FIXED_LEN);

    !Recieve data from vision controller.
    KeyRcvStrMax stReply, 2, g_key_leg_num_set;
    bRet := KUtilRecvCommandString("PPR", stReply);
    IF bRet <> TRUE THEN
        RETURN RET_ERR_PARAM;
    ENDIF

    IF nCommandType = PPR_CMD_LEG_SPEED THEN
        FOR leg_i FROM 1 TO g_key_leg_num_set DO
            g_key_leg_speed{leg_i} := g_key_rPrm{leg_i};
        ENDFOR
    ELSEIF nCommandType = PPR_CMD_LEG_TYPE THEN
        FOR leg_i FROM 1 TO g_key_leg_num_set DO
            g_key_leg_type{leg_i} := g_key_rPrm{leg_i};
        ENDFOR
    ELSE
        Stop;
    ENDIF
    RETURN RET_OK;
ENDFUNC

FUNC num KUtilGetCaptureWaitPosWayPoint()
    VAR bool bRet := TRUE;
    VAR String stReply;

    KeySendString "PPR,"
        + ValToStr(PPR_CMD_INITIAL_WAYPOINT) + ","
        + ValToStr(g_key_tool_id) + ","
        + ValToStr(PPR_OPT_FIXED_LEN);

    !Recieve data from vision controller.
    KeyRcvStrMax stReply, 3, -1;
    bRet := KUtilRecvCommandString("PPR", stReply);
    IF bRet <> TRUE THEN
        RETURN RET_ERR_PARAM;
    ENDIF

    g_key_waypoint_data{1}.robax.rax_1 := g_key_rPrm{1};
    g_key_waypoint_data{1}.robax.rax_2 := g_key_rPrm{2};
    g_key_waypoint_data{1}.robax.rax_3 := g_key_rPrm{3};
    g_key_waypoint_data{1}.robax.rax_4 := g_key_rPrm{4};
    g_key_waypoint_data{1}.robax.rax_5 := g_key_rPrm{5};
    g_key_waypoint_data{1}.robax.rax_6 := g_key_rPrm{6};

    RETURN RET_OK;
ENDFUNC

FUNC bool KUtilRecvCommandString(String strSendCmd, String strRecv)
    VAR bool bRet := TRUE;
    VAR num nEnd := 0;
    VAR num nStart := 0;
    VAR num nIdx := 1;
    VAR num nVal := 0;
    VAR String stParam;

    WHILE nEnd < StrLen(strRecv) DO
        nStart := nEnd+1;
        nEnd := StrFind(strRecv, nStart, ",");
        stParam := StrPart(strRecv, nStart, nEnd-nStart);
        IF nStart = 1 THEN
            !Check receive command.
            IF strSendCmd <> stParam THEN
                RETURN FALSE;
            ENDIF
        ELSE
            IF StrToVal(stParam, nVal) THEN
                g_key_rPrm{nIdx} := nVal;
                nIdx := nIdx+1;
             ELSE
                RETURN FALSE;
            ENDIF
        ENDIF
    ENDWHILE
    RETURN TRUE;
ENDFUNC

ENDMODULE
