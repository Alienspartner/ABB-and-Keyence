MODULE tolerance
    CONST num xtol:=5;
    CONST num ytol:=5;
    CONST num ztol:=10;
    CONST num extol:=5;
    CONST num eytol:=5;
    CONST num eztol:=5;
    !filter the same hook
    
    CONST num exstd:=-7;
    CONST num eystd:=-85.5;
    CONST num ezstd:=-8;
    CONST num etol:=10;
    !exclude the error hook
    
    CONST num dstd:=1452;
    CONST num dtol:=100;
    CONST num diff:=170;
    !regroup the hook
    
    VAR robtarget coordinate{3,13};
    !save hook
    
    VAR robtarget homepos;
    
    PROC scan()
        !Variable declaration, initialization.                    
	    ConfL \On;
	    SingArea \Wrist;

	    !Opens the connection.
	    KeyConnect \Address:="192.168.1.10", \Port:=8500;       

	    !Pauses.
	    WaitTime 1.000;                                                       

	    !Issues the trigger.
	    KeySendString "TA";                                                
	    KeyRecvString stReply;                                            
	    IF stReply<>"TA" THEN                                         
	    RETURN;
	ENDIF                                        
    ENDPROC
    
    PROC hangall()
        VAR num i;
        VAR num j;
        FOR i FROM 1 TO 3 DO
            FOR j FROM 1 TO 13 DO
                IF valid(coordinate{i,j})=1 THEN
                    hang coordinate{i,j},i;
                ENDIF
            ENDFOR
        ENDFOR
        
    ENDPROC
    
    PROC hang(robtarget target,num i)
        MoveJ RelTool(target,0,0,-diff*(3-i)-200), v2000, z50, tool0;
        MoveL target,v500,fine,tool0;
        opengripper;
        WaitTime 0.5;
        MoveL RelTool(target,0,0,-diff*(3-i)-200),v2000,z50,tool0;
    ENDPROC
    
    PROC home()
        MoveJ homepos,v2000,z10,tool0;
    ENDPROC
    
    PROC opengripper()
        Reset Local_IO_0_DO16;
        Set Local_IO_0_DO15;
    ENDPROC
    
    PROC closegripper()
        Reset Local_IO_0_DO15;
        Set Local_IO_0_DO16;
    ENDPROC
    
    PROC initco()
        VAR num i;
        VAR num j;
        FOR i FROM 1 TO 3 DO
            FOR j FROM 1 TO 13 DO
                coordinate{i,j}.trans.x:=0;
                coordinate{i,j}.trans.y:=0;
                coordinate{i,j}.trans.y:=0;
                coordinate{i,j}.rot:=OrientZYX(0,0,0);
            ENDFOR
        ENDFOR
    ENDPROC
    
    PROC merge()
        VAR num i;
        VAR num nGroup;
        FOR i FROM 1 TO 20 DO
            IF valid(rtResults{i})=1 THEN
                nGroup:=group(rtResults{i});
                IF nGroup=1 THEN
                    submerge rtResults{i},1;
                ELSEIF nGroup=2 THEN
                    submerge rtResults{i},2;
                ELSEIF nGroup=3 THEN
                    submerge rtResults{i},3;
                ELSE
                    TPWrite "INDEX OUT OF RANGE";
                ENDIF
            ENDIF
        ENDFOR
    ENDPROC
    
    PROC submerge(robtarget target,num j)
        VAR num k;
        VAR num l;
        VAR num v;
        VAR num flag:=0;
        FOR k FROM 1 TO 13 DO
            IF same(target,coordinate{j,k})=1 THEN
                flag:=1;
            ENDIF
        ENDFOR
        IF flag=0 THEN
            FOR l FROM 1 TO 13 DO
                IF valid(coordinate{j,l})=0 THEN
                    coordinate{j,l}:=target;
                    GOTO end;
                ENDIF
            ENDFOR
        ENDIF
        end:
    ENDPROC
    
    FUNC num correct(robtarget target)
        VAR num flag:=0;
        IF abs(EulerZYX(\X,target.rot)-exstd)<=etol AND abs(EulerZYX(\Y,target.rot)-eystd)<=etol AND abs(EulerZYX(\Z,target.rot)-ezstd)<=etol THEN
            flag:=1;
        ENDIF
        RETURN flag;
    ENDFUNC
    
    FUNC num same(robtarget target1, robtarget target2)
        VAR num flag:=0;
        IF abs(target1.trans.x-target2.trans.x)<=xtol AND abs(target1.trans.y-target2.trans.y)<=ytol AND abs(target1.trans.z-target2.trans.z)<=ztol AND  abs(EulerZYX(\X,target1.rot)-EulerZYX(\X,target2.rot))<=extol AND abs(EulerZYX(\Y,target2.rot)-EulerZYX(\Y,target2.rot))<=eytol AND abs(EulerZYX(\Z,target1.rot)-EulerZYX(\Z,target2.rot))<=eztol THEN
            flag:=1;
        ENDIF
        RETURN flag;
    ENDFUNC
    
    FUNC num group(robtarget target)
        VAR num flag:=0;
        IF abs(target.trans.x-dstd)<=dtol THEN
            flag:=1;
        ELSEIF abs(target.trans.x-dstd+diff)<=dtol THEN
            flag:=2;
        ELSEIF abs(target.trans.x-dstd+2*diff)<=dtol THEN
            flag:=3;
        ENDIF
        RETURN flag;
    ENDFUNC
    
    FUNC num valid(robtarget target)
        VAR num flag:=1;
        IF target.trans.x=0 AND target.trans.y=0 AND target.trans.z=0 AND target.rot=OrientZYX(0,0,0) THEN
            flag:=0;
        ENDIF
        RETURN flag;
    ENDFUNC
    
    FUNC num abs(num i)
        VAR num j;
        IF i >=0 THEN
            j:=i;
        ELSE 
            j:=-1*i;
        ENDIF
        RETURN j;
    ENDFUNC
    
ENDMODULE