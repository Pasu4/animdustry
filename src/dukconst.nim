import duktape/js

const
  DUK_DEFPROP_WRITABLE*          : duk_uint_t = (1 shl 0)
  DUK_DEFPROP_ENUMERABLE*        : duk_uint_t = (1 shl 1)
  DUK_DEFPROP_CONFIGURABLE*      : duk_uint_t = (1 shl 2)
  DUK_DEFPROP_HAVE_WRITABLE*     : duk_uint_t = (1 shl 3)
  DUK_DEFPROP_HAVE_ENUMERABLE*   : duk_uint_t = (1 shl 4)
  DUK_DEFPROP_HAVE_CONFIGURABLE* : duk_uint_t = (1 shl 5)
  DUK_DEFPROP_HAVE_VALUE*        : duk_uint_t = (1 shl 6)
  DUK_DEFPROP_HAVE_GETTER*       : duk_uint_t = (1 shl 7)
  DUK_DEFPROP_HAVE_SETTER*       : duk_uint_t = (1 shl 8)
  DUK_DEFPROP_FORCE*             : duk_uint_t = (1 shl 9)