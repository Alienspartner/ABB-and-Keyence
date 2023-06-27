MODULE MainModule
    VAR String stReply;                                           
	VAR String stParam;
	VAR num nStart;                                               
	VAR num nEnd;
	VAR num nIdx;                                
	VAR num nParam{7};                                                                            
    VAR rawbytes rbValues{2};
    VAR string stResults{20};
    VAR robtarget rtResults{20};
    VAR num count;
    VAR num regs;
    
PROC main()
!    KeyenceSetup "192.168.1.10",8500;
    initco;
    scan;
    Recrawbytes;
    merge;
    hangall;
    MoveJ homepos, v2000, z50, tool0;
    Stop;
ENDPROC

PROC Recrawbytes()
    VAR num i;
    VAR string head;
    VAR string end;
    VAR num nVal;
    FOR i FROM 1 TO 2 DO
        ClearRawBytes rbValues{i};
    ENDFOR
    regs:=1;
    SocketReceive skdSocket \RawData:=rbValues{1};
    regs:=regs+1;
    WHILE SocketPeek(skdSocket)>0 DO
        SocketReceive skdSocket \RawData:=rbValues{regs};
        regs:=regs+1;
    ENDWHILE
    regs:=regs-1;
    count:=1;
    UnpackRawBytes rbValues{1},1,stResults{1}\ASCII:=55;
    FOR i FROM 2 TO 18 DO
        UnpackRawBytes rbValues{1},56*(i-1)+1,stResults{i}\ASCII:=55;
    ENDFOR
    UnpackRawBytes rbValues{1},56*18+1,head\ASCII:=1024-56*18;
    UnpackRawBytes rbValues{2},1,end\ASCII:=55-(1024-56*18);
    stResults{19}:=head+end;
    UnpackRawBytes rbValues{2},55 - (1024 - 56 * 18) + 2,stResults{20}\ASCII:=55;
    FOR i FROM 1 TO 20 DO
        nStart  := 0;
    	nEnd    := 0;
    	nIdx    := 0;
    	WHILE nEnd < StrLen(stResults{i}) DO                       
    	    nIdx := nIdx+1;
    	    nStart := nEnd+1;
    	    nEnd := StrFind(stResults{i}, nStart, ",");
    	    stParam := StrPart(stResults{i},nStart,nEnd - nStart);
    	    IF StrToVal(stParam, nVal) THEN
    	        nParam{nIdx} := nVal;                                     
    	    ENDIF                                                                        
        	rtResults{i}.trans.x := nParam{2};                     
        	rtResults{i}.trans.y := nParam{3};
        	rtResults{i}.trans.z := nParam{4};
        	rtResults{i}.rot := OrientZYX(nParam{7}, nParam{6}, nParam{5});                                                               
    	ENDWHILE
    ENDFOR
    
ENDPROC


ENDMODULE