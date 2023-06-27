MODULE KEY_SET_PARAM
    ! Sets the user's parameters
PROC KeySetParam()
    ! Keyence Vision Controller IP address and port number
    g_key_vision_ip_addr := "192.168.0.10";
    g_key_vision_port := 8500;
    !Path planning tool id
    g_key_tool_id := 101;
    !Result label no
    g_key_path_label_no := 0;
    !Maximum number of times of retry
    g_key_max_retry_num := 0;
ENDPROC
ENDMODULE
