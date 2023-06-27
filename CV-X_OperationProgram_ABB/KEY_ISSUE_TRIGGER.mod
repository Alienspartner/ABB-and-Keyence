MODULE KEY_ISSUE_TRIGGER
FUNC bool KeyIssueTrigger()
    VAR bool bRet := TRUE;
    VAR String stReply;
    !Action at Start Position
    KeySendString "T1";
    KeyRecvString stReply;
    IF stReply <> "T1" THEN
        g_key_operation_status := 3;
        bRet := FALSE;
    ENDIF
    RETURN bRet;
ENDFUNC
ENDMODULE
