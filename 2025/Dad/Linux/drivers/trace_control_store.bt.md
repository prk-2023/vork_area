# #!/usr/bin/env bpftrace
# kprobe:control_store
# {
#     printf("[bpftrace] sysfs control_store() triggered\n");
# }
# kretprobe:control_store
# {
#     printf("[bpftrace] control_store() returned: %d\n", retval);
# }
#
# Since we are trying to probe a function in the sample diver that is not global
# And bpftrace relies on globally visible calls.
#
# Generally if the function is not exported to the kernel symbol table bpftrace will not 
# catch any thing.
#
# One way to handle this is to specify both function and the module in bpftrace using the below prog
# 1. above prog original kprobe:control_store will not work as the function is not in the 
#    global symbol table
# 2. use kprobe:simple_cb_driver:control_store to explicitly  trace the module symbol.
# 3. Tracepoints (sysfs:sysfs_write_file) are more stable alternative for sysfs write tracing
# cat /proc/kallsyms |grep control_store
# ffffffff86110380 t __pfx_control_store
# ffffffff86110390 t control_store
# ffffffff86aabf40 t __pfx_control_store
# ffffffff86aabf50 t control_store
# ffffffffc177f010 t control_store        [simple_cb_driver]
# ffffffffc177f000 t __pfx_control_store  [simple_cb_driver]
#
# the line ffffffffc177f010 t control_store        [simple_cb_driver]
# 't' : means the symbol is local (not global) that is not exported (T or W would be global)
#
#!/usr/bin/env bpftrace
kprobe:simple_cb_driver:control_store
{
    printf("[bpftrace] control_store() called by PID %d\n", pid);
}

kretprobe:simple_cb_driver:control_store:wq

{
    printf("[bpftrace] control_store() returned with: %d\n", retval);
}
#!/usr/bin/env bpftrace

kprobe:control_store
{
    printf("[bpftrace] control_store() called by PID %d (comm=%s)\n", pid, comm);
}

kretprobe:control_store
{
    printf("[bpftrace] control_store() returned with: %d\n", retval);
}
