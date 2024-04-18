import core, vars
import duktape/js
import apivars

var
  ctx: DTContext

template setInt(name: string, value: int) =
  ctx.duk_push_int(value)
  discard ctx.duk_put_global_string(name)

template setNumber(name: string, value: float) =
  ctx.duk_push_number(value)
  discard ctx.duk_put_global_string(name)

template setString(name: string, value: string) =
  ctx.duk_push_string(value)
  discard ctx.duk_put_global_string(name)

template defFunc(name: string, f: proc (ctx: DTContext): int) =
    ctx.duk_push_c_function(proc, 0)
    discard ctx.duk_put_global_string(name)

# Returns whether the script was loaded successfully
proc loadScript*(script: string): bool =
  let err = ctx.duk_peval_string(script)
  return err == 0

proc initJsApi*() =
  # Create heap
  ctx = duk_create_heap_default()

  # Push initial globals

  # Define functions
