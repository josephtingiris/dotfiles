function initialize_ctypes_module()
{
    local prefix=/home/jtingiris/opt/el7.x86_64
    local exec_prefix=${prefix}
    local -a builtins=(
        callback
        dlcall
        dlclose
        dlopen
        dlsym
        pack
        unpack
        struct
        sizeof
    )

    enable -f ctypes.so ${builtins[@]} &> /dev/null || {
        # is it possible user doesn't have dir in library search path?
        enable -f ${exec_prefix}/lib/ctypes.so ${builtins[@]} || {
            echo "can't find the ctypes.so library, run make install?" 1>&2
        }
    }
}

initialize_ctypes_module && unset initialize_ctypes_module

# Declare some convenient constants
declare -r NULL=pointer:0
declare -r STDIN_FILENO=int:0
declare -r STDOUT_FILENO=int:1
declare -r STDERR_FILENO=int:2
